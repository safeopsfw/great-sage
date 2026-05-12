//! L4 — Permanent Fact Store
//!
//! SQLite-backed key-value facts (name, job, preferences).
//! ~500 facts, never evicted. Always injected into every prompt.

pub struct L4FactStore {
    // TODO: rusqlite::Connection
}

impl L4FactStore {
    pub fn open(_path: &str) -> anyhow::Result<Self> {
        todo!("Phase 3: open or create SQLite fact store")
    }

    pub fn upsert(&self, _key: &str, _value: &str) -> anyhow::Result<()> {
        todo!("Phase 3: insert or update a fact")
    }

    pub fn all(&self) -> anyhow::Result<Vec<(String, String)>> {
        todo!("Phase 3: return all facts")
    }
}
