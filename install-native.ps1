# yappfy Native Installer for Windows
# Run: powershell -ExecutionPolicy Bypass -File install-native.ps1
# Downloads pre-built binary — nothing to install or compile.

$ErrorActionPreference = "Stop"
$YAPPFY_HOME = "$env:USERPROFILE\.yappfy"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    yappfy Native Installer for Windows" -ForegroundColor Cyan
Write-Host "    No Docker. No Cloud. Your Rules." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Check Python ─────────────────────────────────────────────────
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $py) {
    Write-Host "WARNING: Python not found. Element Web needs it." -ForegroundColor Yellow
    Write-Host "Install from https://python.org (check 'Add Python to PATH')" -ForegroundColor Yellow
    Write-Host ""
}

# ── Create directories ───────────────────────────────────────────
$dirs = @("dendrite", "element", "config", "logs")
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path "$YAPPFY_HOME\$d" | Out-Null
}

# ── Download pre-built Dendrite binary ───────────────────────────
Write-Host "Downloading Dendrite Matrix Server (40 MB)..." -ForegroundColor Cyan
$DENDRITE_URL = "https://github.com/IthreeX/yappfy/releases/download/v0.1.0/dendrite-windows-amd64.exe"
$DENDRITE_PATH = "$YAPPFY_HOME\dendrite\dendrite.exe"

Invoke-WebRequest -Uri $DENDRITE_URL -OutFile $DENDRITE_PATH
Write-Host "[OK] Dendrite installed" -ForegroundColor Green

# ── Generate config ──────────────────────────────────────────────
Write-Host "Generating config..." -ForegroundColor Cyan
Push-Location $YAPPFY_HOME
& $DENDRITE_PATH --config config\dendrite.yaml --generate-config 2>$null

$config = Get-Content config\dendrite.yaml -Raw
$config = $config -replace 'connection_string:.*', 'connection_string: file:yappfy.db?_journal_mode=WAL'
$config = $config -replace 'server_name:.*', 'server_name: localhost'
Set-Content config\dendrite.yaml $config
Pop-Location
Write-Host "[OK] Config ready" -ForegroundColor Green

# ── Install Element Web ──────────────────────────────────────────
Write-Host "Downloading Element Web..." -ForegroundColor Cyan
$ELEMENT_VERSION = "1.11.93"
$ELEMENT_URL = "https://github.com/element-hq/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz"
$tmp = "$env:TEMP\element-yappfy.tar.gz"

Invoke-WebRequest -Uri $ELEMENT_URL -OutFile $tmp
tar xzf $tmp -C "$YAPPFY_HOME\element"
Remove-Item $tmp -Force

$elementConfig = @"
{
    "default_server_config": {
        "m.homeserver": {"base_url": "http://localhost:8008"}
    },
    "brand": "yappfy",
    "disable_guests": true,
    "showLabsSettings": false,
    "default_federate": false
}
"@
Set-Content "$YAPPFY_HOME\element\config.json" $elementConfig
Write-Host "[OK] Element Web $ELEMENT_VERSION" -ForegroundColor Green

# ── Create start.bat ─────────────────────────────────────────────
$batPath = "$YAPPFY_HOME\start.bat"
@"
@echo off
title yappfy
echo.
echo     yappfy is starting...
echo     Matrix Server: http://localhost:8008
echo     Element Web:   http://localhost:8009
echo.
echo     Close this window to stop all services.
echo     ====================================
echo.

start "" "dendrite\dendrite.exe" --config "config\dendrite.yaml" --tls-cert NUL --tls-key NUL

timeout /t 3 /nobreak >nul

cd element
start "" python -m http.server 8009 --bind 127.0.0.1
cd ..

echo.
echo     yappfy is running! Open http://localhost:8009
echo     Press any key to stop...
pause >nul

taskkill /f /im dendrite.exe 2>nul
taskkill /f /im python.exe 2>nul
echo Done.
"@ | Set-Content $batPath
Write-Host "[OK] start.bat created" -ForegroundColor Green

# ── Summary ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "    yappfy Native Install Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Start:  $YAPPFY_HOME\start.bat"
Write-Host "  Open:   http://localhost:8009"
Write-Host ""
pause
