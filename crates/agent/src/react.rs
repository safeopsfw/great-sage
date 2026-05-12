//! ReAct loop — Reason → Act → Observe → repeat.
//!
//! The model thinks aloud, optionally emits a tool call, reads the result,
//! thinks again, and eventually writes a final answer with no tool call.

pub struct AgentConfig {
    pub max_iterations: usize,
}

impl Default for AgentConfig {
    fn default() -> Self {
        Self { max_iterations: 8 }
    }
}

pub async fn run(_query: &str, _cfg: &AgentConfig) -> anyhow::Result<String> {
    todo!("Phase 4: implement ReAct loop")
}
