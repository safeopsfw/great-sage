//! Chat template formatting for different model families.
//!
//! Llama 3.2, Mistral, Qwen each use distinct special-token formats.

/// A single message in a chat conversation.
pub struct Message {
    pub role: Role,
    pub content: String,
}

/// Chat message roles.
pub enum Role {
    System,
    User,
    Assistant,
    Tool,
}

/// Supported chat template formats.
pub enum ChatTemplate {
    Llama3,
    Mistral,
    Qwen,
}

impl ChatTemplate {
    /// Format a list of messages according to this template.
    pub fn format(&self, _messages: &[Message]) -> String {
        todo!("Phase 1: implement chat template formatting")
    }
}
