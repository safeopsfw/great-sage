//! great-sage.toml → typed config structs.

use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct GreatSageConfig {
    pub general: GeneralConfig,
    pub inference: InferenceConfig,
    pub memory: MemoryConfig,
    pub agent: AgentConfig,
    // TODO: add remaining sections
}

#[derive(Debug, Deserialize)]
pub struct GeneralConfig {
    pub name: String,
    pub version: String,
    pub log_level: String,
}

#[derive(Debug, Deserialize)]
pub struct InferenceConfig {
    pub model_path: String,
    pub device: String,
    pub gpu_layers: u32,
}

#[derive(Debug, Deserialize)]
pub struct MemoryConfig {
    pub data_dir: String,
    pub summary_count: usize,
    pub top_k: usize,
    pub embedding_model: String,
}

#[derive(Debug, Deserialize)]
pub struct AgentConfig {
    pub max_iterations: usize,
}

pub fn load_config(path: &str) -> anyhow::Result<GreatSageConfig> {
    let content = std::fs::read_to_string(path)?;
    let config: GreatSageConfig = toml::from_str(&content)?;
    Ok(config)
}
