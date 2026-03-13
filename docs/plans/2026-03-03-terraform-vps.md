# Terraform VPS Automation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** One `terraform apply` creates a fully working OpenClaw instance: Hetzner VPS, Cloudflare DNS, Tailscale joined, HTTPS cert, OpenClaw configured and running against LiteLLM proxy.

**Architecture:** Terraform manages infra (Hetzner server, Cloudflare A record, Tailscale preauth key, random gateway token). A `remote-exec` provisioner SSHes in as root and runs inline bash: installs packages, creates the `openclaw` user, installs OpenClaw, joins Tailscale, writes the exact working `openclaw.json`, creates a system-level systemd service, gets a Let's Encrypt cert, and configures nginx (HTTPS → loopback gateway). Gateway binds to loopback, nginx handles TLS termination.

**Tech Stack:** Terraform ≥1.5, providers: `hetznercloud/hcloud`, `cloudflare/cloudflare`, `tailscale/tailscale`, `hashicorp/random`.

---

### Task 1: Directory scaffold and .gitignore

**Files:**
- Create: `provision/terraform/.gitignore`

**Step 1: Create the directory**
```bash
mkdir -p provision/terraform
```

**Step 2: Write `.gitignore`**
```
# Secret inputs — never commit
terraform.tfvars

# Terraform state and cache — never commit
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc
```

**Step 3: Commit**
```bash
git add provision/terraform/.gitignore
git commit -m "feat: scaffold terraform directory"
```

---

### Task 2: Variables

**Files:**
- Create: `provision/terraform/variables.tf`
- Create: `provision/terraform/terraform.tfvars.example`

**Step 1: Write `variables.tf`**
```hcl
# Identity
variable "instance_name" {
  description = "Name for this instance (e.g. 'bernard-1'). Used as hostname, Tailscale device name, and DNS subdomain."
  type        = string
}

variable "domain" {
  description = "Root domain (e.g. 'itookthese.com'). DNS record will be <instance_name>.<domain>."
  type        = string
}

# Hetzner
variable "hetzner_token" {
  description = "Hetzner Cloud API token (from hetzner.com → project → API Tokens)"
  type        = string
  sensitive   = true
}

variable "server_type" {
  description = "Hetzner server type. CX22 = 2 vCPU, 4GB RAM, 40GB SSD, ~$4.15/mo"
  type        = string
  default     = "cx22"
}

variable "server_location" {
  description = "Hetzner datacenter location (nbg1=Nuremberg, fsn1=Falkenstein, hel1=Helsinki, ash=Ashburn)"
  type        = string
  default     = "nbg1"
}

variable "server_image" {
  description = "OS image for the server"
  type        = string
  default     = "ubuntu-24.04"
}

# SSH
variable "ssh_public_key" {
  description = "SSH public key content (e.g. contents of ~/.ssh/id_ed25519.pub). Installed for both root and openclaw users."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to private SSH key on your local machine. Used by Terraform provisioner to connect."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

# Cloudflare
variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit permissions for the target zone."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID (from domain dashboard → Overview → right sidebar)."
  type        = string
}

# Tailscale
variable "tailscale_api_key" {
  description = "Tailscale API key (from tailscale.com/admin/settings/keys). Needs tailnets:write scope."
  type        = string
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "Tailscale tailnet slug. '-' resolves to your default tailnet."
  type        = string
  default     = "-"
}

variable "tailscale_tag" {
  description = "Tailscale tag for this device. Must already exist in tagOwners in your ACL."
  type        = string
  default     = "tag:bernard-vps"
}

# LiteLLM proxy
variable "litellm_base_url" {
  description = "Base URL of your LiteLLM proxy (reachable from the VPS via Tailscale)."
  type        = string
}

variable "litellm_api_key" {
  description = "Master key for your LiteLLM proxy."
  type        = string
  sensitive   = true
}

variable "litellm_model_id" {
  description = "Model ID as registered in LiteLLM (used in openclaw.json)."
  type        = string
  default     = "claude-sonnet-4-6"
}
```

