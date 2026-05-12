//! The Great Sage binary — main entry point for the orchestrator.

use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    tracing::info!("Great Sage starting up...");

    // TODO: Phase 8 — initialize all subsystems and enter main loop.
    println!("Great Sage orchestrator — not yet implemented.");
    println!("Use great-sage-cli for interactive sessions.");

    Ok(())
}
