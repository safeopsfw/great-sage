"""
main.py — Entry point for the Python inference service.
Starts gRPC server, loads Index 0 (Great Sage) on startup, runs VRAM monitor.

Run from project root:
    cd "D:\Project LLM\great sage"
    venv\Scripts\python.exe -m services.inference.src.main
"""

import asyncio
import logging
import signal
import sys

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("inference.main")

# ── Imports ───────────────────────────────────────────────────────────────────
from .config           import PORTS, PATHS, VRAM, INDEX_GREAT_SAGE, resolve_model_path
from .inference        import model_loader
from .grpc.server      import start as start_grpc
from .embeddings.bge_m3 import warmup as warmup_embedder
from .                 import vram_monitor


async def main() -> None:
    log.info("=" * 60)
    log.info("  Great Sage × Tempest — Python Inference Service")
    log.info("=" * 60)

    # ── 1. Start VRAM monitor (runs every 10s in background) ─────────────────
    asyncio.create_task(vram_monitor.run_monitor(interval_s=10.0))
    log.info("VRAM monitor started")

    # ── 2. Load Index 0 (Great Sage) into VRAM on startup ────────────────────
    try:
        path   = resolve_model_path(INDEX_GREAT_SAGE)
        device = VRAM.inference_device   # "cuda:0" → RTX 3050
        log.info(f"Loading Index 0 (Great Sage) from {path} on {device}...")
        model_loader.load(INDEX_GREAT_SAGE, path, device)
        snap = vram_monitor.snapshot()
        log.info(
            f"Index 0 loaded — VRAM: {snap.used_mb}/{snap.total_mb} MB used"
        )
    except FileNotFoundError as e:
        log.warning(f"Index 0 model not found: {e}")
        log.warning("Server will start without a loaded model.")
        log.warning("Send LoadModel(model_index=0) RPC to load when weights are ready.")
    except Exception as e:
        log.error(f"Failed to load Index 0: {e}")
        log.warning("Continuing without model — LoadModel RPC will retry")

    # ── 3. Warm up BGE-M3 embedder (pre-loads model on CPU) ──────────────────
    try:
        await warmup_embedder()
    except Exception as e:
        log.warning(f"BGE-M3 warmup failed (non-fatal): {e}")

    # ── 4. Start gRPC server ──────────────────────────────────────────────────
    port   = PORTS.python_inference    # 50052
    server = await start_grpc(port)
    log.info(f"Inference service ready — listening on 127.0.0.1:{port}")
    log.info("Waiting for calls from Rust orchestrator...")

    # ── 5. Graceful shutdown on SIGINT / SIGTERM ─────────────────────────────
    stop_event = asyncio.Event()

    def _handle_signal():
        log.info("Shutdown signal received — stopping gracefully...")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, _handle_signal)
        except NotImplementedError:
            # Windows does not support add_signal_handler for all signals
            pass

    await stop_event.wait()

    log.info("Unloading models...")
    for idx in model_loader.loaded_indices()[:]:   # copy — list changes during iteration
        model_loader.unload(idx)

    await server.stop(grace=5)
    log.info("Inference service stopped cleanly")


if __name__ == "__main__":
    asyncio.run(main())