**Step 2: Write `terraform.tfvars.example`**
```hcl
# Copy this file to terraform.tfvars and fill in your values.
# DO NOT commit terraform.tfvars — it contains secrets.

# Identity
instance_name = "bernard-1"
domain        = "itookthese.com"

# Hetzner (hetzner.com → project → API Tokens → Generate API token)
hetzner_token   = "your-hetzner-token-here"
server_type     = "cx22"
server_location = "nbg1"

# SSH (paste the CONTENTS of your public key file, not the file path)
ssh_public_key       = "ssh-ed25519 AAAA... you@machine"
ssh_private_key_path = "~/.ssh/id_ed25519"

# Cloudflare (cloudflare.com → domain → Overview → Zone ID in right sidebar)
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id   = "your-zone-id-here"

# Tailscale (tailscale.com/admin/settings/keys → Generate auth key)
# The tailscale_api_key is used to generate a device auth key programmatically.
# Requires tailnets:write scope.
tailscale_api_key = "tskey-api-..."
tailscale_tailnet = "-"
tailscale_tag     = "tag:bernard-vps"

# LiteLLM proxy (your existing proxy, reachable from VPS via Tailscale)
litellm_base_url  = "http://100.127.63.22:4000"
litellm_api_key   = "sk-local-litellm-key"
litellm_model_id  = "claude-sonnet-4-6"
```

**Step 3: Commit**
```bash
git add provision/terraform/variables.tf provision/terraform/terraform.tfvars.example
git commit -m "feat: add terraform variables and example tfvars"
```

---

### Task 3: Main resources (server, DNS, Tailscale key, token)

**Files:**
- Create: `provision/terraform/main.tf`

