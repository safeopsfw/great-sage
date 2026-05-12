//! Chat history buffer.
//!
//! Manages the sequence of messages (system, user, assistant, tool_result)
//! fed into the inference engine.

pub struct History {
    pub messages: Vec<HistoryEntry>,
}

pub struct HistoryEntry {
    pub role: String,
    pub content: String,
}

impl History {
    pub fn new() -> Self {
        Self { messages: Vec::new() }
    }

    pub fn push_system(&mut self, content: String) {
        self.messages.push(HistoryEntry { role: "system".into(), content });
    }

    pub fn push_user(&mut self, content: &str) {
        self.messages.push(HistoryEntry { role: "user".into(), content: content.into() });
    }

    pub fn push_assistant(&mut self, content: &str) {
        self.messages.push(HistoryEntry { role: "assistant".into(), content: content.into() });
    }

    pub fn push_tool_result(&mut self, content: &str) {
        self.messages.push(HistoryEntry { role: "tool".into(), content: content.into() });
    }
}
