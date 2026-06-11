#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════╗
# ║  yappfy Setup — 3-Minuten-Installer              ║
# ║  Viber + Telegram + WhatsApp in einer Oberfläche ║
# ╚══════════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    echo -e "${BLUE}"
    echo "  ╔══════════════════════════════════╗"
    echo "  ║  ██╗   ██╗ █████╗ ██████╗ ██████╗ ║"
    echo "  ║  ╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗║"
    echo "  ║   ╚████╔╝ ███████║██████╔╝██████╔╝║"
    echo "  ║    ╚██╔╝  ██╔══██║██╔═══╝ ██╔═══╝ ║"
    echo "  ║     ██║   ██║  ██║██║     ██║     ║"
    echo "  ║     ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝     ║"
    echo "  ║            ███████╗██╗   ██╗       ║"
    echo "  ║            ██╔════╝╚██╗ ██╔╝       ║"
    echo "  ║            █████╗   ╚████╔╝        ║"
    echo "  ║            ██╔══╝    ╚██╔╝         ║"
    echo "  ║            ██║        ██║          ║"
    echo "  ║            ╚═╝        ╚═╝          ║"
    echo "  ╚══════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BOLD}Deine Messenger. Deine Regeln.${NC}"
    echo ""
}

check_deps() {
    echo -e "${YELLOW}🔍 Prüfe Voraussetzungen...${NC}"
    
    for cmd in docker curl python3; do
        if ! command -v $cmd &>/dev/null; then
            echo -e "  ${RED}✗${NC} $cmd fehlt — bitte installieren"
            exit 1
        fi
        echo -e "  ${GREEN}✓${NC} $cmd"
    done
    
    if ! docker compose version &>/dev/null; then
        echo -e "  ${RED}✗${NC} Docker Compose fehlt"
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} docker compose"
    echo ""
}

ask_domain() {
    echo -e "${BOLD}🌐 Domain${NC}"
    echo -e "  Deine yappfy-Instanz braucht eine Domain (z.B. yappfy.io)"
    read -p "  Domain [localhost]: " DOMAIN
    DOMAIN=${DOMAIN:-localhost}
    
    if [ "$DOMAIN" = "localhost" ]; then
        echo -e "  ${YELLOW}⚠ Lokaler Test-Modus (nur http://localhost)${NC}"
    fi
    echo ""
}

ask_bridges() {
    echo -e "${BOLD}🔌 Welche Messenger willst du verbinden?${NC}"
    echo ""
    
    ENABLE_VIBER="no"
    ENABLE_TELEGRAM="no"
    ENABLE_WHATSAPP="no"
    
    read -p "  Viber aktivieren? (y/N): " ans && [ "${ans,,}" = "y" ] && ENABLE_VIBER="yes"
    read -p "  Telegram aktivieren? (y/N): " ans && [ "${ans,,}" = "y" ] && ENABLE_TELEGRAM="yes"
    read -p "  WhatsApp aktivieren? (y/N): " ans && [ "${ans,,}" = "y" ] && ENABLE_WHATSAPP="yes"
    
    echo ""
    echo -e "  ${GREEN}✓${NC} Viber: $ENABLE_VIBER"
    echo -e "  ${GREEN}✓${NC} Telegram: $ENABLE_TELEGRAM"
    echo -e "  ${GREEN}✓${NC} WhatsApp: $ENABLE_WHATSAPP"
    echo ""
}

generate_configs() {
    echo -e "${YELLOW}⚙️  Generiere Konfigurationen...${NC}"
    
    python3 scripts/generate-config.py \
        --domain "$DOMAIN" \
        ${ENABLE_VIBER:+--viber} \
        ${ENABLE_TELEGRAM:+--telegram} \
        ${ENABLE_WHATSAPP:+--whatsapp}
    
    echo -e "  ${GREEN}✓${NC} Configs erstellt"
    echo ""
}

start_services() {
    echo -e "${YELLOW}🚀 Starte yappfy...${NC}"
    echo ""
    
    export DOMAIN=$DOMAIN
    docker compose up -d
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ yappfy läuft!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$DOMAIN" = "localhost" ]; then
        echo -e "  🌐 Client:    ${BOLD}http://localhost:8080${NC}"
    else
        echo -e "  🌐 Client:    ${BOLD}https://$DOMAIN${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}📋 Nächste Schritte:${NC}"
    [ "$ENABLE_TELEGRAM" = "yes" ] && echo "  • Telegram-Bridge einrichten: docker compose exec mautrix-telegram /usr/bin/mautrix-telegram"
    [ "$ENABLE_WHATSAPP" = "yes" ] && echo "  • WhatsApp-Bridge: QR-Code scannen → docker compose logs mautrix-whatsapp"
    [ "$ENABLE_VIBER" = "yes" ] && echo "  • Viber-Bridge: Bot Token in config/mautrix-viber/config.yaml eintragen"
    echo ""
}

# ─── MAIN ───
banner
check_deps
ask_domain
ask_bridges
generate_configs
start_services
