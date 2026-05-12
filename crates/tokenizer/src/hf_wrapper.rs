//! Path A: HuggingFace `tokenizers` crate wrapper.
//!
//! Fast, correct, matches every published model's tokenizer.json.

use crate::Tokenizer;

pub struct HfTokenizer {
    // TODO: wrap tokenizers::Tokenizer
}

impl HfTokenizer {
    pub fn from_file(_path: &str) -> anyhow::Result<Self> {
        todo!("Phase 2: load tokenizer.json")
    }
}

impl Tokenizer for HfTokenizer {
    fn encode(&self, _text: &str, _add_special_tokens: bool) -> anyhow::Result<Vec<u32>> {
        todo!("Phase 2: implement HF encode")
    }

    fn decode(&self, _ids: &[u32], _skip_special_tokens: bool) -> anyhow::Result<String> {
        todo!("Phase 2: implement HF decode")
    }

    fn vocab_size(&self) -> usize {
        todo!("Phase 2: return vocab size")
    }
}