**Step 1: Write `main.tf`**
```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ── Providers ─────────────────────────────────────────────────────────────────

provider "hcloud" {
  token = var.hetzner_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = var.tailscale_tailnet
}

# ── Random gateway auth token ─────────────────────────────────────────────────

resource "random_id" "gateway_token" {
  byte_length = 24
}

# ── SSH key ────────────────────────────────────────────────────────────────────

resource "hcloud_ssh_key" "main" {
  name       = var.instance_name
  public_key = var.ssh_public_key
}

# ── Hetzner server ─────────────────────────────────────────────────────────────

resource "hcloud_server" "main" {
  name        = var.instance_name
  server_type = var.server_type
  location    = var.server_location
  image       = var.server_image
  ssh_keys    = [hcloud_ssh_key.main.id]

  labels = {
    managed_by = "terraform"
    role       = "openclaw-gateway"
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  # ── Provisioner ──────────────────────────────────────────────────────────────
  provisioner "remote-exec" {
    inline = [
      # ── 1. System packages ──────────────────────────────────────────────────
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update -qq",
      "apt-get upgrade -y -qq",
      "apt-get install -y -qq curl git ufw jq nginx certbot python3-certbot-dns-cloudflare",

      # ── 2. Node.js 22 LTS ───────────────────────────────────────────────────
      "curl -fsSL https://deb.nodesource.com/setup_22.x | bash -",
      "apt-get install -y -qq nodejs",

      # ── 3. Tailscale ────────────────────────────────────────────────────────
      "curl -fsSL https://tailscale.com/install.sh | sh",

      # ── 4. openclaw user ────────────────────────────────────────────────────
      "useradd -m -s /bin/bash openclaw || true",
      "mkdir -p /home/openclaw/.ssh",
      "cp /root/.ssh/authorized_keys /home/openclaw/.ssh/authorized_keys",
      "chown -R openclaw:openclaw /home/openclaw/.ssh",
      "chmod 700 /home/openclaw/.ssh && chmod 600 /home/openclaw/.ssh/authorized_keys",

      # ── 5. npm global + OpenClaw ─────────────────────────────────────────────
      "su - openclaw -c 'mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global'",
      "su - openclaw -c 'export PATH=$HOME/.npm-global/bin:$PATH && npm install -g openclaw'",

      # ── 6. Tailscale join ────────────────────────────────────────────────────
      "tailscale up --auth-key=${tailscale_preauthkey.main.key} --hostname=${var.instance_name} --accept-routes",

      # ── 7. bernard-bootstrap ─────────────────────────────────────────────────
      "su - openclaw -c 'export PATH=$HOME/.npm-global/bin:$PATH && cd /tmp && git clone https://github.com/mr-bernard-1969/bernard-bootstrap.git && cd bernard-bootstrap && bash setup.sh && rm -rf /tmp/bernard-bootstrap'",

      # ── 8. openclaw.json ─────────────────────────────────────────────────────
      "mkdir -p /home/openclaw/.openclaw",
      <<-JSON
      cat > /home/openclaw/.openclaw/openclaw.json << 'OCJSON'
      {
        "meta": { "lastTouchedVersion": "2026.3.2" },
        "agents": {
          "defaults": {
            "model": "litellm/${var.litellm_model_id}",
            "models": {
              "litellm/${var.litellm_model_id}": {
                "alias": "sonnet",
                "params": { "cacheRetention": "short" }
              }
            },
            "contextPruning": { "mode": "cache-ttl", "ttl": "1h" },
            "compaction": { "mode": "safeguard" },
            "heartbeat": { "every": "30m" }
          }
        },
        "models": {
          "providers": {
            "litellm": {
              "baseUrl": "${var.litellm_base_url}",
              "apiKey": "${var.litellm_api_key}",
              "api": "openai-completions",
              "models": [
                {
                  "id": "${var.litellm_model_id}",
                  "name": "Claude Sonnet 4.6",
                  "contextWindow": 200000,
                  "maxTokens": 8192
                }
              ]
            }
          }
        },
        "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
        "gateway": {
          "mode": "local",
          "bind": "loopback",
          "trustedProxies": ["127.0.0.1"],
          "controlUi": {
            "allowedOrigins": ["https://${var.instance_name}.${var.domain}"],
            "allowInsecureAuth": true,
            "dangerouslyDisableDeviceAuth": true
          },
          "auth": {
            "mode": "token",
            "token": "${random_id.gateway_token.hex}"
          }
        }
      }
      OCJSON
      JSON
      ,
      "chown openclaw:openclaw /home/openclaw/.openclaw/openclaw.json",
      "chmod 600 /home/openclaw/.openclaw/openclaw.json",

      # ── 9. .env file ──────────────────────────────────────────────────────────
      "cat > /home/openclaw/.openclaw/.env << 'ENVFILE'",
      "ANTHROPIC_API_KEY=${var.litellm_api_key}",
      "ANTHROPIC_BASE_URL=${var.litellm_base_url}",
      "NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache",
      "OPENCLAW_NO_RESPAWN=1",
      "ENVFILE",
      "chown openclaw:openclaw /home/openclaw/.openclaw/.env",
      "chmod 600 /home/openclaw/.openclaw/.env",

      # ── 10. systemd system service ────────────────────────────────────────────
      "cat > /etc/systemd/system/openclaw-gateway.service << 'SVCEOF'",
      "[Unit]",
      "Description=OpenClaw Gateway",
      "After=network-online.target tailscaled.service",
      "Wants=network-online.target",
      "",
      "[Service]",
      "Type=simple",
      "User=openclaw",
      "ExecStart=/home/openclaw/.npm-global/bin/openclaw gateway --port 18789",
      "Restart=always",
      "RestartSec=5",
      "KillMode=process",
      "Environment=HOME=/home/openclaw",
      "Environment=PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin",
      "EnvironmentFile=/home/openclaw/.openclaw/.env",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "SVCEOF",
      "systemctl daemon-reload",
      "systemctl enable openclaw-gateway",
      "systemctl start openclaw-gateway",

      # ── 11. Certbot Cloudflare credentials ────────────────────────────────────
      "mkdir -p /root/.cloudflare",
      "echo 'dns_cloudflare_api_token = ${var.cloudflare_api_token}' > /root/.cloudflare/credentials.ini",
      "chmod 600 /root/.cloudflare/credentials.ini",

      # ── 12. Let's Encrypt cert ────────────────────────────────────────────────
      "certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare/credentials.ini -d ${var.instance_name}.${var.domain} --non-interactive --agree-tos -m admin@${var.domain}",

      # ── 13. nginx config ──────────────────────────────────────────────────────
      "cat > /etc/nginx/sites-available/openclaw << 'NGXEOF'",
      "server {",
      "    listen 80;",
      "    server_name ${var.instance_name}.${var.domain};",
      "    return 301 https://\\$host\\$request_uri;",
      "}",
      "server {",
      "    listen 443 ssl;",
      "    server_name ${var.instance_name}.${var.domain};",
      "    ssl_certificate /etc/letsencrypt/live/${var.instance_name}.${var.domain}/fullchain.pem;",
      "    ssl_certificate_key /etc/letsencrypt/live/${var.instance_name}.${var.domain}/privkey.pem;",
      "    ssl_protocols TLSv1.2 TLSv1.3;",
      "    location / {",
      "        proxy_pass http://127.0.0.1:18789;",
      "        proxy_http_version 1.1;",
      "        proxy_set_header Upgrade \\$http_upgrade;",
      "        proxy_set_header Connection 'upgrade';",
      "        proxy_set_header Host localhost:18789;",
      "        proxy_set_header X-Real-IP \"\";",
      "        proxy_set_header X-Forwarded-For \"\";",
      "        proxy_set_header X-Forwarded-Proto \"\";",
      "    }",
      "}",
      "NGXEOF",
      "ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw",
      "rm -f /etc/nginx/sites-enabled/default",
      "nginx -t && systemctl enable nginx && systemctl restart nginx",

      # ── 14. Firewall ──────────────────────────────────────────────────────────
      "ufw --force reset",
      "ufw default deny incoming",
      "ufw default allow outgoing",
      "ufw allow 22/tcp",
      "ufw allow 80/tcp",
      "ufw allow 443/tcp",
      "ufw --force enable",
    ]
  }
}

# ── Tailscale preauth key ──────────────────────────────────────────────────────

resource "tailscale_preauthkey" "main" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600  # 1 hour — only needed during provisioning
  tags          = [var.tailscale_tag]
}

# ── Cloudflare DNS ─────────────────────────────────────────────────────────────

resource "cloudflare_record" "main" {
  zone_id = var.cloudflare_zone_id
  name    = var.instance_name
  type    = "A"
  value   = hcloud_server.main.ipv4_address
  ttl     = 60
  proxied = false  # Direct DNS, not Cloudflare proxy — needed for WebSocket support
}
```

