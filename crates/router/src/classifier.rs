//! 3-layer MLP classifier over embeddings.
//!
//! query → tokenize → embed → mean-pool → 384-d → MLP(384→128→5) → softmax.
//! Total routing latency: <15 ms on CPU.

// TODO: Phase 6 — implement embedding-based domain classifier.
