# Terraform VPS Automation Design

**Date:** 2026-03-03
**Status:** Approved

## Goal

One `terraform apply` spins up a fully working OpenClaw instance named `bernard-X` — Hetzner VPS, Cloudflare DNS, Tailscale joined, OpenClaw configured and running, HTTPS cert issued. Nothing manual.

## File Structure

```
provision/terraform/
├── main.tf                    ← providers + all resources
├── variables.tf               ← all inputs
├── outputs.tf                 ← IP, URLs, gateway token
├── terraform.tfvars.example   ← fill-in template (committed)
├── terraform.tfvars           ← actual secrets (gitignored)
└── README.md                  ← usage instructions
```

## Providers

- `hetznercloud/hcloud` — CX22 server (Ubuntu 24.04, 4GB RAM, 40GB SSD, ~$4.15/mo)
- `cloudflare/cloudflare` — A record `<instance_name>.<domain> → <VPS IP>`
- `tailscale/tailscale` — single-use preauth key tagged `tag:bernard-vps`
- `hashicorp/random` — generates gateway auth token

## Variables

```hcl
# Identity
instance_name        # e.g. "bernard-1" — becomes hostname + subdomain
domain               # e.g. "itookthese.com" — configurable
subdomain_url        # full base URL, e.g. "https://bernard-1.itookthese.com" — configurable

# Hetzner
hetzner_token
server_location      # default "nbg1"
server_type          # default "cx22"

# SSH
ssh_public_key
ssh_private_key_path

# Cloudflare
cloudflare_api_token
cloudflare_zone_id

# Tailscale
tailscale_api_key
tailscale_tailnet    # default "-"

# LiteLLM proxy
litellm_base_url     # e.g. "http://100.127.63.22:4000"
litellm_api_key      # e.g. "sk-local-litellm-key"
```

## Provisioning Sequence (remote-exec over SSH as root)

1. `apt update` + install: `nodejs`, `git`, `ufw`, `curl`, `jq`, `nginx`, `certbot`, `python3-certbot-dns-cloudflare`
2. Create `openclaw` user, copy `/root/.ssh/authorized_keys` to openclaw, `loginctl enable-linger`
3. Configure npm global prefix, install OpenClaw
4. Install Tailscale, join tailnet: `tailscale up --auth-key=<key> --hostname=<instance_name>`
5. Clone bernard-bootstrap, run `setup.sh` as `openclaw`
6. Write `~/.openclaw/openclaw.json` with the exact working config:
   - `model: "litellm/claude-sonnet-4-6"`
   - `models.providers.litellm` with `api: "openai-completions"`, `baseUrl`, `apiKey`, `models[]`
   - `gateway.bind: "tailnet"`, `auth.mode: "token"`, generated token
   - `gateway.controlUi.dangerouslyDisableDeviceAuth: true`
   - `gateway.controlUi.allowInsecureAuth: true`
7. Write systemd user service (`~/.config/systemd/user/openclaw-gateway.service`) with `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL` env vars
8. Enable and start `openclaw-gateway` service
9. Write Cloudflare certbot credentials, run `certbot certonly --dns-cloudflare -d <instance_name>.<domain>`
10. Write nginx config: HTTPS on 443 → `http://<tailscale-ip>:18789`, HTTP on 80 → redirect
11. Enable nginx site, reload nginx
12. `ufw` allow 22, 80, 443; enable

## Key Lessons Encoded in Config

These bugs burned hours — all baked into the generated config so they never happen again:

- `models.providers.litellm.api` MUST be `"openai-completions"` — omitting it causes `No API provider registered for api: undefined`
- `models.providers.litellm.models` MUST be a non-empty array — omitting it causes validation error
- OpenClaw does NOT read `ANTHROPIC_BASE_URL` env var — must use `models.providers.litellm.baseUrl`
- `gateway.bind: "tailnet"` requires `auth.mode: "token"` (not `"none"`)
- `dangerouslyDisableDeviceAuth` requires `allowInsecureAuth: true` for non-HTTPS browser connections
- Tailscale `tag:bernard-vps` must already exist in tagOwners (assumed pre-configured)

## Outputs

- `server_ip` — public IPv4
- `tailscale_hostname` — `<instance_name>` (Tailscale assigns the IP)
- `gateway_token` — the generated auth token
- `gateway_url_tailscale` — `http://<tailscale-ip>:18789/?token=<token>` (Tailscale-only access)
- `gateway_url_https` — `https://<instance_name>.<domain>/?token=<token>` (public HTTPS)

## Not In Scope

- Tailscale ACL management (assumed `tag:bernard-vps` rules already live)
- Telegram bot setup (separate manual step)
- Upgrading existing bernard instance
