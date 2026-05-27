# verify_environment.ps1
# §1 — Environment Verification
#
# Run after setup_environment.ps1 to confirm everything is correctly installed.
# Also run after Windows updates to check nothing broke.
# Produces: docs\verification\setup_verification.txt
#
# Usage:
#   cd "D:\Project LLM\great sage"
#   .\scripts\verify_environment.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"   # don't abort on version check failures

$Root       = "D:\Project LLM\great sage"
$ReportDir  = "$Root\docs\verification"
$ReportFile = "$ReportDir\setup_verification.txt"
$VenvPy     = "$Root\venv\Scripts\python.exe"

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

# ─────────────────────────────────────────────────────────────────────────────
# Result tracking
# ─────────────────────────────────────────────────────────────────────────────

$results  = @()   # array of [Tool, Expected, Found, Status]
$failures = @()

function Add-Result([string]$tool, [string]$expected, [string]$found, [bool]$pass) {
    $status = if ($pass) { "PASS" } else { "FAIL" }
    $script:results += [PSCustomObject]@{
        Tool     = $tool
        Expected = $expected
        Found    = $found
        Status   = $status
    }
    if (-not $pass) { $script:failures += $tool }
    $color = if ($pass) { "Green" } else { "Red" }
    $icon  = if ($pass) { "[PASS]" } else { "[FAIL]" }
    Write-Host "  $icon  $tool — $found" -ForegroundColor $color
}

# ─────────────────────────────────────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────────────────────────────────────

function Test-Rust {
    $rustVer  = (rustc --version 2>&1)
    $cargoVer = (cargo --version 2>&1)
    $pass = $rustVer -like "*1.78*"
    Add-Result "Rust (rustc)"  "1.78.x"  "$rustVer"  $pass
    Add-Result "Cargo"         "1.78.x"  "$cargoVer" ($cargoVer -like "*1.78*")
}

function Test-Python {
    if (-not (Test-Path $VenvPy)) {
        Add-Result "Python venv" "exists at venv\" "NOT FOUND" $false
        return
    }

    $pyVer = (& $VenvPy --version 2>&1)
    Add-Result "Python (venv)" "3.11.x" "$pyVer" ($pyVer -like "*3.11*")

    # PyTorch version
    $torchVer = (& $VenvPy -c "import torch; print(torch.__version__)" 2>&1)
    Add-Result "PyTorch" "2.3.0+cu121" "$torchVer" ($torchVer -like "*2.3*")

    # CUDA visible to PyTorch
    $cudaAvail = (& $VenvPy -c "import torch; print(torch.cuda.is_available())" 2>&1)
    Add-Result "PyTorch CUDA" "True" "$cudaAvail" ($cudaAvail -eq "True")

    # GPU name
    $gpuName = (& $VenvPy -c "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')" 2>&1)
    Add-Result "GPU detected" "RTX 3050" "$gpuName" ($gpuName -like "*3050*")

    # Key packages
    foreach ($pkg in @("vosk", "anthropic", "grpcio", "playwright", "sentence_transformers")) {
        $ver = (& $VenvPy -c "import $pkg; print(getattr($pkg, '__version__', 'ok'))" 2>&1)
        $pass = $ver -notlike "*Error*" -and $ver -notlike "*No module*"
        Add-Result "Python: $pkg" "installed" $(if ($pass) { $ver } else { "MISSING" }) $pass
    }
}

function Test-CUDA {
    # nvcc
    $nvccVer = (nvcc --version 2>&1 | Select-String "release")
    Add-Result "CUDA (nvcc)"  "12.1" "$nvccVer" ($nvccVer -like "*12.1*")

    # nvidia-smi VRAM
    $smiOut  = (nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>&1)
    $pass    = $smiOut -like "*3050*" -or $smiOut -like "*NVIDIA*"
    Add-Result "nvidia-smi"  "GPU visible" "$smiOut" $pass

    # CUDA_HOME env var
    $cudaHome = $env:CUDA_HOME
    Add-Result "CUDA_HOME env" "set" $(if ($cudaHome) { $cudaHome } else { "NOT SET" }) ([bool]$cudaHome)
}

function Test-Go {
    $goVer = (go version 2>&1)
    Add-Result "Go" "1.22.x" "$goVer" ($goVer -like "*go1.22*")

    $goPath = $env:GOPATH
    Add-Result "GOPATH env" "set" $(if ($goPath) { $goPath } else { "NOT SET" }) ([bool]$goPath)
}

function Test-SupportTools {
    # Git
    $gitVer = (git --version 2>&1)
    Add-Result "Git" "any" "$gitVer" ($gitVer -like "*git version*")

    # Node.js
    $nodeVer = (node --version 2>&1)
    Add-Result "Node.js" "20.x" "$nodeVer" ($nodeVer -like "*v20*")

    # Tesseract
    $tessVer = (tesseract --version 2>&1 | Select-Object -First 1)
    Add-Result "Tesseract OCR" "5.x" "$tessVer" ($tessVer -like "*5.*")

    # ffmpeg
    $ffVer = (ffmpeg -version 2>&1 | Select-Object -First 1)
    Add-Result "ffmpeg" "any" "$ffVer" ($ffVer -like "*ffmpeg*")

    # protoc
    $protocVer = (protoc --version 2>&1)
    Add-Result "protoc" "any" "$protocVer" ($protocVer -like "*libprotoc*")

    # Mermaid CLI
    $mmdcVer = (mmdc --version 2>&1)
    Add-Result "Mermaid CLI (mmdc)" "any" "$mmdcVer" ($mmdcVer -match "\d+\.\d+")
}