**Note on heredoc syntax:** The inline list approach above has limitations with multiline strings. In practice the `openclaw.json` and service file blocks need to be written as `echo` chains or via a `templatefile`. See Task 4 for the cleaner approach using a template file.

**Step 2: Commit**
```bash
git add provision/terraform/main.tf
git commit -m "feat: add terraform main resources (server, dns, tailscale, token)"
```

---

### Task 4: Refactor provisioner to use templatefile (cleaner heredocs)

The inline list in `remote-exec` can't handle multiline strings cleanly. Move the provisioner script to a template file that Terraform renders before sending.

**Files:**
- Create: `provision/terraform/scripts/provision.sh.tpl`
- Modify: `provision/terraform/main.tf` — replace inline with `script` provisioner using rendered template

**Step 1: Write `provision/terraform/scripts/provision.sh.tpl`**
```bash
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
```

**Step 2: Write `provision/terraform/templates/openclaw.json.tpl`**

This is rendered separately and embedded in the script as `${openclaw_json}`:

```json
{
  "meta": { "lastTouchedVersion": "2026.3.2" },
  "agents": {
    "defaults": {
      "model": "litellm/${litellm_model_id}",
      "models": {
        "litellm/${litellm_model_id}": {
          "alias": "sonnet",
          "params": { "cacheRetention": "short" }
        }
      },
      "contextPruning": { "mode": "cache-ttl", "ttl": "1h" },
      "compaction": { "mode": "safeguard" },
      "heartbeat": { "every": "30m" }
    }
  },
  "models": {
    "providers": {
      "litellm": {
        "baseUrl": "${litellm_base_url}",
        "apiKey": "${litellm_api_key}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${litellm_model_id}",
            "name": "Claude Sonnet 4.6",
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true, "ownerDisplay": "raw" },
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "trustedProxies": ["127.0.0.1"],
    "controlUi": {
      "allowedOrigins": ["https://${instance_name}.${domain}"],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "${gateway_token}"
    }
  }
}
```

