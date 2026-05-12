# weekly_refresh.ps1 — Trigger the weekly self-learning LoRA refresh.
#
# This script is meant to be called by Windows Task Scheduler
# or manually via: .\scripts\weekly_refresh.ps1

$ErrorActionPreference = "Stop"

Write-Host "Great Sage Weekly Refresh" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

$GreatSageCli = Join-Path $PSScriptRoot "..\target\release\great-sage-cli.exe"

if (Test-Path $GreatSageCli) {
    & $GreatSageCli refresh
} else {
    Write-Host "great-sage-cli not found. Build with: cargo build --release -p great-sage-cli" -ForegroundColor Red
}
