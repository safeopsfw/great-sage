//! Safety guard — path / scheme / SSRF checks.
//!
//! - Allow-list scheme: only https:// URLs
//! - SSRF protection: reject RFC1918 / loopback / link-local IPs
//! - Size cap: refuse fetches over 5 MB
//! - Timeout: 10 seconds default
//! - Path traversal: reject ".." in filesystem paths

/// Check if a URL is safe to fetch.
pub fn validate_url(_url: &str) -> anyhow::Result<()> {
    todo!("Phase 5: implement URL safety checks")
}

/// Check if a filesystem path is within allowed roots.
pub fn validate_path(_path: &str, _allowed_roots: &[String]) -> anyhow::Result<()> {
    todo!("Phase 4: implement path safety checks")
}
