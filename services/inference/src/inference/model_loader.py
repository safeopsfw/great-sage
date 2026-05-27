"""
model_loader.py — Loads and unloads models into VRAM.
Handles both FP16 (dev/testing) and AWQ INT4 (production after §6).
Called by server.py in response to LoadModel / UnloadModel gRPC calls.
"""

import gc
import logging
import time
from pathlib import Path
from typing import Optional

import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, GenerationConfig

log = logging.getLogger(__name__)

# ── AutoAWQ import — optional (only available after §6 quantization) ──────────
try:
    from awq import AutoAWQForCausalLM
    _AWQ_AVAILABLE = True
except ImportError:
    _AWQ_AVAILABLE = False
    log.info("AutoAWQ not available — FP16 fallback mode active (install awq for production)")

# ── Model registry — holds currently loaded models ────────────────────────────

class LoadedModel:
    """Wrapper around a loaded model + tokenizer pair."""
    def __init__(
        self,
        index: int,
        model,
        tokenizer,
        model_path: Path,
        is_awq: bool,
        device: str,
    ):
        self.index      = index
        self.model      = model
        self.tokenizer  = tokenizer
        self.model_path = model_path
        self.is_awq     = is_awq
        self.device     = device
        self.loaded_at  = time.time()

    @property
    def vram_mb(self) -> int:
        """Rough VRAM used by this model (reads torch allocator stats)."""
        if self.device == "cpu":
            return 0
        try:
            return int(torch.cuda.memory_allocated() / (1024 * 1024))
        except Exception:
            return 0

# Single slot per index — only one model per index in VRAM at a time
_registry: dict[int, LoadedModel] = {}

# ── Load ──────────────────────────────────────────────────────────────────────

def load(index: int, model_path: Path, device: str = "cuda:0") -> LoadedModel:
    """
    Load model weights into VRAM (or CPU for iGPU fallback).
    If this index is already loaded, return the existing instance.
    Detects AWQ weights automatically (looks for quant_config.json).
    """
    if index in _registry:
        log.info(f"Model index {index} already loaded — reusing")
        return _registry[index]

    log.info(f"Loading model index {index} from {model_path} onto {device}")
    start = time.time()

    is_awq = (model_path / "quant_config.json").exists() and _AWQ_AVAILABLE

    if is_awq:
        log.info("AWQ INT4 weights detected — loading with AutoAWQ")
        model = AutoAWQForCausalLM.from_quantized(
            str(model_path),
            fuse_layers=True,          # fuse attention + FFN for speed
            trust_remote_code=True,
        )
        model = model.to(device)
    else:
        log.info("FP16 weights detected — loading with transformers (dev mode)")
        model = AutoModelForCausalLM.from_pretrained(
            str(model_path),
            torch_dtype=torch.float16,
            device_map=device,
            trust_remote_code=True,
            low_cpu_mem_usage=True,
        )

    # torch.compile — fuses GPU kernels via Triton, ~20-40% faster tokens
    # Skip on CPU (Intel UHD fallback) — compile only helps on CUDA
    if device != "cpu" and torch.cuda.is_available():
        log.info("Applying torch.compile for kernel fusion...")
        try:
            model = torch.compile(model, mode="reduce-overhead", fullgraph=False)
            log.info("torch.compile applied")
        except Exception as e:
            log.warning(f"torch.compile failed (non-fatal): {e}")

    model.eval()  # disable dropout, put in inference mode

    tokenizer = AutoTokenizer.from_pretrained(
        str(model_path),
        trust_remote_code=True,
        padding_side="left",    # left-padding for batch inference
    )

    elapsed = time.time() - start
    entry   = LoadedModel(index, model, tokenizer, model_path, is_awq, device)
    _registry[index] = entry

    log.info(
        f"Model index {index} loaded in {elapsed:.1f}s "
        f"(awq={is_awq}, device={device}, vram={entry.vram_mb} MB)"
    )
    return entry

# ── Unload ────────────────────────────────────────────────────────────────────

def unload(index: int) -> None:
    """
    Remove model from VRAM and free memory.
    Called by Rust orchestrator before loading the other model (VRAM swap).
    """
    if index not in _registry:
        log.info(f"Model index {index} not loaded — nothing to unload")
        return

    log.info(f"Unloading model index {index}...")
    entry = _registry.pop(index)

    # Explicitly delete the model object and clear CUDA cache
    del entry.model
    del entry.tokenizer
    del entry

    gc.collect()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.synchronize()

    log.info(f"Model index {index} unloaded — VRAM freed")

# ── Accessors ─────────────────────────────────────────────────────────────────

def get(index: int) -> Optional[LoadedModel]:
    """Return the loaded model entry for index, or None if not loaded."""
    return _registry.get(index)

def is_loaded(index: int) -> bool:
    return index in _registry

def loaded_indices() -> list[int]:
    return list(_registry.keys())

def total_vram_used_mb() -> int:
    """Sum of VRAM across all loaded models."""
    if not torch.cuda.is_available():
        return 0
    return int(torch.cuda.memory_allocated() / (1024 * 1024))
