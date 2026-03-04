#!/bin/bash
set -euo pipefail

echo "=== [1/14] System packages ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq curl git ufw jq nginx certbot python3-certbot-dns-cloudflare

echo "=== [2/14] Node.js 22 LTS ==="
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y -qq nodejs

echo "=== [3/14] Tailscale ==="
curl -fsSL https://tailscale.com/install.sh | sh

echo "=== [4/14] openclaw user ==="
useradd -m -s /bin/bash openclaw || true
mkdir -p /home/openclaw/.ssh
cp /root/.ssh/authorized_keys /home/openclaw/.ssh/authorized_keys
chown -R openclaw:openclaw /home/openclaw/.ssh
chmod 700 /home/openclaw/.ssh
chmod 600 /home/openclaw/.ssh/authorized_keys

echo "=== [5/14] npm global + OpenClaw ==="
su - openclaw -c 'mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global'
su - openclaw -c 'export PATH=$HOME/.npm-global/bin:$PATH && npm install -g openclaw'

echo "=== [6/14] Tailscale join ==="
tailscale up --auth-key="${tailscale_key}" --hostname="${instance_name}" --accept-routes

echo "=== [7/14] bernard-bootstrap ==="
su - openclaw -c '
  export PATH=$HOME/.npm-global/bin:$PATH
  cd /tmp
  git clone https://github.com/mr-bernard-1969/bernard-bootstrap.git
  cd bernard-bootstrap
  bash setup.sh
  rm -rf /tmp/bernard-bootstrap
'

echo "=== [8/14] openclaw.json ==="
mkdir -p /home/openclaw/.openclaw
cat > /home/openclaw/.openclaw/openclaw.json << 'OCJSON'
${openclaw_json}
OCJSON
chown openclaw:openclaw /home/openclaw/.openclaw/openclaw.json
chmod 600 /home/openclaw/.openclaw/openclaw.json

echo "=== [9/14] .env ==="
cat > /home/openclaw/.openclaw/.env << 'ENVEOF'
ANTHROPIC_API_KEY=${litellm_api_key}
ANTHROPIC_BASE_URL=${litellm_base_url}
NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
OPENCLAW_NO_RESPAWN=1
ENVEOF
chown openclaw:openclaw /home/openclaw/.openclaw/.env
chmod 600 /home/openclaw/.openclaw/.env

echo "=== [10/14] systemd service ==="
cat > /etc/systemd/system/openclaw-gateway.service << 'SVCEOF'
[Unit]
Description=OpenClaw Gateway
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=simple
User=openclaw
ExecStart=/home/openclaw/.npm-global/bin/openclaw gateway --port 18789
Restart=always
RestartSec=5
KillMode=process
Environment=HOME=/home/openclaw
Environment=PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/home/openclaw/.openclaw/.env

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl daemon-reload
systemctl enable openclaw-gateway
systemctl start openclaw-gateway

echo "=== [11/14] Certbot Cloudflare credentials ==="
mkdir -p /root/.cloudflare
cat > /root/.cloudflare/credentials.ini << 'CFEOF'
dns_cloudflare_api_token = ${cloudflare_api_token}
CFEOF
chmod 600 /root/.cloudflare/credentials.ini

echo "=== [12/14] Let's Encrypt cert ==="
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.cloudflare/credentials.ini \
  -d "${instance_name}.${domain}" \
  --non-interactive \
  --agree-tos \
  -m "admin@${domain}"

echo "=== [13/14] nginx ==="
cat > /etc/nginx/sites-available/openclaw << 'NGXEOF'
server {
    listen 80;
    server_name ${instance_name}.${domain};
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name ${instance_name}.${domain};
    ssl_certificate /etc/letsencrypt/live/${instance_name}.${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${instance_name}.${domain}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host localhost:18789;
        proxy_set_header X-Real-IP "";
        proxy_set_header X-Forwarded-For "";
        proxy_set_header X-Forwarded-Proto "";
    }
}
NGXEOF
ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl restart nginx

echo "=== [14/14] Firewall ==="
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=== Provisioning complete ==="
