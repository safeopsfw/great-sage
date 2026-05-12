//! Read pipeline / context builder.
//!
//! Assembles L4 facts + L3 retrieved memories + L2 summaries
//! into a ContextBundle for prompt injection.

pub struct ContextBundle {
    pub facts: Vec<(String, String)>,
    pub memories: Vec<String>,
    pub summaries: Vec<String>,
}

pub struct MemoryConfig {
    pub summary_count: usize,
    pub top_k: usize,
}

pub fn build_context(_query: &str, _cfg: &MemoryConfig) -> ContextBundle {
    todo!("Phase 3: assemble context from L2 + L3 + L4")
}
