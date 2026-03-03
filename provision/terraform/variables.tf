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
