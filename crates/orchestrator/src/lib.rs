//! Friday Orchestrator
//!
//! Phase 8: The main runtime that wires all subsystems together.
//! - startup.rs: initialization sequence
//! - main_loop.rs: primary event loop
//! - config.rs: friday.toml → typed config
//! - scheduler.rs: weekly cron tasks

pub mod startup;
pub mod main_loop;
pub mod config;
pub mod scheduler;
