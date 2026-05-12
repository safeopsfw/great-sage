//! Allow-listed shell command runner.
//!
//! Each allowed command is a struct: { name, executable_path,
//! allowed_args_pattern, max_duration_secs }.
//! Anything not on the list is rejected before spawn.

// TODO: Phase 4 — implement struct-typed allow-list command runner.
