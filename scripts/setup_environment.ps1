# setup_environment.ps1
# §1 — Single Dev/Prod Environment Setup
#
# Run this ONCE on a fresh machine or after a Windows reinstall.
# Run as Administrator — some steps write to system environment variables.
#
# Usage:
#   cd "D:\Project LLM\great sage"
#   .\scripts\setup_environment.ps1
#
# After this completes, run verify_environment.ps1 to confirm everything passed.

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = "D:\Project LLM\great sage"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

function Write-Step([string]$msg) {
    Write-Host ""
    Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray
}

function Write-OK([string]$msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-SKIP([string]$msg) { Write-Host "  [SKIP] $msg" -ForegroundColor Yellow }
function Write-FAIL([string]$msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }

function Set-SystemEnvVar([string]$name, [string]$value) {
    [System.Environment]::SetEnvironmentVariable($name, $value, "Machine")
    $env:($name) = $value   # also apply to current session
    Write-OK "Set system env: $name = $value"
}

function Add-ToSystemPath([string]$newPath) {
    $current = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($current -notlike "*$newPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$current;$newPath", "Machine")
        $env:Path += ";$newPath"
        Write-OK "Added to PATH: $newPath"
    } else {
        Write-SKIP "Already in PATH: $newPath"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Rust Toolchain
# ─────────────────────────────────────────────────────────────────────────────

function Install-RustToolchain {
    Write-Step "1/8 — Rust Toolchain"

    if (Get-Command rustc -ErrorAction SilentlyContinue) {
        $ver = (rustc --version 2>&1)
        Write-SKIP "Rust already installed: $ver"
        Write-Host "     If version is not 1.78.x, run: rustup update 1.78"
    } else {
        Write-Host "  Downloading rustup-init.exe..." -ForegroundColor Gray
        $installer = "$env:TEMP\rustup-init.exe"
        Invoke-WebRequest "https://win.rustup.rs/x86_64" -OutFile $installer
        # -y = no prompts, --default-toolchain = pin version, --profile = minimal + extras
        & $installer -y --default-toolchain "1.78" --profile default
        if ($LASTEXITCODE -ne 0) { Write-FAIL "rustup-init failed"; return }
        Write-OK "Rust 1.78 installed"
    }

    # Add rustfmt + clippy (needed for cargo fmt / cargo clippy in CI)
    & rustup component add rustfmt clippy rust-src 2>&1 | Out-Null
    Write-OK "Components: rustfmt, clippy, rust-src"

    # Set RUSTUP_HOME and CARGO_HOME as system vars so they survive reboots
    $cargoHome = "$env:USERPROFILE\.cargo"
    Set-SystemEnvVar "CARGO_HOME"  $cargoHome
    Set-SystemEnvVar "RUSTUP_HOME" "$env:USERPROFILE\.rustup"
    Add-ToSystemPath "$cargoHome\bin"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Python Virtual Environment
# ─────────────────────────────────────────────────────────────────────────────

function Install-PythonEnv {
    Write-Step "2/8 — Python 3.11 Virtual Environment"

    # Python itself must already be installed — we don't install it here
    # because the user may have 3.11 under a custom path.
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) {
        Write-FAIL "python not found in PATH. Install Python 3.11 from https://python.org then re-run."
        Write-Host "         IMPORTANT: tick 'Add Python to PATH' during install." -ForegroundColor Yellow
        return
    }
    $pyVer = (python --version 2>&1)
    if ($pyVer -notlike "*3.11*") {
        Write-FAIL "Found $pyVer but need 3.11.x. Install Python 3.11 and make it the default."
        return
    }
    Write-OK "Python found: $pyVer"

    $venvPath = "$Root\venv"
    if (Test-Path "$venvPath\Scripts\python.exe") {
        Write-SKIP "venv already exists at $venvPath"
    } else {
        Write-Host "  Creating venv at $venvPath..." -ForegroundColor Gray
        python -m venv "$venvPath"
        Write-OK "venv created"
    }

    # Upgrade pip inside venv
    & "$venvPath\Scripts\python.exe" -m pip install --upgrade pip --quiet
    Write-OK "pip upgraded inside venv"

    # Install all pinned packages
    Write-Host "  Installing Python packages (this takes a few minutes)..." -ForegroundColor Gray
    & "$venvPath\Scripts\pip.exe" install -r "$Root\services\inference\requirements.txt" --quiet
    if ($LASTEXITCODE -ne 0) { Write-FAIL "pip install failed — check requirements.txt"; return }
    Write-OK "All Python packages installed"

    # Install Playwright browsers (Chromium only — Part 9)
    & "$venvPath\Scripts\python.exe" -m playwright install chromium --quiet 2>&1 | Out-Null
    Write-OK "Playwright Chromium browser installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. CUDA Toolkit 12.1
# ─────────────────────────────────────────────────────────────────────────────

function Install-CUDAToolkit {
    Write-Step "3/8 — CUDA Toolkit 12.1"

    $cudaHome = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1"
    if (Test-Path "$cudaHome\bin\nvcc.exe") {
        Write-SKIP "CUDA 12.1 already installed at $cudaHome"
    } else {
        Write-Host "  CUDA 12.1 must be installed manually." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Steps:" -ForegroundColor Gray
        Write-Host "    1. Go to: https://developer.nvidia.com/cuda-12-1-0-download-archive" -ForegroundColor Gray
        Write-Host "    2. Select: Windows > x86_64 > 11 > exe (local)" -ForegroundColor Gray
        Write-Host "    3. Download and run the installer (custom install, only 'CUDA' component needed)" -ForegroundColor Gray
        Write-Host "    4. Re-run this script after installation" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Skipping CUDA setup — complete manually then re-run." -ForegroundColor Yellow
        return
    }

    Set-SystemEnvVar "CUDA_HOME" $cudaHome
    Add-ToSystemPath "$cudaHome\bin"
    Add-ToSystemPath "$cudaHome\libnvvp"
    Write-OK "CUDA_HOME set and bin added to PATH"
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. cuDNN — NOTE: NOT a manual install step for this project
# ─────────────────────────────────────────────────────────────────────────────
# torch==2.3.0+cu121 bundles cuDNN 8.9.x inside the wheel.
# No separate cuDNN download is needed. PyTorch handles it automatically.
# This function just confirms PyTorch can see the GPU — which proves cuDNN works.

function Verify-CuDNN {
    Write-Step "4/8 — cuDNN (bundled via PyTorch)"

    $venvPy = "$Root\venv\Scripts\python.exe"
    if (-not (Test-Path $venvPy)) {
        Write-SKIP "venv not ready yet — cuDNN will be verified after Install-PythonEnv"
        return
    }

    $cudnnVer = (& $venvPy -c "import torch; print(torch.backends.cudnn.version())" 2>&1)
    if ($cudnnVer -match "^\d+") {
        Write-OK "cuDNN available via PyTorch — version: $cudnnVer (no separate install needed)"
    } else {
        Write-Host "  cuDNN not yet visible — this will resolve once CUDA 12.1 is installed" -ForegroundColor Yellow
        Write-Host "  torch bundles cuDNN; no manual download from NVIDIA required." -ForegroundColor Gray
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. Go 1.22
# ─────────────────────────────────────────────────────────────────────────────

function Install-GoRuntime {
    Write-Step "5/8 — Go 1.22"

    if (Get-Command go -ErrorAction SilentlyContinue) {
        $ver = (go version 2>&1)
        Write-SKIP "Go already installed: $ver"
    } else {
        Write-Host "  Downloading Go 1.22 installer..." -ForegroundColor Gray
        $installer = "$env:TEMP\go1.22.windows-amd64.msi"
        Invoke-WebRequest "https://go.dev/dl/go1.22.5.windows-amd64.msi" -OutFile $installer
        Start-Process msiexec -ArgumentList "/i `"$installer`" /quiet /norestart" -Wait
        Write-OK "Go 1.22 installed to C:\Program Files\Go\"
    }

    $goPath = "$Root\go_modules"
    New-Item -ItemType Directory -Force -Path $goPath | Out-Null
    Set-SystemEnvVar "GOPATH" $goPath
    Add-ToSystemPath "C:\Program Files\Go\bin"
    Add-ToSystemPath "$goPath\bin"

    # Install protoc-gen-go and protoc-gen-go-grpc (needed by generate_proto.ps1)
    Write-Host "  Installing Go protoc plugins..." -ForegroundColor Gray
    & go install google.golang.org/protobuf/cmd/protoc-gen-go@latest 2>&1 | Out-Null
    & go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest 2>&1 | Out-Null
    Write-OK "protoc-gen-go and protoc-gen-go-grpc installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. Support Tools (Git, Node.js, Tesseract, ffmpeg, protoc)
# ─────────────────────────────────────────────────────────────────────────────

function Install-SupportTools {
    Write-Step "6/8 — Support Tools"

    # Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-SKIP "Git: $(git --version 2>&1)"
    } else {
        Write-Host "  Git not found. Download from https://git-scm.com/download/win and re-run." -ForegroundColor Yellow
    }

    # Node.js (for Mermaid CLI — Part 12 diagram generation)
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-SKIP "Node.js: $(node --version 2>&1)"
    } else {
        Write-Host "  Node.js not found." -ForegroundColor Yellow
        Write-Host "  Download Node 20 LTS from https://nodejs.org and re-run." -ForegroundColor Yellow
    }

    # Tesseract OCR (Part 12 screen reading)
    $tessExe = "C:\Program Files\Tesseract-OCR\tesseract.exe"
    if (Test-Path $tessExe) {
        Write-SKIP "Tesseract: already installed"
        Add-ToSystemPath "C:\Program Files\Tesseract-OCR"
    } else {
        Write-Host "  Tesseract not found." -ForegroundColor Yellow
        Write-Host "  Download from https://github.com/UB-Mannheim/tesseract/wiki" -ForegroundColor Yellow
        Write-Host "  Install to default path (C:\Program Files\Tesseract-OCR\)" -ForegroundColor Yellow
    }

    # ffmpeg (Part 11 — audio/video processing)
    $ffmpegDir = "$Root\tools\ffmpeg\bin"
    if (Test-Path "$ffmpegDir\ffmpeg.exe") {
        Write-SKIP "ffmpeg: already present at $ffmpegDir"
        Add-ToSystemPath $ffmpegDir
    } else {
        Write-Host "  ffmpeg not found." -ForegroundColor Yellow
        Write-Host "  Download from https://ffmpeg.org/download.html (Windows build, 7-zip)" -ForegroundColor Yellow
        Write-Host "  Extract and place ffmpeg.exe, ffprobe.exe into: $ffmpegDir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $ffmpegDir | Out-Null
    }

    # protoc (Protocol Buffer compiler — needed by generate_proto.ps1)
    if (Get-Command protoc -ErrorAction SilentlyContinue) {
        Write-SKIP "protoc: $(protoc --version 2>&1)"
    } else {
        Write-Host "  protoc not found." -ForegroundColor Yellow
        Write-Host "  Install via: winget install protobuf" -ForegroundColor Yellow
        Write-Host "  Or download from https://github.com/protocolbuffers/protobuf/releases" -ForegroundColor Yellow
    }

    # Mermaid CLI (installed via npm — Part 12)
    if (Get-Command mmdc -ErrorAction SilentlyContinue) {
        Write-SKIP "Mermaid CLI (mmdc): already installed"
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "  Installing Mermaid CLI via npm..." -ForegroundColor Gray
        npm install -g @mermaid-js/mermaid-cli --quiet 2>&1 | Out-Null
        Write-OK "Mermaid CLI installed"
    } else {
        Write-SKIP "npm not available — install Node.js first, then: npm install -g @mermaid-js/mermaid-cli"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 7. HuggingFace Cache Location
# ─────────────────────────────────────────────────────────────────────────────

function Set-HuggingFaceCache {
    Write-Step "7/8 — HuggingFace Cache"

    # Default HF cache goes to C:\Users\<user>\.cache\huggingface — fills C: drive fast.
    # Redirect everything to D: drive.
    $hfHome = "$Root\hf_cache"
    New-Item -ItemType Directory -Force -Path "$hfHome\hub" | Out-Null

    Set-SystemEnvVar "HF_HOME"             $hfHome
    Set-SystemEnvVar "TRANSFORMERS_CACHE"  "$hfHome\hub"
    Set-SystemEnvVar "HF_DATASETS_CACHE"   "$hfHome\datasets"
    Write-OK "HuggingFace cache redirected to $hfHome"
}

# ─────────────────────────────────────────────────────────────────────────────
# 8. Download Base Model Weights
# ─────────────────────────────────────────────────────────────────────────────

function Download-BaseModelWeights {
    Write-Step "8/8 — Phi-3.5-mini-instruct Base Weights"

    $gsTarget   = "$Root\models\great_sage\base_weights_original"
    $profTarget = "$Root\models\professor\base_weights_original"
    $markerFile = "$gsTarget\download_complete.txt"

    if (Test-Path $markerFile) {
        Write-SKIP "Base weights already downloaded (marker file exists)"
        return
    }

    New-Item -ItemType Directory -Force -Path $gsTarget   | Out-Null
    New-Item -ItemType Directory -Force -Path $profTarget | Out-Null

    $venvPy = "$Root\venv\Scripts\python.exe"
    if (-not (Test-Path $venvPy)) {
        Write-FAIL "venv not found — run Install-PythonEnv first"
        return
    }

    # huggingface-hub CLI is included via pip install huggingface-hub
    Write-Host "  Downloading microsoft/Phi-3.5-mini-instruct (~7.6 GB)..." -ForegroundColor Gray
    Write-Host "  This will take several minutes depending on your connection." -ForegroundColor Gray

    & $venvPy -c @"
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='microsoft/Phi-3.5-mini-instruct',
    local_dir=r'$gsTarget',
    ignore_patterns=['*.gguf']   # skip GGUF variants — we use SafeTensors
)
print('Download complete.')
"@

    if ($LASTEXITCODE -ne 0) {
        Write-FAIL "Download failed. Check your internet connection and try again."
        return
    }

    # Copy same weights for Professor (same base model, different fine-tune later)
    Write-Host "  Copying weights for Professor model slot..." -ForegroundColor Gray
    Copy-Item -Path "$gsTarget\*" -Destination $profTarget -Recurse -Force

    # Write marker file so this step is skipped on re-runs
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Set-Content -Path $markerFile -Value "Downloaded: $timestamp`nSource: microsoft/Phi-3.5-mini-instruct`nFormat: SafeTensors (FP16)"
    Write-OK "Base weights downloaded and marker written"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN — Run all steps in order
# ─────────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Great Sage × Tempest — Environment Setup  (§1)    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  Root: $Root"
Write-Host ""

Install-RustToolchain
Install-PythonEnv
Install-CUDAToolkit
Verify-CuDNN
Install-GoRuntime
Install-SupportTools
Set-HuggingFaceCache
Download-BaseModelWeights

Write-Host ""
Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Setup complete. Run verify_environment.ps1 to confirm." -ForegroundColor Green
Write-Host "  Note: Restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
