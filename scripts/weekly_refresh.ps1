# weekly_refresh.ps1 — Trigger the weekly self-learning LoRA refresh.
#
# This script is meant to be called by Windows Task Scheduler
# or manually via: .\scripts\weekly_refresh.ps1

$ErrorActionPreference = "Stop"

Write-Host "Friday Weekly Refresh" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

$FridayCli = Join-Path $PSScriptRoot "..\target\release\friday-cli.exe"

if (Test-Path $FridayCli) {
    & $FridayCli refresh
} else {
    Write-Host "friday-cli not found. Build with: cargo build --release -p friday-cli" -ForegroundColor Red
}
