# yappfy — Your Chats. Your Server. Your Rules.

**All messengers in one interface. Self-hosted. Open Source. Free.**

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
[![Native](https://img.shields.io/badge/native-macOS_|_Windows-blue)](install-native.sh)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen)](https://docs.docker.com/)
[![Matrix](https://img.shields.io/badge/Matrix-000000?style=flat&logo=matrix&logoColor=white)](https://matrix.org)

---

## What is yappfy?

yappfy unifies **all your messengers** into **one client**. No cloud service, no data sharing — everything runs on **your server**.

[![WhatsApp](https://img.shields.io/badge/WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](#)
[![Signal](https://img.shields.io/badge/Signal-3A76F0?style=for-the-badge&logo=signal&logoColor=white)](#)
[![Telegram](https://img.shields.io/badge/Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](#)
[![Viber](https://img.shields.io/badge/Viber-7360F2?style=for-the-badge&logo=viber&logoColor=white)](#)
[![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)](#)
[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](#)
[![Email](https://img.shields.io/badge/Email-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](#)
[![Messenger](https://img.shields.io/badge/Messenger-0084FF?style=for-the-badge&logo=messenger&logoColor=white)](#)
[![Instagram](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](#)
[![iMessage](https://img.shields.io/badge/iMessage-34D399?style=for-the-badge&logo=apple&logoColor=white)](#)
[![WeChat](https://img.shields.io/badge/WeChat-07C160?style=for-the-badge&logo=wechat&logoColor=white)](#)
[![Snapchat](https://img.shields.io/badge/Snapchat-FFFC00?style=for-the-badge&logo=snapchat&logoColor=black)](#)
[![Teams](https://img.shields.io/badge/Teams-6264A7?style=for-the-badge&logo=microsoftteams&logoColor=white)](#)
[![Google Chat](https://img.shields.io/badge/Google_Chat-4285F4?style=for-the-badge&logo=googlechat&logoColor=white)](#)
[![SMS](https://img.shields.io/badge/SMS-8888A0?style=for-the-badge&logo=android&logoColor=white)](#)
[![Twitter/X](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](#)

---

```
┌────────────────────────────────────────────────┐
│                  Element Web                    │  ← One client for everything
├────────────────────────────────────────────────┤
│              Matrix Synapse                     │  ← Decentralized protocol
├──────┬──────┬──────┬──────┬──────┬─────────────┤
│WhatsApp│Signal│Telegram│Viber│Slack│ Discord …  │  ← 16+ Bridges
└──────┴──────┴──────┴──────┴──────┴─────────────┘
```

## Features

- 🔌 **16+ messengers unified**: WhatsApp, Signal, Telegram, Viber, Slack, Discord, Facebook Messenger, Instagram, iMessage, WeChat, Snapchat, Teams, Google Chat, SMS, Twitter/X, Email
- 🏠 **100% Self-Hosted**: Your data, your server
- 🔒 **End-to-End Encryption**: Matrix E2EE
- 📱 **All devices**: Element client for Web, Desktop, iOS, Android
- 🐳 **Docker** or 🖥️ **Native**: Choose Docker or run directly on macOS/Windows/Linux
- 🇪🇺 **DSGVO/GDPR compliant**: Privacy by design
- ⚡ **Lightweight**: Dendrite (Go, SQLite) uses <100 MB RAM native

## Quick Start

### Option A: Native (No Docker) 🖥️

```bash
# macOS / Linux
chmod +x install-native.sh && ./install-native.sh

# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File install-native.ps1
```

→ Then run `~/.yappfy/start.sh` (or `start.bat` on Windows)
→ Open **http://localhost:8009**

Uses **Dendrite** (Go binary, SQLite) instead of Synapse+PostgreSQL.  
No Docker, no external database — just one Go binary + Element Web.

### Option B: Docker 🐳

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

### Signal
```bash
docker compose logs mautrix-signal
```
→ Link as companion device

### Viber
1. Create a bot on the [Viber Admin Panel](https://partners.viber.com)
2. Add the token to `config/mautrix-viber/config.yaml`
3. `docker compose restart mautrix-viber`

### Discord / Slack / Messenger / Instagram / iMessage / Teams / Google Chat
More bridges available — see individual [mautrix docs](https://docs.mau.fi/bridges/).

## Architecture

| Component | Docker | Native |
|---|---|---|
| **Matrix Server** | Synapse + PostgreSQL | Dendrite (Go, SQLite) |
| **WhatsApp Bridge** | mautrix-whatsapp | mautrix-whatsapp |
| **Signal Bridge** | mautrix-signal | mautrix-signal |
| **Telegram Bridge** | mautrix-telegram | mautrix-telegram |
| **Viber Bridge** | mautrix-viber | mautrix-viber |
| **Slack Bridge** | mautrix-slack | mautrix-slack |
| **Discord Bridge** | mautrix-discord | mautrix-discord |
| **Messenger / IG** | mautrix-meta | mautrix-meta |
| **iMessage Bridge** | mautrix-imessage | mautrix-imessage |
| **Google Chat** | mautrix-googlechat | mautrix-googlechat |
| **Client** | Element Web | Element Web |
| **Database** | PostgreSQL | SQLite |
| **Cache** | Redis | (none needed) |
| **Proxy** | Nginx | (none needed) |

## System Requirements

### Native (Dendrite)
- **Minimum**: 512 MB RAM, 1 CPU core
- **Recommended**: 1 GB RAM, 2 CPU cores
- Go 1.21+ (for building; binary included)
- Python 3.9+ (for serving Element Web)
- macOS, Windows, or Linux

### Docker
- **Minimum**: 2 GB RAM, 2 CPU cores
- **Recommended**: 4 GB RAM, 4 CPU cores (8+ GB for 10+ bridges)
- Docker & Docker Compose
- Domain (production) or localhost (testing)

## License

yappfy is **AGPL-3.0** — you may use, modify, and redistribute it. Changes must be published under the same license.

The bridges (mautrix-*) are under their respective licenses (Apache 2.0 / AGPL-3.0).

---

Made with ❤️ in Austria.
