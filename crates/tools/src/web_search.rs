//! Web search tool — DuckDuckGo / Brave / Tavily.
//!
//! Default: DuckDuckGo HTML scraping via reqwest + scraper.
//! Behind a SearchProvider trait for easy swapping.

pub struct SearchResult {
    pub title: String,
    pub url: String,
    pub snippet: String,
    pub rank: u32,
}

// TODO: Phase 5 — implement SearchProvider trait + DuckDuckGo backend.
