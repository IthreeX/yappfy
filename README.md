# yappfy — Your Chats. Your Server. Your Rules.

**Viber + Telegram + WhatsApp in one interface. Self-hosted. Open Source. Free.**

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen)](https://docs.docker.com/)

> 🇩🇪 [Deutsche Version unten](#yappfy--deine-chats-dein-server-deine-regeln)

---

## What is yappfy?

yappfy unifies your messengers into **one client**. No cloud service, no data sharing — everything runs on **your server**.

```
┌────────────────────────────────────────┐
│              Element Web               │  ← One client for everything
├────────────────────────────────────────┤
│            Matrix Synapse              │  ← Decentralized protocol
├──────────┬──────────┬─────────────────┤
│  Viber   │ Telegram │    WhatsApp     │  ← Bridges
└──────────┴──────────┴─────────────────┘
```

## Features

- 🔌 **3 messengers unified**: Viber, Telegram, WhatsApp
- 🏠 **100% Self-Hosted**: Your data, your server
- 🔒 **End-to-End Encryption**: Matrix E2EE
- 📱 **All devices**: Element client for Web, Desktop, iOS, Android
- 🐳 **Docker**: `docker compose up` — done
- 🇪🇺 **DSGVO/GDPR compliant**: Privacy by design

## Quick Start (3 minutes)

```bash
# 1. Clone
git clone https://github.com/IthreeX/yappfy.git
cd yappfy

# 2. Run setup wizard
chmod +x setup.sh
./setup.sh

# 3. Open your browser
open http://localhost:8080
```

The wizard asks for:
- Your domain
- Which messengers you want to connect

## Setting up messengers

### Telegram
```bash
docker compose exec mautrix-telegram /usr/bin/mautrix-telegram
```
→ Follow the QR code or link

### WhatsApp
```bash
docker compose logs mautrix-whatsapp
```
→ Scan QR code in WhatsApp

### Viber
1. Create a bot on the [Viber Admin Panel](https://partners.viber.com)
2. Add the token to `config/mautrix-viber/config.yaml`
3. `docker compose restart mautrix-viber`

## Architecture

| Component | Technology | Purpose |
|---|---|---|
| **Matrix Server** | Synapse | Federated chat protocol |
| **Viber Bridge** | mautrix-viber | Viber ↔ Matrix |
| **Telegram Bridge** | mautrix-telegram | Telegram ↔ Matrix |
| **WhatsApp Bridge** | mautrix-whatsapp | WhatsApp ↔ Matrix |
| **Client** | Element Web | Chat interface |
| **Database** | PostgreSQL | Synapse storage |
| **Cache** | Redis | Bridge performance |
| **Proxy** | Nginx | SSL, routing |

## System Requirements

- **Minimum**: 2 GB RAM, 2 CPU cores
- **Recommended**: 4 GB RAM, 4 CPU cores
- Docker & Docker Compose
- Domain (production) or localhost (testing)

## License

yappfy is **AGPL-3.0** — you may use, modify, and redistribute it. Changes must be published under the same license.

The bridges (mautrix-*) are under their respective licenses (Apache 2.0 / AGPL-3.0).

---

Made with ❤️ in Austria.

---

## yappfy — Deine Chats. Dein Server. Deine Regeln.

**Viber + Telegram + WhatsApp in einer Oberfläche. Self-hosted. Open Source. Kostenlos.**

yappfy vereint deine Messenger in **einem Client**. Kein Cloud-Dienst, keine Datenweitergabe — alles läuft auf **deinem Server**.

### Quick Start

```bash
git clone https://github.com/IthreeX/yappfy.git
cd yappfy
chmod +x setup.sh
./setup.sh
open http://localhost:8080
```

### Lizenz

yappfy ist **AGPL-3.0** — du darfst es nutzen, verändern und weitergeben. Änderungen müssen unter der gleichen Lizenz veröffentlicht werden.

Made with ❤️ in Austria.
