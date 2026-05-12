# Decision Log

Architectural decisions and their rationale.

## D001 — Primary language: Rust
**Decision:** Rust is the primary language. Python is transitional only.
**Rationale:** No GC pauses for real-time audio, memory safety, single binary deployment.
**Date:** Project inception.

## D002 — Tensor library: candle
**Decision:** Use HuggingFace's candle for tensor math + autograd.
**Rationale:** Pure Rust, good AVX2/CUDA support, GGUF loader built-in.
**Date:** Project inception.

## D003 — CPU-first inference
**Decision:** Default inference on CPU; GPU reserved for training and optional offload.
**Rationale:** 32 GB RAM >> 4 GB VRAM. RAM is the asset, VRAM is the bottleneck.
**Date:** Project inception.

## D004 — No online gradient updates
**Decision:** Never update model weights from live chat. Memory + weekly LoRA only.
**Rationale:** Catastrophic forgetting, drift, attack surface.
**Date:** Project inception.

_(Add new decisions as they arise)_
