# download_models.ps1 — Download pre-trained model weights for Friday.
#
# Run from the friday/ root directory:
#   .\scripts\download_models.ps1

$ErrorActionPreference = "Stop"
$ModelsDir = Join-Path $PSScriptRoot "..\models"

Write-Host "Friday Model Downloader" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# TODO: Add download URLs for each model.
# Models to download:
#   1. llama-3.2-3b-instruct-q4_k_m.gguf  (~2 GB)
#   2. bge-small-en-v1.5/                  (~80 MB)
#   3. whisper-base.en.bin                  (~150 MB)
#   4. piper/en_US-libritts.onnx           (~60 MB)
#   5. wakeword_friday.onnx                (~1 MB)

Write-Host "Model directory: $ModelsDir"
Write-Host ""
Write-Host "This script is a placeholder. Add HuggingFace download URLs" -ForegroundColor Yellow
Write-Host "for each model before running." -ForegroundColor Yellow
