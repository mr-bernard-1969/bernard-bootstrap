# VPS Provisioning Guide

## Requirements

- A VPS with Ubuntu 22.04+ (2 vCPU, 4GB RAM, 80GB SSD recommended)
- SSH access (root or sudo user)
- An Anthropic API key (or other LLM provider key)

## Cloud Provider Quick Start

### Hetzner (Recommended — best price/performance)

1. Create a CX22 instance (~€4.50/mo) at [console.hetzner.cloud](https://console.hetzner.cloud)
   - Image: Ubuntu 24.04
   - Location: your nearest datacenter
   - Add your SSH key
2. Note the IP address
3. Run: `bash provision-vps.sh <IP> ~/.ssh/id_rsa`

### DigitalOcean

1. Create a Droplet (~$12/mo) at [cloud.digitalocean.com](https://cloud.digitalocean.com)
   - Image: Ubuntu 24.04
   - Plan: Basic, Regular, $12/mo (2GB RAM, 1 vCPU, 50GB SSD)
   - Add your SSH key
2. Note the IP address
3. Run: `bash provision-vps.sh <IP> ~/.ssh/id_rsa`

### Any VPS Provider

As long as you have:
- Ubuntu 22.04+ (Debian-based also works)
- SSH root access
- At least 2GB RAM

The script handles everything else.

## What the Script Does

1. Creates `openclaw` system user
2. Installs Node.js (v22 LTS) via NodeSource
3. Installs OpenClaw globally via npm
4. Runs the Bernard Bootstrap setup
5. Configures the OpenClaw gateway as a systemd service
6. Sets up UFW firewall (SSH + HTTP/HTTPS)
7. Prompts for API key configuration

## After Provisioning

1. SSH into the VPS: `ssh openclaw@<IP>`
2. Configure your API key: `nano ~/.openclaw/.env` → add `ANTHROPIC_API_KEY=sk-...`
3. Set up a Telegram bot (see `setup-telegram-bot.md`)
4. Customize your workspace files in `~/.openclaw/workspace/`
5. Start the gateway: `openclaw gateway start`

## Security Notes

- The script sets up key-based SSH only (password auth disabled)
- UFW firewall allows only SSH (22), HTTP (80), HTTPS (443)
- The `openclaw` user has no root access by default
- API keys are stored in `~/.openclaw/.env` (never version-controlled)
