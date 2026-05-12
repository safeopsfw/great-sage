//! Web fetch tool — readability-rs page extraction.
//!
//! Fetches HTML, strips boilerplate, returns clean text.

pub struct FetchedPage {
    pub url: String,
    pub final_url: String,
    pub title: Option<String>,
    pub byline: Option<String>,
    pub clean_text: String,
}

// TODO: Phase 5 — implement reqwest fetch + readability extraction.
