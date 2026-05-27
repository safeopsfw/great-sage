"""
config.py — Reads config\paths.toml and config\vram_limits.toml at startup.
All other modules import from here — no other file reads TOML directly.
"""

import tomllib
import os
from pathlib import Path
from dataclasses import dataclass

# ── Locate project root (two levels up from services\inference\src\) ──────────
_SRC_DIR  = Path(__file__).parent
_SVC_DIR  = _SRC_DIR.parent
_ROOT     = _SVC_DIR.parent.parent   # D:\Project LLM\great sage

# ── Load TOML files ───────────────────────────────────────────────────────────

def _load_toml(path: Path) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)

_paths_raw  = _load_toml(_ROOT / "config" / "paths.toml")["paths"]
_vram_raw   = _load_toml(_ROOT / "config" / "vram_limits.toml")
_ports_raw  = _load_toml(_ROOT / "config" / "grpc_ports.toml")["ports"]

# ── Paths ─────────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Paths:
    project_root:       Path
    model_gs_current:   Path   # Index 0 — Great Sage (AWQ INT4 after §6)
    model_gs_base:      Path   # Index 0 — base FP16 weights (for dev/testing)
    model_prof_current: Path   # Index 1 — Professor (AWQ INT4 after §6)
    model_prof_base:    Path   # Index 1 — base FP16 weights
    model_gs_tokenizer: Path
    model_prof_tokenizer: Path
    faiss_index:        Path
    logs_dir:           Path
    proto_python_out:   Path   # where tempest_pb2.py lives

PATHS = Paths(
    project_root       = Path(_paths_raw["project_root"]),
    model_gs_current   = Path(_paths_raw["model_gs_current"]),
    model_gs_base      = Path(_paths_raw["model_gs_base"]),
    model_prof_current = Path(_paths_raw["model_prof_current"]),
    model_prof_base    = Path(_paths_raw["model_prof_base"]),
    model_gs_tokenizer = Path(_paths_raw["model_gs_tokenizer"]),
    model_prof_tokenizer = Path(_paths_raw["model_prof_tokenizer"]),
    faiss_index        = Path(_paths_raw["faiss_index"]),
    logs_dir           = Path(_paths_raw["logs_dir"]),
    proto_python_out   = Path(_paths_raw["proto_python_out"]),
)

# ── VRAM Limits ───────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class VRAMConfig:
    hard_limit_mb:          int   # kill switch — never exceed this
    chat_mode_budget_mb:    int   # Index 0 only
    teaching_mode_budget_mb: int  # Index 0 + Index 1
    compression_trigger_mb: int   # start context compression above this
    embedder_device:        str   # "cpu" — BGE-M3 always on CPU
    inference_device:       str   # "cuda:0" — RTX 3050
    igpu_fallback_device:   str   # "cpu" — Intel UHD via CPU inference

# vram_limits.toml uses MB integers
_vl = _vram_raw.get("vram", _vram_raw)  # handle flat or nested toml

VRAM = VRAMConfig(
    hard_limit_mb           = _vl.get("hard_limit_mb",           3700),
    chat_mode_budget_mb     = _vl.get("chat_mode_budget_mb",      900),
    teaching_mode_budget_mb = _vl.get("teaching_mode_budget_mb", 2900),
    compression_trigger_mb  = _vl.get("compression_trigger_mb",  3200),
    embedder_device         = _vl.get("embedder_device",         "cpu"),
    inference_device        = _vl.get("inference_device",       "cuda:0"),
    igpu_fallback_device    = _vl.get("igpu_fallback_device",   "cpu"),
)

# ── Ports ─────────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Ports:
    python_inference: int   # this service listens here

PORTS = Ports(
    python_inference = _ports_raw["python_inference"],  # 50052
)

# ── Model index constants ──────────────────────────────────────────────────────

INDEX_GREAT_SAGE  = 0   # Qwen2.5-1.5B-Instruct
INDEX_PROFESSOR   = 1   # Phi-3.5-mini-instruct

# ── Resolve active model path ──────────────────────────────────────────────────
# After §6 (AWQ quantization), "current" folder has AWQ weights.
# Before §6, falls back to base FP16 weights so server still starts.

def resolve_model_path(index: int) -> Path:
    """Return the best available weights path for a model index."""
    if index == INDEX_GREAT_SAGE:
        current = PATHS.model_gs_current
        base    = PATHS.model_gs_base
    elif index == INDEX_PROFESSOR:
        current = PATHS.model_prof_current
        base    = PATHS.model_prof_base
    else:
        raise ValueError(f"Unknown model index: {index}")

    # Prefer AWQ-quantized weights (current/), fall back to FP16 base
    if (current / "config.json").exists():
        return current
    if (base / "config.json").exists():
        return base
    raise FileNotFoundError(
        f"No weights found for model index {index}. "
        f"Checked: {current}, {base}"
    )