**Step 3: Update `main.tf` — replace inline with rendered script**

Replace the `provisioner "remote-exec"` block in the `hcloud_server` resource:

```hcl
# Add locals to render templates
locals {
  openclaw_json = templatefile("${path.module}/templates/openclaw.json.tpl", {
    litellm_model_id = var.litellm_model_id
    litellm_base_url = var.litellm_base_url
    litellm_api_key  = var.litellm_api_key
    instance_name    = var.instance_name
    domain           = var.domain
    gateway_token    = random_id.gateway_token.hex
  })

  provision_script = templatefile("${path.module}/scripts/provision.sh.tpl", {
    tailscale_key        = tailscale_preauthkey.main.key
    instance_name        = var.instance_name
    domain               = var.domain
    litellm_base_url     = var.litellm_base_url
    litellm_api_key      = var.litellm_api_key
    cloudflare_api_token = var.cloudflare_api_token
    openclaw_json        = local.openclaw_json
  })
}
```

Then change the server's provisioner to:
```hcl
provisioner "remote-exec" {
  inline = [local.provision_script]
}
```

Wait — `inline` expects a list of strings. Use `script` with a `null_resource` local file approach instead, or use a `file` provisioner + `remote-exec` to run it. The cleanest approach:

```hcl
# Write rendered script to a temp file locally, upload and run
provisioner "file" {
  content     = local.provision_script
  destination = "/tmp/provision.sh"
}

provisioner "remote-exec" {
  inline = [
    "chmod +x /tmp/provision.sh",
    "bash /tmp/provision.sh 2>&1 | tee /tmp/provision.log",
  ]
}
```

**Step 4: Commit**
```bash
git add provision/terraform/scripts/ provision/terraform/templates/ provision/terraform/main.tf
git commit -m "feat: refactor provisioner to use templatefile for clean heredocs"
```

---

### Task 5: Outputs

**Files:**
- Create: `provision/terraform/outputs.tf`

**Step 1: Write `outputs.tf`**
```hcl
output "server_ip" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.main.ipv4_address
}

output "gateway_token" {
  description = "Auth token for the OpenClaw gateway"
  value       = random_id.gateway_token.hex
  sensitive   = true
}

output "gateway_url_https" {
  description = "Public HTTPS URL for the OpenClaw UI (via nginx + Let's Encrypt)"
  value       = "https://${var.instance_name}.${var.domain}/?token=${random_id.gateway_token.hex}"
  sensitive   = true
}

output "gateway_url_direct" {
  description = "Direct URL (requires Tailscale). Check Tailscale admin for assigned IP."
  value       = "See tailscale.com/admin/machines for ${var.instance_name} IP, then: http://<tailscale-ip>:18789/?token=${random_id.gateway_token.hex}"
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect as openclaw user"
  value       = "ssh openclaw@${hcloud_server.main.ipv4_address}"
}
```

**Step 2: Show sensitive outputs after apply**
```bash
terraform output gateway_url_https
```

**Step 3: Commit**
```bash
git add provision/terraform/outputs.tf
git commit -m "feat: add terraform outputs (server IP, gateway URLs, token)"
```

---

### Task 6: README for the terraform directory

**Files:**
- Create: `provision/terraform/README.md`

**Step 1: Write `README.md`**
```markdown
# Bernard Bootstrap — Terraform VPS Provisioning

One command spins up a fully working OpenClaw instance: Hetzner VPS, Cloudflare DNS,
Tailscale joined, HTTPS cert, OpenClaw configured and running.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- A Hetzner Cloud account + API token
- A Cloudflare-managed domain + API token with Zone:Edit
- Tailscale account with `tag:bernard-vps` already in your ACL's `tagOwners`
  (run `scripts/add-bernard-vps.py --apply-acl` from tailscale-network-setup if not done)
- An existing LiteLLM proxy reachable from the VPS via Tailscale

## Quickstart

```bash
cd provision/terraform

# 1. Copy and fill in secrets
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # fill in all values

# 2. Initialize providers
terraform init

# 3. Preview what will be created
terraform plan

# 4. Apply (takes ~5 minutes)
terraform apply

