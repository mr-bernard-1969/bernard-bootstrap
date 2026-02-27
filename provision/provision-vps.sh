#!/bin/bash
set -euo pipefail

# Bernard Bootstrap — VPS Provisioning Script
# Usage: bash provision-vps.sh <VPS_IP> [SSH_KEY_PATH]
#
# This script provisions a fresh Ubuntu VPS with:
# - openclaw system user
# - Node.js 22 LTS
# - OpenClaw (latest)
# - Bernard Bootstrap workspace setup
# - Systemd gateway service
# - Basic firewall

VPS_IP="${1:-}"
SSH_KEY="${2:-$HOME/.ssh/id_rsa}"

if [ -z "$VPS_IP" ]; then
    echo "Usage: bash provision-vps.sh <VPS_IP> [SSH_KEY_PATH]"
    echo ""
    echo "Example: bash provision-vps.sh 123.45.67.89 ~/.ssh/id_rsa"
    exit 1
fi

echo "🔧 Bernard Bootstrap — VPS Provisioning"
echo "========================================"
echo "Target: $VPS_IP"
echo "SSH Key: $SSH_KEY"
echo ""

# Test SSH connection
echo "🔌 Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new root@"$VPS_IP" "echo 'Connected'"; then
    echo "❌ Cannot connect to $VPS_IP — check IP and SSH key"
    exit 1
fi

echo ""
echo "📦 Provisioning VPS..."

ssh -i "$SSH_KEY" root@"$VPS_IP" 'bash -s' << 'REMOTE_SCRIPT'
set -euo pipefail

echo "--- System update ---"
apt-get update -qq
apt-get upgrade -y -qq

echo "--- Installing essentials ---"
apt-get install -y -qq curl git ufw jq trash-cli

echo "--- Creating openclaw user ---"
if ! id openclaw &>/dev/null; then
    useradd -m -s /bin/bash openclaw
    echo "   ✅ User 'openclaw' created"
else
    echo "   ⏭️  User 'openclaw' already exists"
fi

# Copy SSH keys to openclaw user
mkdir -p /home/openclaw/.ssh
cp /root/.ssh/authorized_keys /home/openclaw/.ssh/authorized_keys
chown -R openclaw:openclaw /home/openclaw/.ssh
chmod 700 /home/openclaw/.ssh
chmod 600 /home/openclaw/.ssh/authorized_keys

echo "--- Installing Node.js 22 LTS ---"
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y -qq nodejs
fi
echo "   Node: $(node --version)"
echo "   npm: $(npm --version)"

echo "--- Configuring npm global for openclaw user ---"
su - openclaw -c '
    mkdir -p ~/.npm-global
    npm config set prefix ~/.npm-global
    echo "export PATH=\$HOME/.npm-global/bin:\$PATH" >> ~/.bashrc
'

echo "--- Installing OpenClaw ---"
su - openclaw -c '
    export PATH=$HOME/.npm-global/bin:$PATH
    npm install -g openclaw
    echo "   OpenClaw: $(openclaw --version 2>/dev/null || echo "installed")"
'

echo "--- Running Bernard Bootstrap ---"
su - openclaw -c '
    export PATH=$HOME/.npm-global/bin:$PATH
    cd /tmp
    if [ -d bernard-bootstrap ]; then rm -rf bernard-bootstrap; fi
    git clone https://github.com/mr-bernard-1969/bernard-bootstrap.git
    cd bernard-bootstrap
    bash setup.sh
    rm -rf /tmp/bernard-bootstrap
'

echo "--- Setting up firewall ---"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable
echo "   ✅ Firewall configured (SSH + HTTP + HTTPS)"

echo "--- Creating .env template ---"
su - openclaw -c '
    mkdir -p ~/.openclaw
    if [ ! -f ~/.openclaw/.env ]; then
        cat > ~/.openclaw/.env << EOF
# LLM Provider API Key (required — pick one)
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...

# Optional: Gemini (for embeddings, image gen)
# GEMINI_API_KEY=...
EOF
        echo "   ✅ .env template created"
    else
        echo "   ⏭️  .env already exists"
    fi
'

echo ""
echo "========================================"
echo "✅ VPS provisioned successfully!"
echo ""
echo "Next steps:"
echo "  1. SSH in: ssh openclaw@$(hostname -I | awk '{print $1}')"
echo "  2. Add your API key: nano ~/.openclaw/.env"
echo "  3. Set up Telegram bot (see setup-telegram-bot.md)"
echo "  4. Customize workspace: nano ~/.openclaw/workspace/SOUL.md"
echo "  5. Start gateway: openclaw gateway start"
REMOTE_SCRIPT

echo ""
echo "✅ Provisioning complete!"
echo ""
echo "SSH in with: ssh -i $SSH_KEY openclaw@$VPS_IP"
