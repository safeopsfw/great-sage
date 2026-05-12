//! friday-cli — command-line interface for Friday.
//!
//! Subcommands:
//! - chat:     interactive REPL or single-shot prompt
//! - research: research-mode deep search
//! - refresh:  manual self-learning trigger
//! - diagnose: doctor checks for system health

use clap::{Parser, Subcommand};

mod chat;
mod research;
mod refresh;
mod diagnose;

#[derive(Parser)]
#[command(name = "friday-cli")]
#[command(about = "Friday personal AI assistant — CLI interface")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Interactive chat (REPL) or single-shot prompt
    Chat {
        /// Single-shot prompt (skip REPL)
        #[arg(long)]
        once: Option<String>,

        /// Path to GGUF model file
        #[arg(long)]
        model: Option<String>,

        /// Sampling temperature
        #[arg(long, default_value_t = 0.7)]
        temp: f32,

        /// Top-p (nucleus sampling)
        #[arg(long, default_value_t = 0.9)]
        top_p: f32,
    },

    /// Research mode — multi-step search and synthesis
    Research {
        /// The research question
        query: String,
    },

    /// Manual self-learning refresh trigger
    Refresh,

    /// Doctor checks — verify system health
    Diagnose,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    let cli = Cli::parse();

    match cli.command {
        Commands::Chat { once, model, temp, top_p } => {
            chat::run(once, model, temp, top_p).await
        }
        Commands::Research { query } => {
            research::run(&query).await
        }
        Commands::Refresh => {
            refresh::run().await
        }
        Commands::Diagnose => {
            diagnose::run().await
        }
    }
}