# 5. Get your URL
terraform output gateway_url_https
```

## What gets created

| Resource | Details |
|---|---|
| Hetzner server | CX22 (2 vCPU, 4GB RAM, 40GB SSD) running Ubuntu 24.04 |
| Cloudflare DNS | A record: `<instance_name>.<domain>` → server IP |
| Tailscale device | Joined as `<instance_name>` tagged `tag:bernard-vps` |
| Let's Encrypt cert | Auto-issued via Cloudflare DNS challenge |
| OpenClaw | Configured with LiteLLM provider, token auth, nginx HTTPS |

## Teardown

```bash
terraform destroy
```

Note: This destroys the server, DNS record, and Tailscale device. The Tailscale auth key
expires automatically (1h). The Let's Encrypt cert on the now-deleted server is also gone.

## Instance naming

Name new instances `bernard-1`, `bernard-2`, etc. Existing instances are not affected
by running `terraform apply` with a different `instance_name` — they're separate state files.
Keep separate state per instance (use Terraform workspaces or separate directories).

## Troubleshooting

**Provisioner fails mid-way:** The server is created but not fully configured.
Run `ssh root@<ip> cat /tmp/provision.log` to see where it failed.
Fix the underlying issue, then `terraform taint hcloud_server.main && terraform apply`
to reprovision from scratch.

**Gateway not responding:** `ssh openclaw@<ip>` then `systemctl status openclaw-gateway`
and `journalctl -u openclaw-gateway -n 50`.

**401 from agent:** Verify LiteLLM is reachable: `curl http://<litellm_base_url>/health`
from the VPS.
```

**Step 2: Commit**
```bash
git add provision/terraform/README.md
git commit -m "feat: add terraform usage README"
```

---

### Task 7: Update main repo README and provision/README

**Files:**
- Modify: `README.md` — add mention of terraform under Option B
- Modify: `provision/README.md` (if it exists) — note terraform as the primary approach

**Step 1: Check provision/README.md**
```bash
cat provision/README.md
```

**Step 2: Update if needed — add a note pointing to the terraform directory**

**Step 3: Commit all README updates**
```bash
git add README.md provision/README.md
git commit -m "docs: update READMEs to reference terraform provisioner"
```

---

### Task 8: Smoke test

No automated tests for infrastructure — verify manually after `terraform apply`.

**Step 1: Init and plan**
```bash
cd provision/terraform
terraform init
terraform plan
# Expected: plan shows 5 resources to create (server, ssh_key, dns_record, tailscale_key, random_id)
```

**Step 2: Apply (takes ~5 min)**
```bash
terraform apply
# Expected: all 5 resources created, provisioner completes with "=== Provisioning complete ==="
```

**Step 3: Get the URL**
```bash
terraform output gateway_url_https
# Expected: https://bernard-1.itookthese.com/?token=<hex>
```

**Step 4: Open URL in browser**
- Expected: OpenClaw UI loads, Health OK, Version shown
- Send a message: "hello"
- Expected: response from Claude (via LiteLLM), no 401 errors

**Step 5: Verify Tailscale joined**
- Check tailscale.com/admin/machines — new device named `bernard-1` should appear tagged `tag:bernard-vps`

**Step 6: Final commit**
```bash
git add -A
git commit -m "feat: complete terraform vps automation"
```

---

## Key config facts baked in

These were discovered the hard way on the existing bernard VPS:

1. **`models.providers.litellm.api` must be `"openai-completions"`** — if omitted, crash: `No API provider registered for api: undefined`
2. **`models.providers.litellm.models` must be a non-empty array** — if omitted, config validation error
3. **OpenClaw ignores `ANTHROPIC_BASE_URL` env var** — must use `models.providers.litellm.baseUrl` in config
4. **`bind: "loopback"` + `trustedProxies: ["127.0.0.1"]`** — required for nginx to work
5. **`dangerouslyDisableDeviceAuth: true` + `allowInsecureAuth: true`** — required for browser access without device pairing
6. **`auth.mode: "token"`** — required when using non-default bind modes
7. **Tailscale `tag:bernard-vps` must already be in `tagOwners` in ACL** — auth key creation fails otherwise
