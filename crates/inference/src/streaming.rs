//! Token stream channel — yields each sampled token as soon as it is decoded.
//!
//! Phase 7 (voice) subscribes to this channel to feed sentences to TTS
//! as they arrive.

use tokio::sync::mpsc;

/// A single streamed token fragment.
pub struct TokenFragment {
    pub token_id: u32,
    pub text: String,
    pub is_final: bool,
}

/// Create a token streaming channel.
pub fn token_channel(buffer: usize) -> (mpsc::Sender<TokenFragment>, mpsc::Receiver<TokenFragment>) {
    mpsc::channel(buffer)
}
