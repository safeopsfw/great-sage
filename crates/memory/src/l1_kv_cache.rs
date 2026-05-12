//! L1 — Live KV Cache
//!
//! Thin wrapper over the inference engine's KV cache.
//! Tracks current token position and triggers summarization
//! when the cache exceeds 80% capacity.

pub struct L1KvCache {
    pub capacity: usize,
    pub position: usize,
}

impl L1KvCache {
    pub fn new(capacity: usize) -> Self {
        Self { capacity, position: 0 }
    }

    pub fn usage_ratio(&self) -> f32 {
        self.position as f32 / self.capacity as f32
    }

    pub fn needs_eviction(&self) -> bool {
        self.usage_ratio() > 0.8
    }
}
