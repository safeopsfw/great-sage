# Great Sage / Tempest

Voice-first personal AI assistant running entirely on a single laptop.

## What this is

Great Sage is a voice-controlled AI assistant powered by the Tempest infrastructure
layer. It runs two fine-tuned Phi-3.5-mini-instruct models — Great Sage for general
conversation and Professor for IT certification teaching — entirely offline on an
NVIDIA RTX 3050 (4 GB VRAM). The only external service is the Claude API, used as
a fallback when local knowledge is insufficient.

## System components

| Service | Language | Role |
|---------|----------|------|
| Orchestrator | Rust | Session lifecycle, memory, routing, security |
| Inference | Python | Model serving, embeddings, STT, TTS |
| Gateway | Go | HTTP/WebSocket server, internet whitelist |

## Two models

| Model | Purpose |
|-------|---------|
| Great Sage | General conversation, task routing, gap-fill decisions |
| Professor | IT/security certification teaching only |

## Key constraint

Single machine only. 4 GB VRAM hard ceiling. Fully offline except Claude API.

## Status

Phase 1 — Foundation in progress.

## Full documentation

See docs\03_complete_blueprint.md for the complete system design.
