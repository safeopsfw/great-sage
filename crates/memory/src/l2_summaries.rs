//! L2 — Rolling Hierarchical Summaries
//!
//! Circular buffer of ~200 short summaries (~80 tokens each).
//! Older summaries are recursively compacted.

pub struct L2Summaries {
    // TODO: circular buffer of summary entries
}

impl L2Summaries {
    pub fn new(_capacity: usize) -> Self {
        todo!("Phase 3: implement L2 summary buffer")
    }

    pub fn recent(&self, _count: usize) -> Vec<String> {
        todo!("Phase 3: return recent summaries")
    }

    pub fn push(&mut self, _summary: String) {
        todo!("Phase 3: add summary, compact if at capacity")
    }
}
