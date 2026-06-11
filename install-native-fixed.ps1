# yappfy FIX Installer — one click, everything works
$ErrorActionPreference = "Stop"
$H = "$env:USERPROFILE\.yappfy"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "    yappfy FIXED — One-Click Installer" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Python not found. Install from https://python.org" -ForegroundColor Red
    Write-Host "(Check 'Add Python to PATH' during install!)" -ForegroundColor Red
    pause
    exit 1
}

# Create directories
foreach ($d in @("dendrite","element","config")) { New-Item -ItemType Directory -Force -Path "$H\$d" | Out-Null }

# ---- 1. Download Dendrite ----
Write-Host "[1/4] Downloading Dendrite (40 MB)..." -ForegroundColor Cyan
if (-not (Test-Path "$H\dendrite\dendrite.exe")) {
    Invoke-WebRequest -Uri "https://github.com/IthreeX/yappfy/releases/download/v0.1.0/dendrite-windows-amd64.exe" -OutFile "$H\dendrite\dendrite.exe"
}
Write-Host "  [OK] Dendrite" -ForegroundColor Green

# ---- 2. Generate signing key ----
Write-Host "[2/4] Generating signing key..." -ForegroundColor Cyan
$keyFile = "$H\config\signing.key"
if (-not (Test-Path $keyFile)) {
    # Use forward slashes for Python
    $keyFilePy = $keyFile -replace '\\','/'
    python -c "import os,base64; open('$keyFilePy','w').write('ed25519 '+base64.b64encode(os.urandom(32)).decode())"
}
Write-Host "  [OK] Signing key" -ForegroundColor Green

# ---- 3. Create dendrite.yaml (FIXED: private_key = FILE PATH) ----
Write-Host "[3/4] Creating config..." -ForegroundColor Cyan
# Use forward slashes in YAML so Dendrite is happy on Windows
$cfgDir = $H -replace '\\','/'
$keyPathInYaml = "$cfgDir/config/signing.key"

$config = @"
version: 2
global:
  server_name: localhost
  private_key: $keyPathInYaml
  disable_federation: true
database:
  connection_string: file:$cfgDir/yappfy.db?_journal_mode=WAL
  max_open_conns: 10
app_service_api:
  listen: http://127.0.0.1:7777
  internal_api:
    connect: http://127.0.0.1:7777
client_api:
  listen: http://127.0.0.1:7771
  internal_api:
    connect: http://127.0.0.1:7771
  registration_disabled: false
federation_api:
  listen: http://127.0.0.1:7772
  internal_api:
    connect: http://127.0.0.1:7772
key_server:
  internal_api:
    connect: http://127.0.0.1:7779
media_api:
  listen: http://127.0.0.1:7774
  internal_api:
    connect: http://127.0.0.1:7774
  database:
    connection_string: file:$cfgDir/yappfy-media.db?_journal_mode=WAL
room_server:
  internal_api:
    connect: http://127.0.0.1:7770
  database:
    connection_string: file:$cfgDir/yappfy-rooms.db?_journal_mode=WAL
sync_api:
  listen: http://127.0.0.1:7773
  internal_api:
    connect: http://127.0.0.1:7773
  database:
    connection_string: file:$cfgDir/yappfy-sync.db?_journal_mode=WAL
user_api:
  internal_api:
    connect: http://127.0.0.1:7781
  account_database:
    connection_string: file:$cfgDir/yappfy-accounts.db?_journal_mode=WAL
  device_database:
    connection_string: file:$cfgDir/yappfy-devices.db?_journal_mode=WAL
logging:
  - type: std
    level: warn
cache:
  max_size_estimated: 100m
  max_age: 1h
"@
Set-Content "$H\config\dendrite.yaml" $config
Write-Host "  [OK] Config" -ForegroundColor Green

# ---- 4. Download & setup Element Web ----
Write-Host "[4/4] Downloading Element Web..." -ForegroundColor Cyan
$elementDir = "$H\element\element-v1.11.93"
if (-not (Test-Path $elementDir)) {
    $tmp = "$env:TEMP\element-yappfy.tar.gz"
    Invoke-WebRequest -Uri "https://github.com/element-hq/element-web/releases/download/v1.11.93/element-v1.11.93.tar.gz" -OutFile $tmp
    tar xzf $tmp -C "$H\element"
    Remove-Item $tmp -Force
}
# Create config.json INSIDE the element directory
Set-Content "$elementDir\config.json" '{"default_server_config":{"m.homeserver":{"base_url":"http://localhost:8008"}},"brand":"yappfy","disable_guests":true,"showLabsSettings":false,"default_federate":false}'
Write-Host "  [OK] Element Web" -ForegroundColor Green

# ---- 5. Create start.bat (FIXED: cd /d %~dp0) ----
@"
@echo off
cd /d %~dp0
title yappfy
echo yappfy — http://localhost:8009/element-v1.11.93/

REM Start Dendrite
start "yappfy-Dendrite" dendrite\dendrite.exe --config config\dendrite.yaml --http-bind-address "127.0.0.1:8008" --tls-cert NUL --tls-key NUL

REM Wait for Dendrite to start
echo Waiting for Dendrite...
timeout /t 4 /nobreak >nul

REM Start Element Web
cd element\element-v1.11.93
start "yappfy-Element" python -m http.server 8009 --bind 127.0.0.1
cd ..\..

echo.
echo ============================================
echo     yappfy is running!
echo     Open: http://localhost:8009/element-v1.11.93/
echo ============================================
echo.
echo Close this window to stop all servers.
pause >nul

REM Only kill OUR processes
taskkill /fi "WINDOWTITLE eq yappfy-Dendrite" /f 2>nul
taskkill /fi "WINDOWTITLE eq yappfy-Element" /f 2>nul
"@ | Set-Content "$H\start.bat"
Write-Host "  [OK] start.bat" -ForegroundColor Green

# ---- DONE ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "    INSTALL COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Starten:  %USERPROFILE%\.yappfy\start.bat" -ForegroundColor Cyan
Write-Host "  Browser:  http://localhost:8009/element-v1.11.93/" -ForegroundColor Cyan
Write-Host ""
pause
