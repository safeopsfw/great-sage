//! Tool-call JSON detection.
//!
//! Parses model output lines for JSON tool-call objects.
//! Uses regex + balanced-brace heuristic + serde_json validation.

use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct ToolCall {
    pub tool: String,
    pub args: serde_json::Value,
}

/// Attempt to extract a tool call from the model's response text.
pub fn parse_tool_call(_response: &str) -> Option<ToolCall> {
    todo!("Phase 4: implement tool-call JSON detection")
}
