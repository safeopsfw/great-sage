//! Great Sage Tool Registry
//!
//! Phase 4 + 5: Tool trait, registry, and built-in tools:
//! - Core: get_time, system_info, files, notes
//! - Calculate: sandboxed math evaluator
//! - Run command: allow-listed shell commands
//! - Web search: DuckDuckGo / Brave / Tavily
//! - Web fetch: readability-rs page extraction
//! - Research mode: multi-step subagent
//! - Guard: path / scheme / SSRF checks

pub mod core;
pub mod calculate;
pub mod run_command;
pub mod web_search;
pub mod web_fetch;
pub mod research_mode;
pub mod guard;

use anyhow::Result;
use serde_json::Value;

/// A tool that the agent can invoke.
pub trait Tool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn invoke(&self, args: Value) -> Result<Value>;
}

/// Registry of all available tools.
pub struct ToolRegistry {
    tools: Vec<Box<dyn Tool>>,
}

impl ToolRegistry {
    pub fn new() -> Self {
        Self { tools: Vec::new() }
    }

    pub fn register(&mut self, tool: Box<dyn Tool>) {
        self.tools.push(tool);
    }

    pub fn invoke(&self, name: &str, args: Value) -> Result<Value> {
        let tool = self.tools.iter()
            .find(|t| t.name() == name)
            .ok_or_else(|| anyhow::anyhow!("Unknown tool: {name}"))?;
        tool.invoke(args)
    }

    pub fn descriptions(&self) -> Vec<(&str, &str)> {
        self.tools.iter().map(|t| (t.name(), t.description())).collect()
    }
}
