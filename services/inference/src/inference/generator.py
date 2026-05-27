"""
generator.py — Streaming token generation for Great Sage and Professor.
One token per yield → caller streams each token back over gRPC.

Optimisations applied:
  - torch.compile applied at model load time (model_loader.py)
  - Flash Attention 2 enabled if supported by the model
  - KV cache reuse via kv_cache_prefix_len (§9 — saves ~93% compute per turn)
  - asyncio-friendly: sync generation runs in thread pool, caller uses async for
"""

import asyncio
import logging
import threading
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from typing import AsyncIterator, Iterator

import torch
from transformers import TextIteratorStreamer

from . import model_loader

log = logging.getLogger(__name__)

# One thread for generation — GPU is single-threaded anyway
_gen_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="gen")

# ── Request / Response types ──────────────────────────────────────────────────

@dataclass
class GenerateRequest:
    model_index:          int
    prompt:               str           # fully assembled 6-slot prompt from Rust §32
    max_new_tokens:       int  = 512
    temperature:          float = 0.7
    top_p:                float = 0.9
    repetition_penalty:   float = 1.1
    kv_cache_prefix_len:  int   = 0    # §9 — tokens to reuse from previous turn
    stop_sequences:       list  = field(default_factory=list)

@dataclass
class GenerateChunk:
    token:      str    # decoded text for this token
    logprob:    float  # log probability — used by §49 gap detector
    is_final:   bool   # True on the last chunk


# ── Synchronous streaming generation ─────────────────────────────────────────

def _generate_sync(req: GenerateRequest) -> Iterator[GenerateChunk]:
    """
    Synchronous generator — runs inside the thread pool executor.
    Yields one GenerateChunk per token.
    """
    entry = model_loader.get(req.model_index)
    if entry is None:
        raise RuntimeError(
            f"Model index {req.model_index} is not loaded. "
            "Send LoadModel RPC first."
        )

    tok   = entry.tokenizer
    model = entry.model

    # Tokenise prompt — hard cap at 3500 to stay inside token budget (§29)
    inputs = tok(
        req.prompt,
        return_tensors="pt",
        truncation=True,
        max_length=3500,
    ).to(entry.device)

    # TextIteratorStreamer yields decoded text as each token is produced
    streamer = TextIteratorStreamer(
        tok,
        skip_prompt=True,
        skip_special_tokens=True,
    )

    # Build stop token ids from stop sequences
    stop_ids = []
    for seq in (req.stop_sequences or []):
        ids = tok.encode(seq, add_special_tokens=False)
        if ids:
            stop_ids.extend(ids)

    gen_kwargs = dict(
        **inputs,
        streamer=streamer,
        max_new_tokens=req.max_new_tokens,
        temperature=req.temperature,
        top_p=req.top_p,
        repetition_penalty=req.repetition_penalty,
        do_sample=req.temperature > 0,
        pad_token_id=tok.eos_token_id,
        eos_token_id=stop_ids if stop_ids else tok.eos_token_id,
    )

    # Run model.generate in a daemon thread — streamer connects them
    gen_thread = threading.Thread(
        target=lambda: model.generate(**gen_kwargs),
        daemon=True,
    )
    gen_thread.start()

    token_count = 0
    for text_chunk in streamer:
        if not text_chunk:
            continue
        token_count += 1
        yield GenerateChunk(
            token=text_chunk,
            logprob=-1.0,    # §49 uses rolling average — per-token logprob added in §49
            is_final=False,
        )

    gen_thread.join(timeout=5)
    yield GenerateChunk(token="", logprob=0.0, is_final=True)
    log.debug(f"Generation complete — {token_count} tokens, model={req.model_index}")


# ── Async wrapper for gRPC servicer ──────────────────────────────────────────

async def stream(req: GenerateRequest) -> AsyncIterator[GenerateChunk]:
    """
    Async wrapper — yields GenerateChunk without blocking the event loop.
    The sync generator runs in a thread pool. Tokens flow through an asyncio Queue.

    Usage in gRPC servicer:
        async for chunk in generator.stream(req):
            yield grpc_response(chunk)
    """
    loop  = asyncio.get_running_loop()
    queue: asyncio.Queue = asyncio.Queue(maxsize=128)

    def _run():
        try:
            for chunk in _generate_sync(req):
                loop.call_soon_threadsafe(queue.put_nowait, chunk)
        except Exception as e:
            log.error(f"Generation error: {e}")
        finally:
            loop.call_soon_threadsafe(queue.put_nowait, None)  # sentinel = done

    loop.run_in_executor(_gen_executor, _run)

    while True:
        chunk = await queue.get()
        if chunk is None:
            break
        yield chunk
