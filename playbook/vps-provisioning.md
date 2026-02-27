# VPS Provisioning Guide

Step-by-step for spinning up a new OpenClaw instance on a fresh VPS.

## Prerequisites
- Ubuntu 24.04 VPS (2+ cores, 4GB+ RAM recommended)
- SSH access as root
- Anthropic API key
- Telegram bot token (from @BotFather)

## Steps

### 1. System setup
```bash
apt-get update -qq && apt-get upgrade -y -qq
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs git ufw
```

### 2. Create user
```bash
useradd -m -s /bin/bash openclaw
echo "openclaw ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/openclaw
loginctl enable-linger openclaw
```

### 3. Install OpenClaw
```bash
npm install -g openclaw
```

### 4. Run bootstrap
```bash
su - openclaw -c 'git clone https://github.com/mr-bernard-1969/bernard-bootstrap.git ~/bernard-bootstrap && cd ~/bernard-bootstrap && bash setup.sh'
```

### 5. Configure auth
```bash
# Write API key to .env (NOT via openclaw onboard — it requires interactive TTY)
echo "ANTHROPIC_API_KEY=sk-ant-..." > /home/openclaw/.openclaw/.env
echo "TELEGRAM_BOT_TOKEN=123:ABC..." >> /home/openclaw/.openclaw/.env
chown openclaw:openclaw /home/openclaw/.openclaw/.env
chmod 600 /home/openclaw/.openclaw/.env
```

### 6. Configure OpenClaw
```bash
su - openclaw -c '
  openclaw config set gateway.mode local
  openclaw config set gateway.port 18789
  openclaw config set agents.defaults.model.primary "anthropic/claude-sonnet-4-5"
  openclaw config set channels.telegram.enabled true
  openclaw config set channels.telegram.botToken "\${TELEGRAM_BOT_TOKEN}"
'
# Fix allowFrom (config set doesn't handle arrays well)
python3 -c "
import json
with open('/home/openclaw/.openclaw/openclaw.json') as f:
    d = json.load(f)
d['channels']['telegram']['allowFrom'] = ['*']
d['channels']['telegram']['dmPolicy'] = 'open'
d['channels']['telegram']['groupPolicy'] = 'open'
d['channels']['telegram']['streaming'] = True
with open('/home/openclaw/.openclaw/openclaw.json', 'w') as f:
    json.dump(d, f, indent=2)
"
```

### 7. Create systemd service
```bash
cat > /etc/systemd/system/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/node /usr/lib/node_modules/openclaw/dist/index.js gateway --port 18789
Restart=always
RestartSec=5
KillMode=process
User=openclaw
Environment=HOME=/home/openclaw
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/home/openclaw/.openclaw/.env

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw-gateway
systemctl start openclaw-gateway
```

### 8. Firewall
```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### 9. Verify
```bash
systemctl status openclaw-gateway
journalctl -u openclaw-gateway -n 20 --no-pager | grep telegram
```

## Permissions checklist
```bash
chmod 700 /home/openclaw/.openclaw
chmod 600 /home/openclaw/.openclaw/openclaw.json
chmod 600 /home/openclaw/.openclaw/.env
```

## Common issues
- **`openclaw onboard` hangs:** Use `.env` + `config set` instead (see step 5-6)
- **systemd user bus unavailable under `su`:** Use system-level service with `User=openclaw`
- **`find` returns wrong index.js:** Entry point is `/usr/lib/node_modules/openclaw/dist/index.js`
- **Telegram `allowFrom` validation error:** Edit JSON directly with Python (see step 6)
