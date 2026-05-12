//! Great Sage Tokenizer
//!
//! Phase 2: Tokenizer trait with two implementations:
//! - Path A: HuggingFace `tokenizers` crate wrapper (production)
//! - Path B: Hand-rolled BPE from scratch (learning)

pub mod hf_wrapper;
pub mod bpe_scratch;

/// Tokenizer trait — encode text to IDs, decode IDs to text.
pub trait Tokenizer {
    fn encode(&self, text: &str, add_special_tokens: bool) -> anyhow::Result<Vec<u32>>;
    fn decode(&self, ids: &[u32], skip_special_tokens: bool) -> anyhow::Result<String>;
    fn vocab_size(&self) -> usize;
}
