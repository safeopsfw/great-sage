//! Great Sage Voice Pipeline
//!
//! Phase 7: Full voice I/O pipeline:
//! - Audio capture / playback via cpal
//! - Ring buffer for audio data
//! - Wake word detection (ONNX)
//! - Voice activity detection
//! - Speech-to-text (whisper-rs)
//! - Text-to-speech (piper-rs)
//! - Sentence streaming from token stream

pub mod capture;
pub mod playback;
pub mod ringbuffer;
pub mod wakeword;
pub mod vad;
pub mod stt;
pub mod tts;
pub mod sentence_stream;
