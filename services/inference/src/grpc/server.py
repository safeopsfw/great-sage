"""
server.py — gRPC servicer for OrchestratorToInference service.
Implements all RPC methods defined in proto\tempest.proto Service 2.
Called by main.py — do not run this file directly.
"""

import asyncio
import logging
import sys
from pathlib import Path

import grpc

# Add proto dir to path so tempest_pb2 imports resolve
_PROTO_DIR = Path(__file__).parent.parent.parent / "proto"
sys.path.insert(0, str(_PROTO_DIR))

import tempest_pb2       as pb
import tempest_pb2_grpc  as pb_grpc

from ..config        import PATHS, VRAM, PORTS, INDEX_GREAT_SAGE, INDEX_PROFESSOR, resolve_model_path
from ..inference     import model_loader
from ..inference.generator  import GenerateRequest, stream as token_stream
from ..embeddings.bge_m3    import embed, embed_batch
from ..             import vram_monitor

log = logging.getLogger(__name__)

# ── gRPC Servicer ─────────────────────────────────────────────────────────────

class InferenceServicer(pb_grpc.OrchestratorToInferenceServicer):
    """
    Implements OrchestratorToInference service (Rust → Python direction).
    All methods are async — gRPC server runs on asyncio event loop.
    """

    # ── Generate (streaming) ─────────────────────────────────────────────────

    async def Generate(self, request, context):
        """
        Stream token-by-token response back to Rust orchestrator.
        Rust assembles the 6-slot prompt (§32), sends it here, streams chunks back.
        """
        req = GenerateRequest(
            model_index         = request.model_index,
            prompt              = request.prompt,
            max_new_tokens      = request.max_new_tokens or 512,
            temperature         = request.temperature    or 0.7,
            top_p               = request.top_p          or 0.9,
            repetition_penalty  = request.repetition_penalty or 1.1,
            kv_cache_prefix_len = request.kv_cache_prefix_len,
            stop_sequences      = list(request.stop_sequences),
        )

        try:
            async for chunk in token_stream(req):
                yield pb.GenerateChunk(
                    token    = chunk.token,
                    logprob  = chunk.logprob,
                    is_final = chunk.is_final,
                )
        except Exception as e:
            log.error(f"Generate error: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))

    # ── Embed ────────────────────────────────────────────────────────────────

    async def Embed(self, request, context):
        """Single text → 768-dim BGE-M3 vector. CPU, non-blocking."""
        try:
            vec = await embed(request.text)
            return pb.EmbedResponse(embedding=vec)
        except Exception as e:
            log.error(f"Embed error: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return pb.EmbedResponse()

    # ── EmbedBatch ───────────────────────────────────────────────────────────

    async def EmbedBatch(self, request, context):
        """Batch of texts → list of 768-dim vectors. Used by §15 knowledge ingestion."""
        try:
            vecs = await embed_batch(list(request.texts))
            embeddings = [pb.EmbedResponse(embedding=v) for v in vecs]
            return pb.EmbedBatchResponse(embeddings=embeddings)
        except Exception as e:
            log.error(f"EmbedBatch error: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return pb.EmbedBatchResponse()

    # ── LoadModel ────────────────────────────────────────────────────────────

    async def LoadModel(self, request, context):
        """
        Load a model into VRAM. Called by Rust orchestrator when switching modes.
        Uses iGPU fallback (CPU) if RTX 3050 VRAM is too full.
        """
        index  = request.model_index
        snap   = vram_monitor.snapshot()

        # Decide device: RTX 3050 if VRAM safe, Intel UHD (CPU) as fallback
        device = VRAM.inference_device   # "cuda:0"
        if snap.used_mb > VRAM.hard_limit_mb - 500:
            log.warning(
                f"VRAM tight ({snap.used_mb} MB used) — loading index {index} on CPU (Intel UHD)"
            )
            device = VRAM.igpu_fallback_device   # "cpu"

        try:
            path = resolve_model_path(index)
            model_loader.load(index, path, device)
            snap_after = vram_monitor.snapshot()
            return pb.LoadModelResponse(
                success=True,
                vram_used_mb=snap_after.used_mb,
                message=f"Model index {index} loaded on {device}",
            )
        except Exception as e:
            log.error(f"LoadModel error index={index}: {e}")
            return pb.LoadModelResponse(success=False, message=str(e))

    # ── UnloadModel ──────────────────────────────────────────────────────────

    async def UnloadModel(self, request, context):
        """Free VRAM by removing a model. Called before loading the other model."""
        index = request.model_index
        try:
            model_loader.unload(index)
            snap = vram_monitor.snapshot()
            return pb.UnloadModelResponse(
                success=True,
                vram_freed_mb=snap.free_mb,
                message=f"Model index {index} unloaded",
            )
        except Exception as e:
            log.error(f"UnloadModel error index={index}: {e}")
            return pb.UnloadModelResponse(success=False, message=str(e))

    # ── GetVRAMStatus ────────────────────────────────────────────────────────

    async def GetVRAMStatus(self, request, context):
        """Returns current VRAM snapshot. Polled by Rust orchestrator every 10s."""
        snap = vram_monitor.snapshot()
        return pb.VRAMStatusResponse(
            total_mb       = snap.total_mb,
            used_mb        = snap.used_mb,
            free_mb        = snap.free_mb,
            util_pct       = snap.util_pct,
            loaded_indices = model_loader.loaded_indices(),
            is_critical    = snap.is_critical,
        )

    # ── HealthCheck ──────────────────────────────────────────────────────────

    async def HealthCheck(self, request, context):
        """
        Fast liveness check. Fails immediately if GPU not available.
        Rust orchestrator calls this on startup and every 30s.
        """
        import torch
        gpu_ok = torch.cuda.is_available()
        snap   = vram_monitor.snapshot()
        return pb.HealthResponse(
            ok      = True,
            gpu_ok  = gpu_ok,
            message = (
                f"GPU: {'RTX 3050 ready' if gpu_ok else 'UNAVAILABLE — CPU fallback active'} | "
                f"VRAM: {snap.used_mb}/{snap.total_mb} MB | "
                f"Loaded models: {model_loader.loaded_indices()}"
            ),
        )

    # ── Transcribe (STT — Vosk, §35) ─────────────────────────────────────────

    async def Transcribe(self, request, context):
        """
        Speech-to-text via Vosk (CPU, zero VRAM).
        Implemented in §35 (Voice System). Stub here so server starts cleanly.
        """
        # §35 will replace this stub
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details("Transcribe implemented in §35 — Voice System")
        return pb.TranscribeResponse()


# ── Server start ──────────────────────────────────────────────────────────────

async def start(port: int = 50052) -> grpc.aio.Server:
    """
    Create and start the async gRPC server.
    Called from main.py — returns the server handle for graceful shutdown.
    """
    server = grpc.aio.server()
    pb_grpc.add_OrchestratorToInferenceServicer_to_server(InferenceServicer(), server)
    listen_addr = f"127.0.0.1:{port}"   # localhost only — never 0.0.0.0
    server.add_insecure_port(listen_addr)
    await server.start()
    log.info(f"Inference gRPC server listening on {listen_addr}")
    return server
