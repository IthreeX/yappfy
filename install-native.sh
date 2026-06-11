#!/usr/bin/env bash
set -e

# ── yappfy Native Installer ──────────────────────────────────────
# No Docker. No Cloud. No compile. Your Rules.
# ──────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
YAPPFY_HOME="${YAPPFY_HOME:-$HOME/.yappfy}"
OS="$(uname -s)"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║       yappfy Native Installer           ║"
echo "║   No Docker. No Cloud. Your Rules.      ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

mkdir -p "$YAPPFY_HOME"/{dendrite,element,config}

# ── Download Dendrite ────────────────────────────────────────────
echo -e "\n${CYAN}📦 Downloading Dendrite Matrix Server...${NC}"
case "$OS" in
    Darwin) FILE="dendrite-darwin-amd64" ;;
    Linux)  FILE="dendrite-linux-amd64" ;;
esac
curl -fsSL "https://github.com/IthreeX/yappfy/releases/download/v0.1.0/${FILE}" -o "$YAPPFY_HOME/dendrite/dendrite"
chmod +x "$YAPPFY_HOME/dendrite/dendrite"
echo -e "${GREEN}✓ Dendrite installed${NC}"

# ── Generate signing key ─────────────────────────────────────────
python3 -c "
import os, base64
key = base64.b64encode(os.urandom(32)).decode()
with open('$YAPPFY_HOME/config/signing.key', 'w') as f:
    f.write('ed25519 ' + key)
"

# ── Write config ─────────────────────────────────────────────────
KEY=$(cat "$YAPPFY_HOME/config/signing.key")
cat > "$YAPPFY_HOME/config/dendrite.yaml" << CONFIGEND
version: 2
global:
  server_name: localhost
  private_key: ${KEY}
  disable_federation: true
database:
  connection_string: file:${YAPPFY_HOME}/yappfy.db?_journal_mode=WAL
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
    connection_string: file:${YAPPFY_HOME}/yappfy-media.db?_journal_mode=WAL
room_server:
  internal_api:
    connect: http://127.0.0.1:7770
  database:
    connection_string: file:${YAPPFY_HOME}/yappfy-rooms.db?_journal_mode=WAL
sync_api:
  listen: http://127.0.0.1:7773
  internal_api:
    connect: http://127.0.0.1:7773
  database:
    connection_string: file:${YAPPFY_HOME}/yappfy-sync.db?_journal_mode=WAL
user_api:
  internal_api:
    connect: http://127.0.0.1:7781
  account_database:
    connection_string: file:${YAPPFY_HOME}/yappfy-accounts.db?_journal_mode=WAL
  device_database:
    connection_string: file:${YAPPFY_HOME}/yappfy-devices.db?_journal_mode=WAL
logging:
  - type: std
    level: warn
cache:
  max_size_estimated: 100m
  max_age: 1h
CONFIGEND

echo -e "${GREEN}✓ Config ready${NC}"

# ── Install Element Web ──────────────────────────────────────────
echo -e "\n${CYAN}📦 Downloading Element Web...${NC}"
curl -fsSL "https://github.com/element-hq/element-web/releases/download/v1.11.93/element-v1.11.93.tar.gz" \
    | tar xz -C "$YAPPFY_HOME/element/"
cat > "$YAPPFY_HOME/element/config.json" << 'EOF'
{"default_server_config":{"m.homeserver":{"base_url":"http://localhost:8008"}},"brand":"yappfy","disable_guests":true,"showLabsSettings":false,"default_federate":false}
EOF
echo -e "${GREEN}✓ Element Web installed${NC}"

# ── Create start script ──────────────────────────────────────────
cat > "$YAPPFY_HOME/start.sh" << 'START'
#!/usr/bin/env bash
H="${YAPPFY_HOME:-$HOME/.yappfy}"
cd "$H"
echo "🚀 yappfy — http://localhost:8009"
"./dendrite/dendrite" --config config/dendrite.yaml --http-bind-address ":8008" --tls-cert /dev/null --tls-key /dev/null &
sleep 3
cd element && python3 -m http.server 8009 --bind 127.0.0.1 &
cd "$H"
echo "✅ Running. Ctrl+C to stop."
trap "kill 0" INT TERM
wait
START
chmod +x "$YAPPFY_HOME/start.sh"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ yappfy Install Complete!         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo "  $YAPPFY_HOME/start.sh  →  http://localhost:8009"
