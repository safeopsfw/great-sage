//! Chat subcommand — one-shot prompt or interactive REPL.

pub async fn run(
    _once: Option<String>,
    _model: Option<String>,
    _temp: f32,
    _top_p: f32,
) -> anyhow::Result<()> {
    todo!("Phase 1: implement chat REPL and single-shot mode")
}
