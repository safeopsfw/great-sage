"""
bge_m3.py — BGE-M3 text embeddings (768-dim) on CPU / Intel UHD.
Zero RTX 3050 VRAM — intentionally runs on CPU so inference VRAM stays free.

Intel UHD has 15.8 GB shared memory — more than enough for BGE-M3 (~570M params).
Embeddings run in a separate thread pool so they never block token generation.
"""

import asyncio
import logging
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Union

import numpy as np

log = logging.getLogger(__name__)

# One thread for embeddings — CPU-bound, no benefit from more threads here
_embed_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="embed")

_MODEL_ID = "BAAI/bge-m3"   # downloaded to hf_cache on first run

# ── Lazy load — model only loads when first embed() call arrives ──────────────

_encoder = None
_lock    = asyncio.Lock()

def _load_encoder():
    """Load BGE-M3 synchronously (called once, in thread pool)."""
    global _encoder
    if _encoder is not None:
        return

    from sentence_transformers import SentenceTransformer
    log.info(f"Loading BGE-M3 embeddings model ({_MODEL_ID}) on CPU...")
    _encoder = SentenceTransformer(_MODEL_ID, device="cpu")
    # Normalise embeddings so cosine similarity = dot product (faster in FAISS)
    _encoder.max_seq_length = 512
    log.info("BGE-M3 loaded on CPU — ready for embeddings")


# ── Single embed ──────────────────────────────────────────────────────────────

def _embed_sync(text: str) -> list[float]:
    """Synchronous — embed one string, return 768-dim float list."""
    _load_encoder()
    vec = _encoder.encode(
        text,
        normalize_embeddings=True,   # L2-normalise for cosine similarity
        show_progress_bar=False,
        batch_size=1,
    )
    return vec.tolist()


async def embed(text: str) -> list[float]:
    """
    Async single embed — runs in thread pool, non-blocking.
    Returns 768-dimensional float list.

    Usage:
        vec = await bge_m3.embed("what is ARP poisoning?")
    """
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(_embed_executor, _embed_sync, text)


# ── Batch embed ───────────────────────────────────────────────────────────────

def _embed_batch_sync(texts: list[str]) -> list[list[float]]:
    """Synchronous — embed multiple strings at once (more efficient than loop)."""
    _load_encoder()
    vecs = _encoder.encode(
        texts,
        normalize_embeddings=True,
        show_progress_bar=False,
        batch_size=32,             # BGE-M3 on CPU: 32 is a good batch size
        convert_to_numpy=True,
    )
    return vecs.tolist()


async def embed_batch(texts: list[str]) -> list[list[float]]:
    """
    Async batch embed — for bulk ingestion in knowledge pipeline (§15).
    Returns list of 768-dim float lists, one per input text.

    Usage:
        vecs = await bge_m3.embed_batch(["text1", "text2", "text3"])
    """
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(_embed_executor, _embed_batch_sync, texts)


# ── Warm up ───────────────────────────────────────────────────────────────────

async def warmup() -> None:
    """
    Pre-load BGE-M3 at server startup so the first real request isn't slow.
    Call this from server.py after gRPC server starts.
    """
    log.info("Warming up BGE-M3 embedder...")
    await embed("warmup")
    log.info("BGE-M3 warmup complete — embedder ready")
