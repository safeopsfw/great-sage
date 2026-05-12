//! Adapter manifest / metadata.
//!
//! Tracks available adapters: name, domain, file path, version, rank.

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct AdapterInfo {
    pub name: String,
    pub domain: String,
    pub path: String,
    pub rank: u32,
    pub version: String,
}

// TODO: Phase 6 — implement adapter discovery and manifest loading.
