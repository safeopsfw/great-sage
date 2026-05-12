//! Importance scoring heuristics.
//!
//! Scores exchanges from 0.0 to 1.0 based on corrections,
//! preferences, goals, explicit "remember this", recency decay,
//! and access frequency.

pub struct ImportanceSignals {
    pub is_correction: bool,
    pub is_preference: bool,
    pub is_goal: bool,
    pub is_explicit_remember: bool,
    pub is_tool_result: bool,
    pub access_count: u32,
    pub age_days: f32,
}

pub fn score(signals: &ImportanceSignals) -> f32 {
    let mut s: f32 = 0.2; // baseline

    if signals.is_correction      { s += 0.4; }
    if signals.is_preference      { s += 0.3; }
    if signals.is_goal            { s += 0.3; }
    if signals.is_explicit_remember { s += 0.5; }
    if signals.is_tool_result     { s -= 0.1; }

    // Access frequency bonus (capped)
    s += (signals.access_count as f32 * 0.05).min(0.2);

    // Recency decay: exponential with half-life 30 days
    let decay = (-(signals.age_days / 30.0) * 0.693).exp();
    s *= decay;

    s.clamp(0.0, 1.0)
}
