"""
vram_monitor.py — Monitors RTX 3050 VRAM every 10 seconds.
Runs as a background asyncio task alongside the gRPC server.
Also exposes a synchronous snapshot() for immediate reads.
"""

import asyncio
import logging
import time
from dataclasses import dataclass

log = logging.getLogger(__name__)

# pynvml is included with nvidia-ml-py (part of torch install)
try:
    import pynvml
    pynvml.nvmlInit()
    _HANDLE  = pynvml.nvmlDeviceGetHandleByIndex(0)   # RTX 3050 = device 0
    _NVML_OK = True
except Exception as e:
    log.warning(f"pynvml unavailable ({e}) — VRAM monitor running in stub mode")
    _NVML_OK = False

# ── Snapshot dataclass ────────────────────────────────────────────────────────

@dataclass
class VRAMSnapshot:
    total_mb:     int    # physical VRAM (should be ~4096 MB for RTX 3050)
    used_mb:      int    # currently allocated
    free_mb:      int    # total - used
    util_pct:     float  # 0.0–100.0
    timestamp_ms: int    # Unix ms when this was measured

    @property
    def is_critical(self) -> bool:
        """True when free VRAM drops below 400 MB — triggers compression in §29."""
        return self.free_mb < 400

    @property
    def is_over_budget(self) -> bool:
        """True when used VRAM exceeds the 3700 MB hard limit."""
        return self.used_mb > 3700

# ── Global latest snapshot (updated every 10 s) ────────────────────────────────

_latest: VRAMSnapshot | None = None

def snapshot() -> VRAMSnapshot:
    """Synchronous: return the most recent VRAM snapshot (or measure now)."""
    if _latest is not None:
        return _latest
    return _measure()

def _measure() -> VRAMSnapshot:
    now = int(time.time() * 1000)
    if not _NVML_OK:
        # Stub for machines without NVML (CPU-only dev mode)
        return VRAMSnapshot(
            total_mb=4096, used_mb=0, free_mb=4096,
            util_pct=0.0, timestamp_ms=now
        )
    try:
        info  = pynvml.nvmlDeviceGetMemoryInfo(_HANDLE)
        total = info.total // (1024 * 1024)
        used  = info.used  // (1024 * 1024)
        free  = info.free  // (1024 * 1024)
        util  = round(used / total * 100, 1) if total > 0 else 0.0
        return VRAMSnapshot(
            total_mb=total, used_mb=used, free_mb=free,
            util_pct=util, timestamp_ms=now
        )
    except Exception as e:
        log.error(f"VRAM measure failed: {e}")
        return VRAMSnapshot(
            total_mb=4096, used_mb=0, free_mb=4096,
            util_pct=0.0, timestamp_ms=now
        )

# ── Background polling loop ───────────────────────────────────────────────────

async def run_monitor(interval_s: float = 10.0) -> None:
    """
    Asyncio task — updates global _latest every `interval_s` seconds.
    Start with:  asyncio.create_task(vram_monitor.run_monitor())
    """
    global _latest
    log.info(f"VRAM monitor started (interval: {interval_s}s)")
    while True:
        _latest = _measure()
        if _latest.is_critical:
            log.warning(
                f"VRAM CRITICAL — free: {_latest.free_mb} MB "
                f"(used: {_latest.used_mb}/{_latest.total_mb} MB)"
            )
        elif _latest.is_over_budget:
            log.error(
                f"VRAM OVER HARD LIMIT — {_latest.used_mb} MB used "
                f"(limit: 3700 MB) — unload required"
            )
        else:
            log.debug(
                f"VRAM ok — {_latest.used_mb}/{_latest.total_mb} MB "
                f"({_latest.util_pct}% used)"
            )
        await asyncio.sleep(interval_s)
