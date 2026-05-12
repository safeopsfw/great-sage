//! Backend trait + GGUF Llama implementation.
//!
//! Wraps candle's quantized_llama module behind a trait so future models
//! (Mistral, Phi-3, Qwen) can be plugged in.

use anyhow::Result;
use candle_core::Tensor;
use std::path::Path;

/// Abstraction over any language model backend.
pub trait Backend {
    /// Run a forward pass over the given token IDs starting at position `pos`.
    /// Returns logits over the vocabulary.
    fn forward(&mut self, tokens: &[u32], pos: usize) -> Result<Tensor>;

    /// Reset the KV cache (start a new conversation).
    fn reset_cache(&mut self);
}

/// Quantized Llama backend using candle-transformers' GGUF loader.
pub struct QuantizedLlamaBackend {
    // TODO: candle's loaded model + KV cache state
}

impl Backend for QuantizedLlamaBackend {
    fn forward(&mut self, _tokens: &[u32], _pos: usize) -> Result<Tensor> {
        todo!("Phase 1: implement forward pass")
    }

    fn reset_cache(&mut self) {
        todo!("Phase 1: implement cache reset")
    }
}

/// Load a GGUF model file and return a boxed Backend.
pub fn load_gguf(_path: &Path, _device: &candle_core::Device) -> Result<Box<dyn Backend>> {
    todo!("Phase 1: implement GGUF loading")
}
