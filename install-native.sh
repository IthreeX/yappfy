#!/usr/bin/env bash
set -e

# ── yappfy Native Installer ──────────────────────────────────────
# Installs everything without Docker. Runs on macOS and Linux.
# Windows: use install-native.ps1
# ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
YAPPFY_HOME="${YAPPFY_HOME:-$HOME/.yappfy}"
OS="$(uname -s)"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║       yappfy Native Installer           ║"
echo "║   No Docker. No Cloud. Your Rules.      ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Dependency check ─────────────────────────────────────────────
command -v go >/dev/null 2>&1 || {
    echo -e "${RED}Go is required. Install from https://go.dev/dl/${NC}"
    echo "  macOS: brew install go"
    echo "  Linux: snap install go --classic"
    exit 1
}
echo -e "${GREEN}✓ Go $(go version | awk '{print $3}')${NC}"

# ── Create directories ───────────────────────────────────────────
mkdir -p "$YAPPFY_HOME"/{dendrite,bridges,element,logs,config}

# ── Install Dendrite (Matrix server, Go binary, SQLite) ──────────
echo -e "\n${CYAN}📦 Installing Dendrite Matrix Server...${NC}"
DENDRITE_VERSION="0.14.1"
DENDRITE_URL=""
case "$OS" in
    Darwin)
        ARCH=$(uname -m)
        [ "$ARCH" = "arm64" ] && DENDRITE_ARCH="arm64" || DENDRITE_ARCH="amd64"
        DENDRITE_URL="https://github.com/matrix-org/dendrite/releases/download/v${DENDRITE_VERSION}/dendrite-darwin-${DENDRITE_ARCH}"
        ;;
    Linux)
        DENDRITE_URL="https://github.com/matrix-org/dendrite/releases/download/v${DENDRITE_VERSION}/dendrite-linux-amd64"
        ;;
    *)
        echo "Building from source..."
        go install github.com/matrix-org/dendrite/cmd/dendrite@v${DENDRITE_VERSION}
        cp "$(go env GOPATH)/bin/dendrite" "$YAPPFY_HOME/dendrite/dendrite"
        ;;
esac

if [ -n "$DENDRITE_URL" ]; then
    curl -fsSL "$DENDRITE_URL" -o "$YAPPFY_HOME/dendrite/dendrite"
    chmod +x "$YAPPFY_HOME/dendrite/dendrite"
fi

# Generate default config with SQLite
cd "$YAPPFY_HOME"
./dendrite/dendrite --config config/dendrite.yaml --generate-config >/dev/null 2>&1 || true

# Replace PostgreSQL with SQLite in config
sed -i.bak 's/connection_string:.*/connection_string: file:yappfy.db?_journal_mode=WAL/' config/dendrite.yaml 2>/dev/null || true
sed -i.bak 's/server_name:.*/server_name: localhost/' config/dendrite.yaml 2>/dev/null || true
rm -f config/dendrite.yaml.bak

echo -e "${GREEN}✓ Dendrite ${DENDRITE_VERSION} installed${NC}"

# ── Install Element Web ──────────────────────────────────────────
echo -e "\n${CYAN}📦 Installing Element Web Client...${NC}"
ELEMENT_VERSION="1.11.93"
curl -fsSL "https://github.com/element-hq/element-web/releases/download/v${ELEMENT_VERSION}/element-v${ELEMENT_VERSION}.tar.gz" \
    | tar xz -C "$YAPPFY_HOME/element/"

cat > "$YAPPFY_HOME/element/config.json" << 'EOF'
{
    "default_server_config": {
        "m.homeserver": {"base_url": "http://localhost:8008"}
    },
    "brand": "yappfy",
    "disable_guests": true,
    "disable_login_language_selector": false,
    "showLabsSettings": false,
    "default_federate": false
}
EOF
echo -e "${GREEN}✓ Element Web ${ELEMENT_VERSION} installed${NC}"

# ── Create start script ──────────────────────────────────────────
cat > "$YAPPFY_HOME/start.sh" << 'STARTSCRIPT'
#!/usr/bin/env bash
YAPPFY_HOME="${YAPPFY_HOME:-$HOME/.yappfy}"
cd "$YAPPFY_HOME"

echo "🚀 Starting yappfy..."
echo ""
echo "  Matrix Server: http://localhost:8008"
echo "  Element Web:   http://localhost:8009"
echo ""
echo "Press Ctrl+C to stop all services."

# Start Dendrite
./dendrite/dendrite --config config/dendrite.yaml --tls-cert /dev/null --tls-key /dev/null &
DENDRITE_PID=$!

sleep 3

# Serve Element Web
if command -v python3 >/dev/null 2>&1; then
    cd element && python3 -m http.server 8009 --bind 127.0.0.1 &
    ELEMENT_PID=$!
    cd "$YAPPFY_HOME"
fi

echo ""
echo -e "\033[0;32m✅ yappfy is running!\033[0m"
echo "   Open: http://localhost:8009"

trap "kill $DENDRITE_PID $ELEMENT_PID 2>/dev/null; exit" INT TERM
wait
STARTSCRIPT
chmod +x "$YAPPFY_HOME/start.sh"

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ yappfy Native Install Complete    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Start:  $YAPPFY_HOME/start.sh"
echo "  Config: $YAPPFY_HOME/config/"
echo "  Logs:   $YAPPFY_HOME/logs/"
echo ""
echo "  Open http://localhost:8009 and log in!"
