# Bernard Bootstrap — Terraform VPS Provisioning

One command spins up a fully working OpenClaw instance: Hetzner VPS, Cloudflare DNS,
Tailscale joined, HTTPS cert, OpenClaw configured and running against your LiteLLM proxy.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5 installed locally
- Hetzner Cloud account + API token
- Cloudflare-managed domain + API token with Zone:Edit permission
- Tailscale account with `tag:bernard-vps` already in your ACL's `tagOwners`
  (see `scripts/add-bernard-vps.py` in the tailscale-network-setup repo if not done)
- An existing LiteLLM proxy reachable from the VPS via Tailscale

## Quickstart

```bash
cd provision/terraform

# 1. Copy and fill in your secrets
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 2. Initialize providers
terraform init

# 3. Preview what will be created
terraform plan

# 4. Apply — takes ~5 minutes
terraform apply

# 5. Get your URL
terraform output gateway_url_https
```

Open the URL in your browser. You should see the OpenClaw UI with Health OK.

## What gets created

| Resource | Details |
|---|---|
| Hetzner server | CX22 — 2 vCPU, 4GB RAM, 40GB SSD, Ubuntu 24.04, ~$4.15/mo |
| Cloudflare DNS | A record: `<instance_name>.<domain>` → server public IP |
| Tailscale device | Joined as `<instance_name>` tagged `tag:bernard-vps` (Tailscale ACL controls access) |
| Let's Encrypt cert | Auto-issued via Cloudflare DNS-01 challenge — no port 80 required during issuance |
| OpenClaw | System service, configured with LiteLLM provider, token auth, nginx HTTPS reverse proxy |

## Instance naming

Name instances `bernard-1`, `bernard-2`, etc. Each instance is independent — running
`terraform apply` with a different `instance_name` creates a new instance without touching
existing ones, as long as you use separate state (see below).

**Separate state per instance:**
```bash
# Option A: separate directories
mkdir bernard-1 && cp terraform.tfvars bernard-1/ && cd bernard-1 && terraform init && terraform apply

# Option B: Terraform workspaces
terraform workspace new bernard-2
terraform apply -var="instance_name=bernard-2"
```

## Teardown

```bash
terraform destroy
```

Destroys the server, DNS record, and removes the Tailscale device. The auth key expires
automatically (1h). Cert is deleted with the server.

## Troubleshooting

**Provisioner fails mid-way**
The server is created but incomplete. Check what failed:
```bash
ssh root@<server-ip> cat /tmp/provision.log
```
Fix the issue, then reprovision:
```bash
terraform taint hcloud_server.main
terraform apply
```

**Gateway not responding**
```bash
ssh openclaw@<server-ip>
systemctl status openclaw-gateway
journalctl -u openclaw-gateway -n 50
```

**401 errors when chatting**
LiteLLM not reachable. From the VPS:
```bash
curl http://<litellm_base_url>/health
```
Verify VPS is on Tailscale and your ACL allows it to reach the LiteLLM host.

**DNS not propagated yet**
Wait 1-2 minutes. The Cloudflare TTL is set to 60 seconds.
```bash
dig <instance_name>.<domain>
```
