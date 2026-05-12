//! Embedding model wrapper.
//!
//! V1: bge-small-en-v1.5 (33M params, 384-d output, <10ms on CPU).
//! Future: great-sage-embed from Track A replaces this.

pub struct Embedder {
    // TODO: candle model for embedding
}

impl Embedder {
    pub fn load(_model_path: &str) -> anyhow::Result<Self> {
        todo!("Phase 3: load embedding model via candle")
    }

    pub fn embed(&self, _text: &str) -> anyhow::Result<Vec<f32>> {
        todo!("Phase 3: encode text to 384-d embedding vector")
    }
}
