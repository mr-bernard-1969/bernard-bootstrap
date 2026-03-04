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

# ── Tailscale preauth key ──────────────────────────────────────────────────────

resource "tailscale_preauthkey" "main" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = [var.tailscale_tag]
}

# ── Cloudflare DNS ─────────────────────────────────────────────────────────────

resource "cloudflare_record" "main" {
  zone_id = var.cloudflare_zone_id
  name    = var.instance_name
  type    = "A"
  value   = hcloud_server.main.ipv4_address
  ttl     = 60
  proxied = false
}

# ── Rendered templates ─────────────────────────────────────────────────────────

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
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "10m"
  }

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
}
