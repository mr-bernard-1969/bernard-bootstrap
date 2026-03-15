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

| Service | Port | Health | Restart |
|---------|------|--------|---------|
| Gateway (OC) | 18789 | — | `bash scripts/restart-gateway.sh` |
| [Your service] | [port] | [health URL] | [restart command] |

## TTS Configuration
- **Public voice:** [name, for group chats and strangers]
- **Private voice:** [name, for DM with your human only]

Options:
- **Piper** (local, free): Quick voice messages, low latency
- **Hume Octave** (API, paid): Narration, documentary, dramatic content
- **ElevenLabs** (API, paid): High quality, voice cloning

## Memory Search
- Provider: [Gemini/OpenAI/local]
- Hybrid search: [BM25 + vector if configured]
- Gemini embeddings (gemini-embedding-001) are free and reliable
- OpenAI embeddings may hit quota limits

## Password Management
- Vault: `~/.openclaw/vault.kdbx` (KeePassXC, AES-256)
- CLI: `scripts/vault.sh` (show/list/search/add/edit)
- Sync: [Syncthing/manual] → mobile KeePass app
- Master PW: in `.env` as `VAULT_MASTER_PASSWORD`

## Headless Browser
[If you set up Playwright for screenshots]
- ⚠️ Use `http://127.0.0.1:<port>` for local services (Cloudflare blocks headless)
- Stealth mode: Xvfb + playwright-extra + stealth plugin for sites with bot detection
- `DISPLAY=:99` for headless browser automation on VPS

## Quick Reference
- **Screenshots:** `node scripts/screenshot.js <url> [out.png] [--full] [--wait=ms] [--mobile]`
- **Watermarking:** `python3 scripts/watermark.py embed|extract|verify <file>`
- **Watchdog:** `python3 scripts/hallucination-watchdog.py --full`

## Key Lessons
[Hard-won operational knowledge — save future-you from repeating mistakes]
- API quirks, rate limits, encoding issues
- Service dependencies and startup order
- Webhook URLs and auth requirements
- Env var names (and any permanent typos)
- Which tools need full paths in systemd/cron contexts
- `curl -4` required for some APIs (IPv6 may be blocked)
- `--http1.1` required for some APIs (Twitter/X)

## Pending
[Things not yet configured but planned]
