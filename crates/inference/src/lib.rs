//! Great Sage Inference Engine
//!
//! Phase 1: GGUF model loading, forward pass, KV cache management,
//! sampling strategies, chat templates, and token streaming.

pub mod backend;
pub mod sampler;
pub mod chat_template;
pub mod streaming;
