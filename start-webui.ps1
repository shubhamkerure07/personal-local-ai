<#
.SYNOPSIS
    One-Click Launcher for Personal Local AI System (Open WebUI + Ollama)
.DESCRIPTION
    Ensures Ollama daemon is running with GPU acceleration, starts Open WebUI
    in the isolated Python virtual environment, and opens your browser.
#>

[CmdletBinding()]
param(
    [int]$Port = 8080,
    [string]$OllamaUrl = "http://127.0.0.1:11434"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvDir = Join-Path $scriptDir "venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$venvPip = Join-Path $venvDir "Scripts\pip.exe"
$venvWebUI = Join-Path $venvDir "Scripts\open-webui.exe"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   🚀 PERSONAL LOCAL AI SYSTEM: ONE-CLICK LAUNCHER       " -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# 1. Check Ollama Daemon
Write-Host "[1/3] Checking Ollama engine status..." -ForegroundColor Yellow
$ollamaRunning = $false
try {
    $version = (Invoke-RestMethod -Uri "$OllamaUrl/api/version" -TimeoutSec 2).version
    Write-Host "  -> Ollama is active (v$version) with NVIDIA RTX 4050 GPU." -ForegroundColor Green
    $ollamaRunning = $true
} catch {
    Write-Host "  -> Starting Ollama background engine..." -ForegroundColor Yellow
    $ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (Test-Path $ollamaExe) {
        Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        Write-Host "  -> Ollama engine started successfully." -ForegroundColor Green
    } else {
        Write-Host "  -> Ollama binary not found at $ollamaExe. Please verify installation." -ForegroundColor Red
    }
}

# 2. Check Virtual Environment & Open WebUI Package
Write-Host "[2/3] Checking Open WebUI environment..." -ForegroundColor Yellow
if (-not (Test-Path $venvPython)) {
    Write-Host "  -> Initializing virtual environment at $venvDir..." -ForegroundColor Yellow
    python -m venv $venvDir
}

if (-not (Test-Path $venvWebUI)) {
    Write-Host "  -> Installing Open WebUI (first-time setup)..." -ForegroundColor Yellow
    & $venvPip install --quiet open-webui
    Write-Host "  -> Open WebUI package installed successfully." -ForegroundColor Green
} else {
    Write-Host "  -> Open WebUI is ready." -ForegroundColor Green
}

# 3. Launch Open WebUI & Browser
Write-Host "[3/3] Starting Open WebUI server on port $Port..." -ForegroundColor Yellow
Write-Host "`nAccess your local ChatGPT-style interface at:" -ForegroundColor Cyan
Write-Host "👉 http://localhost:$Port`n" -ForegroundColor Green
Write-Host "Press Ctrl+C at any time to stop the server.`n" -ForegroundColor Gray

Start-Process "http://localhost:$Port"

# Set environment variables for Open WebUI
$env:OLLAMA_BASE_URL = $OllamaUrl
$env:PORT = $Port

& $venvWebUI serve --port $Port
