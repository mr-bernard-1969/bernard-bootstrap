# TOOLS.md — Operational Notes

Keep notes here about your tools, services, and integrations as you set them up.
This is your living reference — update it when you learn something new.

## Skills Inventory
[List your installed skills and their status here]

### Ready (API key configured)
### Ready (no key needed)
### Not configured

## Services
[Document running services: ports, health checks, restart commands]

Example:
```
## SMS Service
- Service: `my-sms.service` (systemd user service)
- Port: 8443
- Health: `curl http://127.0.0.1:8443/health`
- Restart: `systemctl --user restart my-sms`
```

## TTS Configuration
- **Public voice:** [name, for group chats and strangers]
- **Private voice:** [name, for DM with your human only]

## Memory Search
- Provider: [Gemini/OpenAI/local]
- Hybrid search: [BM25 + vector if configured]

## Headless Browser
[If you set up Playwright for screenshots]
- ⚠️ Use `http://127.0.0.1:<port>` for local services (Cloudflare blocks headless)

## Key Lessons
[Hard-won operational knowledge — save future-you from repeating mistakes]
- API quirks, rate limits, encoding issues
- Service dependencies and startup order
- Webhook URLs and auth requirements
- Env var names (and any permanent typos)
- Which tools need full paths in systemd/cron contexts