function Test-ProjectFiles {
    $checks = @(
        @{ Path = "$Root\proto\tempest.proto";                       Label = "proto\tempest.proto" },
        @{ Path = "$Root\config\grpc_ports.toml";                   Label = "config\grpc_ports.toml" },
        @{ Path = "$Root\config\paths.toml";                        Label = "config\paths.toml" },
        @{ Path = "$Root\services\orchestrator\Cargo.toml";         Label = "orchestrator\Cargo.toml" },
        @{ Path = "$Root\services\orchestrator\build.rs";           Label = "orchestrator\build.rs" },
        @{ Path = "$Root\services\inference\requirements.txt";      Label = "inference\requirements.txt" },
        @{ Path = "$Root\services\gateway\go.mod";                  Label = "gateway\go.mod" },
        @{ Path = "$Root\scripts\setup_environment.ps1";            Label = "scripts\setup_environment.ps1" },
        @{ Path = "$Root\scripts\generate_proto.ps1";               Label = "scripts\generate_proto.ps1" },
        @{ Path = "$Root\models\great_sage\base_weights_original\download_complete.txt"; Label = "model weights downloaded" }
    )

    foreach ($c in $checks) {
        $exists = Test-Path $c.Path
        Add-Result $c.Label "exists" $(if ($exists) { "found" } else { "MISSING" }) $exists
    }
}

function Test-HuggingFaceEnv {
    $hfHome = $env:HF_HOME
    Add-Result "HF_HOME env" "set to D: drive" $(if ($hfHome) { $hfHome } else { "NOT SET" }) ($hfHome -like "*Project LLM*")
}

# ─────────────────────────────────────────────────────────────────────────────
# Write Report
# ─────────────────────────────────────────────────────────────────────────────

function Write-VerificationReport {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $overall   = if ($failures.Count -eq 0) { "READY TO BUILD" } else { "BLOCKED" }

    $lines = @()
    $lines += "Great Sage × Tempest — Environment Verification Report"
    $lines += "Generated: $timestamp"
    $lines += "Overall:   $overall"
    if ($failures.Count -gt 0) {
        $lines += "Failures:  $($failures -join ', ')"
    }
    $lines += ""
    $lines += ("Tool".PadRight(35) + "Expected".PadRight(20) + "Found".PadRight(40) + "Status")
    $lines += ("-" * 100)
    foreach ($r in $results) {
        $found = $r.Found
        if ($found.Length -gt 38) { $found = $found.Substring(0, 35) + "..." }
        $lines += ($r.Tool.PadRight(35) + $r.Expected.PadRight(20) + $found.PadRight(40) + $r.Status)
    }
    $lines += ""
    if ($overall -eq "READY TO BUILD") {
        $lines += "All checks passed. Proceed to Part 2 (Inference Engine & Quantization)."
    } else {
        $lines += "Fix the items marked FAIL before proceeding."
        $lines += "Re-run setup_environment.ps1 for any missing installations."
    }

    $lines | Set-Content -Path $ReportFile -Encoding UTF8
    Write-Host ""
    Write-Host "  Report written to: $ReportFile" -ForegroundColor Gray
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Great Sage × Tempest — Environment Verify  (§1)    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "[ Rust ]" -ForegroundColor DarkCyan;        Test-Rust
Write-Host ""
Write-Host "[ Python / PyTorch ]" -ForegroundColor DarkCyan; Test-Python
Write-Host ""
Write-Host "[ CUDA ]" -ForegroundColor DarkCyan;        Test-CUDA
Write-Host ""
Write-Host "[ Go ]" -ForegroundColor DarkCyan;          Test-Go
Write-Host ""
Write-Host "[ Support Tools ]" -ForegroundColor DarkCyan; Test-SupportTools
Write-Host ""
Write-Host "[ HuggingFace ]" -ForegroundColor DarkCyan; Test-HuggingFaceEnv
Write-Host ""
Write-Host "[ Project Files ]" -ForegroundColor DarkCyan; Test-ProjectFiles

Write-VerificationReport

Write-Host ""
if ($failures.Count -eq 0) {
    Write-Host "  RESULT: READY TO BUILD" -ForegroundColor Green
    Write-Host "  All checks passed. §1 complete. Proceed to Part 2." -ForegroundColor Green
} else {
    Write-Host "  RESULT: BLOCKED — $($failures.Count) check(s) failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    Write-Host "  Fix the above items, then re-run this script." -ForegroundColor Yellow
}
Write-Host ""
