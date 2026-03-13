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
