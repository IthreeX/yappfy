# yappfy Native Installer for Windows — No Docker, No Go, No compile.
# Run: powershell -ExecutionPolicy Bypass -File install-native.ps1

$ErrorActionPreference = "Stop"
$H = "$env:USERPROFILE\.yappfy"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    yappfy Native Installer for Windows" -ForegroundColor Cyan
Write-Host "    No Docker. No Cloud. Your Rules." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
        Write-Host "Python needed: https://python.org (check 'Add Python to PATH')" -ForegroundColor Yellow
    }
}

foreach ($d in @("dendrite","element","config")) { New-Item -ItemType Directory -Force -Path "$H\$d" | Out-Null }

# Download Dendrite
Write-Host "Downloading Dendrite (40 MB)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/IthreeX/yappfy/releases/download/v0.1.0/dendrite-windows-amd64.exe" -OutFile "$H\dendrite\dendrite.exe"
Write-Host "[OK] Dendrite" -ForegroundColor Green

# Generate key
Write-Host "Generating config..." -ForegroundColor Cyan
python -c "import os,base64; open('$H\config\signing.key','w').write('ed25519 '+base64.b64encode(os.urandom(32)).decode())"
$key = (Get-Content "$H\config\signing.key" -Raw).Trim()
$dd = $H -replace '\\','/'

$config = @"
version: 2
global:
  server_name: localhost
  private_key: $key
  disable_federation: true
database:
  connection_string: file:$dd/yappfy.db?_journal_mode=WAL
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
    connection_string: file:$dd/yappfy-media.db?_journal_mode=WAL
room_server:
  internal_api:
    connect: http://127.0.0.1:7770
  database:
    connection_string: file:$dd/yappfy-rooms.db?_journal_mode=WAL
sync_api:
  listen: http://127.0.0.1:7773
  internal_api:
    connect: http://127.0.0.1:7773
  database:
    connection_string: file:$dd/yappfy-sync.db?_journal_mode=WAL
user_api:
  internal_api:
    connect: http://127.0.0.1:7781
  account_database:
    connection_string: file:$dd/yappfy-accounts.db?_journal_mode=WAL
  device_database:
    connection_string: file:$dd/yappfy-devices.db?_journal_mode=WAL
logging:
  - type: std
    level: warn
cache:
  max_size_estimated: 100m
  max_age: 1h
"@
Set-Content "$H\config\dendrite.yaml" $config
Write-Host "[OK] Config" -ForegroundColor Green

# Element Web
Write-Host "Downloading Element Web..." -ForegroundColor Cyan
$tmp = "$env:TEMP\element-yappfy.tar.gz"
Invoke-WebRequest -Uri "https://github.com/element-hq/element-web/releases/download/v1.11.93/element-v1.11.93.tar.gz" -OutFile $tmp
tar xzf $tmp -C "$H\element"
Remove-Item $tmp -Force
Set-Content "$H\element\config.json" '{"default_server_config":{"m.homeserver":{"base_url":"http://localhost:8008"}},"brand":"yappfy","disable_guests":true,"showLabsSettings":false,"default_federate":false}'
Write-Host "[OK] Element Web" -ForegroundColor Green

# start.bat
@"
@echo off
title yappfy
echo yappfy — http://localhost:8009
start "" "dendrite\dendrite.exe" --config "config\dendrite.yaml" --http-bind-address ":8008" --tls-cert NUL --tls-key NUL
timeout /t 3 /nobreak >nul
cd element
start "" python -m http.server 8009 --bind 127.0.0.1
cd ..
echo Running. Close this window to stop.
pause >nul
taskkill /f /im dendrite.exe 2>nul
taskkill /f /im python.exe 2>nul
"@ | Set-Content "$H\start.bat"
Write-Host "[OK] start.bat" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "    yappfy Install Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Start:  $H\start.bat"
Write-Host "  Open:   http://localhost:8009"
Write-Host ""
pause
