# build_all.ps1 — Builds all three services in dependency order.
# Run from D:\Project LLM\great sage\ as working directory.
# Implemented fully in Part 17 (Operations). This is a stub with the build sequence.

$root = $PSScriptRoot | Split-Path -Parent
$venv = "$root\venv\Scripts\Activate.ps1"

Write-Host "=== Great Sage — Full Build ===" -ForegroundColor Cyan

# Step 1 — Python packages
Write-Host "`n[1/4] Installing Python dependencies..." -ForegroundColor Yellow
& $venv
pip install -r "$root\services\inference\requirements.txt"
if ($LASTEXITCODE -ne 0) { Write-Host "pip install failed." -ForegroundColor Red; exit 1 }

# Step 2 — Rust orchestrator (release build)
Write-Host "`n[2/4] Building Rust orchestrator (release)..." -ForegroundColor Yellow
Push-Location $root
cargo build --release
if ($LASTEXITCODE -ne 0) { Write-Host "cargo build failed." -ForegroundColor Red; Pop-Location; exit 1 }
Pop-Location

# Step 3 — Go gateway dependencies
Write-Host "`n[3/4] Fetching Go dependencies..." -ForegroundColor Yellow
Push-Location "$root\services\gateway"
go mod tidy
if ($LASTEXITCODE -ne 0) { Write-Host "go mod tidy failed." -ForegroundColor Red; Pop-Location; exit 1 }
Pop-Location

# Step 4 — Go gateway build (skipped until gateway src exists in Part 9)
Write-Host "`n[4/4] Go gateway build — deferred to Part 9." -ForegroundColor DarkGray

Write-Host "`n=== Build complete ===" -ForegroundColor Green
