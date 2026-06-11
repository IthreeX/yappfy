#!/usr/bin/env python3
"""Generate all config files for yappfy bridges."""

import argparse
import os
import secrets
import yaml

CONFIG_DIR = os.path.join(os.path.dirname(__file__), "..", "config")

def generate_synapse(domain):
    """Generate Synapse homeserver.yaml"""
    path = os.path.join(CONFIG_DIR, "synapse", "homeserver.yaml")
    config = {
        "server_name": domain,
        "pid_file": "/data/homeserver.pid",
        "listeners": [
            {"port": 8008, "tls": False, "type": "http",
             "x_forwarded": True,
             "resources": [{"names": ["client", "federation"], "compress": False}]}
        ],
        "database": {
            "name": "psycopg2",
            "args": {
                "user": "yappfy",
                "password": os.environ.get("DB_PASSWORD", "yappfy_secret"),
                "database": "synapse",
                "host": "postgres",
                "cp_min": 5,
                "cp_max": 10,
            }
        },
        "media_store_path": "/data/media",
        "registration_shared_secret": secrets.token_hex(16),
        "report_stats": False,
        "macaroon_secret_key": secrets.token_hex(16),
        "form_secret": secrets.token_hex(16),
        "signing_key_path": "/data/signing.key",
        "trusted_key_servers": [{"server_name": "matrix.org"}],
        "enable_registration": True,
        "enable_registration_without_verification": True,
    }
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        yaml.dump(config, f, default_flow_style=False)
    print(f"  ✓ synapse config → {path}")

def generate_bridge_config(bridge_name, domain, bridge_port=None):
    """Generate a mautrix bridge config.yaml"""
    path = os.path.join(CONFIG_DIR, f"mautrix-{bridge_name}", "config.yaml")
    
    config = {
        "homeserver": {
            "address": f"http://synapse:8008",
            "domain": domain,
        },
        "appservice": {
            "address": f"http://mautrix-{bridge_name}:{bridge_port or 29318}",
            "hostname": "0.0.0.0",
            "port": bridge_port or 29318,
            "database": {
                "type": "sqlite3",
                "uri": f"file:/data/{bridge_name}.db?_foreign_keys=on",
            },
        },
        "logging": {
            "handlers": {
                "console": {
                    "class": "logging.StreamHandler",
                    "formatter": "default",
                }
            },
            "root": {
                "level": "INFO",
                "handlers": ["console"],
            },
        },
    }
    
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        yaml.dump(config, f, default_flow_style=False)
    print(f"  ✓ {bridge_name} bridge config → {path}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--domain", default="localhost")
    parser.add_argument("--viber", action="store_true")
    parser.add_argument("--telegram", action="store_true")
    parser.add_argument("--whatsapp", action="store_true")
    args = parser.parse_args()
    
    print(f"\n  🏠 Domain: {args.domain}\n")
    
    generate_synapse(args.domain)
    
    if args.viber:
        generate_bridge_config("viber", args.domain)
    if args.telegram:
        generate_bridge_config("telegram", args.domain)
    if args.whatsapp:
        generate_bridge_config("whatsapp", args.domain)

if __name__ == "__main__":
    main()
