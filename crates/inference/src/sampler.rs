//! Token sampling strategies: greedy, temperature, top-p, repeat penalty.

/// Configuration for token sampling.
pub struct SamplingConfig {
    /// 0.0 = greedy (argmax)
    pub temperature: f32,
    /// 1.0 = no nucleus filter
    pub top_p: f32,
    /// 0 = disabled
    pub top_k: usize,
    /// 1.0 = no penalty
    pub repeat_penalty: f32,
    /// Number of recent tokens to apply repeat penalty over
    pub repeat_last_n: usize,
}

impl Default for SamplingConfig {
    fn default() -> Self {
        Self {
            temperature: 0.7,
            top_p: 0.9,
            top_k: 0,
            repeat_penalty: 1.1,
            repeat_last_n: 64,
        }
    }
}

/// Given logits over the vocabulary, sample the next token ID.
pub fn sample(_logits: &candle_core::Tensor, _config: &SamplingConfig) -> anyhow::Result<u32> {
    todo!("Phase 1: implement sampling strategies")
}
