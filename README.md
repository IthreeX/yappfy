# yappfy — Deine Messenger. Deine Regeln.

**Viber + Telegram + WhatsApp in einer Oberfläche. Self-hosted. Open Source. Kostenlos.**

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen)](https://docs.docker.com/)

---

## Was ist yappfy?

yappfy vereint deine Messenger in **einem Client**. Kein Cloud-Dienst, keine Datenweitergabe — alles läuft auf **deinem Server**.

```
┌────────────────────────────────────────┐
│              Element Web               │  ← Ein Client für alles
├────────────────────────────────────────┤
│            Matrix Synapse              │  ← Dezentrales Protokoll
├──────────┬──────────┬─────────────────┤
│  Viber   │ Telegram │    WhatsApp     │  ← Bridges (Verbindungen)
└──────────┴──────────┴─────────────────┘
```

## Features

- 🔌 **3 Messenger vereint**: Viber, Telegram, WhatsApp
- 🏠 **100% Self-Hosted**: Deine Daten, dein Server
- 🔒 **Ende-zu-Ende Verschlüsselung**: Matrix E2EE
- 📱 **Alle Geräte**: Element Client für Web, Desktop, iOS, Android
- 🐳 **Docker**: `docker compose up` — fertig
- 🇩🇪 **Deutsche Doku**: Vollständig auf Deutsch

## Quick Start (3 Minuten)

```bash
# 1. Klonen
git clone https://github.com/deinuser/yappfy.git
cd yappfy

# 2. Setup-Wizard starten
chmod +x setup.sh
./setup.sh

# 3. Browser öffnen
open http://localhost:8080
```

Der Wizard fragt nach:
- Deiner Domain
- Welche Messenger du verbinden willst

## Messenger einrichten

### Telegram
```bash
docker compose exec mautrix-telegram /usr/bin/mautrix-telegram
```
→ QR-Code oder Link folgen

### WhatsApp
```bash
docker compose logs mautrix-whatsapp
```
→ QR-Code in WhatsApp scannen

### Viber
1. Bot auf [Viber Admin Panel](https://partners.viber.com) erstellen
2. Token in `config/mautrix-viber/config.yaml` eintragen
3. `docker compose restart mautrix-viber`

## Architektur

| Komponente | Technologie | Zweck |
|---|---|---|
| **Matrix Server** | Synapse | Föderiertes Chat-Protokoll |
| **Viber Bridge** | mautrix-viber | Viber ↔ Matrix |
| **Telegram Bridge** | mautrix-telegram | Telegram ↔ Matrix |
| **WhatsApp Bridge** | mautrix-whatsapp | WhatsApp ↔ Matrix |
| **Client** | Element Web | Chat-Oberfläche |
| **Datenbank** | PostgreSQL | Synapse Storage |
| **Cache** | Redis | Bridge Performance |
| **Proxy** | Nginx | SSL, Routing |

## Systemanforderungen

- **Minimum**: 2 GB RAM, 2 CPU Kerne
- **Empfohlen**: 4 GB RAM, 4 CPU Kerne
- Docker & Docker Compose
- Domain (für Produktion) oder localhost (zum Testen)

## Lizenz

yappfy ist **AGPL-3.0** — du darfst es nutzen, verändern und weitergeben. Änderungen müssen unter der gleichen Lizenz veröffentlicht werden.

Die Bridges (mautrix-*) stehen unter ihren eigenen Lizenzen (Apache 2.0 / AGPL-3.0).

---

Made with ❤️ in Germany.
