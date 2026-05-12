//! Async write pipeline.
//!
//! After every completed exchange, runs on a background tokio task:
//! 1. SQLite append
//! 2. Importance scoring
//! 3. L3 vector insert (chunk, embed, write)
//! 4. Fact extraction (regex + tiny LLM pass)
//! 5. L1 maintenance (summarize if >80%)
//! 6. L2 maintenance (recursive compaction if at capacity)

pub async fn write_exchange(
    _user_msg: &str,
    _assistant_msg: &str,
) -> anyhow::Result<()> {
    todo!("Phase 3: implement async write pipeline")
}
