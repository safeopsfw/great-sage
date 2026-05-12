//! Friday Memory System
//!
//! Phase 3: Four-layer memory architecture:
//! - L1: Live KV cache (thin wrapper over inference KV cache)
//! - L2: Rolling hierarchical summaries (circular buffer + recursive compaction)
//! - L3: Semantic vector store (HNSW index + payloads)
//! - L4: Permanent fact store (SQLite)
//!
//! Plus: importance scoring, async write pipeline, and context assembly.

pub mod l1_kv_cache;
pub mod l2_summaries;
pub mod l3_vector;
pub mod l4_facts;
pub mod importance;
pub mod writer;
pub mod context;
pub mod embedder;
