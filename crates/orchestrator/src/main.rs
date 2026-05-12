//! The friday binary — main entry point for the orchestrator.

use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    tracing::info!("Friday starting up...");

    // TODO: Phase 8 — initialize all subsystems and enter main loop.
    println!("Friday orchestrator — not yet implemented.");
    println!("Use friday-cli for interactive sessions.");

    Ok(())
}
