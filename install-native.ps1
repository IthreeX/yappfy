# yappfy Native Installer for Windows
# Run: powershell -ExecutionPolicy Bypass -File install-native.ps1
# Requires: Go installed from https://go.dev/dl/

$ErrorActionPreference = "Stop"
$YAPPFY_HOME = "$env:USERPROFILE\.yappfy"

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       yappfy Native Installer           ║" -ForegroundColor Cyan
Write-Host "║   No Docker. No Cloud. Your Rules.      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ── Check Go ─────────────────────────────────────────────────────
$go = Get-Command go -ErrorAction SilentlyContinue
if (-not $go) {
    Write-Host "Go is required. Download from https://go.dev/dl/" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Go found" -ForegroundColor Green

# ── Create directories ───────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$YAPPFY_HOME/dendrite" | Out-Null
New-Item -ItemType Directory -Force -Path "$YAPPFY_HOME/element" | Out-Null
New-Item -ItemType Directory -Force -Path "$YAPPFY_HOME/config" | Out-Null
New-Item -ItemType Directory -Force -Path "$YAPPFY_HOME/logs" | Out-Null

# ── Install Dendrite ─────────────────────────────────────────────
Write-Host "`n📦 Installing Dendrite Matrix Server..." -ForegroundColor Cyan
$DENDRITE_VERSION = "0.14.1"
$DENDRITE_URL = "https://github.com/matrix-org/dendrite/releases/download/v$DENDRITE_VERSION/dendrite-windows-amd64.exe"

Write-Host "  Downloading Dendrite $DENDRITE_VERSION..."
Invoke-WebRequest -Uri $DENDRITE_URL -OutFile "$YAPPFY_HOME\dendrite\dendrite.exe"

Write-Host "✓ Dendrite $DENDRITE_VERSION installed" -ForegroundColor Green

# ── Generate Dendrite config ─────────────────────────────────────
Set-Location $YAPPFY_HOME
& "$YAPPFY_HOME\dendrite\dendrite.exe" --config config/dendrite.yaml --generate-config 2>$null

# Replace PostgreSQL with SQLite
$config = Get-Content config/dendrite.yaml -Raw
$config = $config -replace 'connection_string:.*', 'connection_string: file:yappfy.db?_journal_mode=WAL'
$config = $config -replace 'server_name:.*', 'server_name: localhost'
Set-Content config/dendrite.yaml $config

# ── Install Element Web ──────────────────────────────────────────
Write-Host "`n📦 Installing Element Web Client..." -ForegroundColor Cyan
$ELEMENT_VERSION = "1.11.93"
$ELEMENT_URL = "https://github.com/element-hq/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz"

Write-Host "  Downloading Element Web $ELEMENT_VERSION..."

# Download and extract
$tmp = "$env:TEMP\element.tar.gz"
Invoke-WebRequest -Uri $ELEMENT_URL -OutFile $tmp
tar xzf $tmp -C "$YAPPFY_HOME\element"
Remove-Item $tmp

# Create config
$elementConfig = @'
{
    "default_server_config": {
        "m.homeserver": {"base_url": "http://localhost:8008"}
    },
    "brand": "yappfy",
    "disable_guests": true,
    "showLabsSettings": false,
    "default_federate": false
}
'@
Set-Content "$YAPPFY_HOME\element\config.json" $elementConfig

Write-Host "✓ Element Web $ELEMENT_VERSION installed" -ForegroundColor Green

# ── Create start script ──────────────────────────────────────────
$startScript = @'
@echo off
title yappfy
echo 🚀 Starting yappfy...
echo.
echo   Matrix Server: http://localhost:8008
echo   Element Web:   http://localhost:8009
echo.
echo Close this window to stop all services.
echo ─────────────────────────────────────

start "" "%~dp0dendrite\dendrite.exe" --config "config\dendrite.yaml" --tls-cert NUL --tls-key NUL

timeout /t 3 /nobreak >nul

cd element
start "" python -m http.server 8009 --bind 127.0.0.1
cd ..

echo.
echo ✅ yappfy is running! Open http://localhost:8009
echo Press any key to stop...
pause >nul

taskkill /f /im dendrite.exe 2>nul
taskkill /f /im python.exe 2>nul
echo Done.
'@
Set-Content "$YAPPFY_HOME\start.bat" $startScript

# ── Summary ──────────────────────────────────────────────────────
Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ yappfy Native Install Complete    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "  Start:  $YAPPFY_HOME\start.bat"
Write-Host "  Config: $YAPPFY_HOME\config\"
Write-Host ""
Write-Host "  Double-click start.bat or run in terminal!" -ForegroundColor Yellow
Write-Host "  Open http://localhost:8009" -ForegroundColor Yellow
