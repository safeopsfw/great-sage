//! Great Sage Training Engine
//!
//! Phases 6, 9, 10, 11: Covers pretraining (nanoGPT, MoE),
//! LoRA fine-tuning, weekly self-learning refresh,
//! data loading, evaluation, and checkpointing.

pub mod pretrain;
pub mod moe;
pub mod lora;
pub mod finetune;
pub mod refresh;
pub mod data;
pub mod eval;
pub mod checkpoint;
