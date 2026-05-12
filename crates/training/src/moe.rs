//! MoE FFN + load balance loss.
//!
//! Mixture-of-Experts feed-forward network: N small experts + router.
//! Top-K selection per token. Load balancing loss prevents expert collapse.

// TODO: Phase 10 — implement MoE layer with auxiliary loss.
