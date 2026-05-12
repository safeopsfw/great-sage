//! Path B: Hand-rolled BPE from scratch.
//!
//! ~500 lines of Rust. Learning exercise that becomes Track A's tokenizer.
//! Train → Encode → Decode → Special tokens.

use crate::Tokenizer;

pub struct BpeScratchTokenizer {
    // TODO: vocab map, merge table, special tokens
}

impl BpeScratchTokenizer {
    /// Train a BPE vocabulary from a text corpus.
    pub fn train(_corpus: &str, _vocab_size: usize) -> anyhow::Result<Self> {
        todo!("Phase 2: implement BPE training")
    }
}

impl Tokenizer for BpeScratchTokenizer {
    fn encode(&self, _text: &str, _add_special_tokens: bool) -> anyhow::Result<Vec<u32>> {
        todo!("Phase 2: implement BPE encode")
    }

    fn decode(&self, _ids: &[u32], _skip_special_tokens: bool) -> anyhow::Result<String> {
        todo!("Phase 2: implement BPE decode")
    }

    fn vocab_size(&self) -> usize {
        todo!("Phase 2: return vocab size")
    }
}
