# Bernard Bootstrap Kit

**Spin up a battle-tested OpenClaw agent in minutes, not months.**

This repo contains the distilled operational DNA from a production OpenClaw agent (Mr. Bernard) that's been running since February 2026. It encodes hundreds of hours of hard-won lessons into a reusable bootstrap that any new agent can inherit.

## What This Is

A bootstrap kit that takes a fresh OpenClaw install and gives it:
- **Workspace structure** — organized memory system, heartbeat config, project scaffolding
- **Operational playbook** — rules for memory discipline, communication, error recovery, security
- **Anti-patterns** — every mistake already made so your agent doesn't repeat them
- **Persona templates** — starting points for SOUL.md, IDENTITY.md, AGENTS.md (customize to your taste)
- **Skills manifest** — which skills to install first and how to configure them
- **Safety scripts** — gateway restart with rollback, self-healing, hallucination watchdog
- **Operational context system** — services.yaml + query tools for managing complex deployments
- **Password management** — KeePassXC vault pattern with mobile sync

## What This Isn't

- Not a copy of Mr. Bernard (you'll build your own persona)
- Not a replacement for OpenClaw itself (you need OpenClaw installed first)
- Not magic — your agent still needs to learn and grow, but it starts from a much better foundation

## Quick Start

### Option A: Manual Setup (You Have a VPS Already)

```bash
git clone https://github.com/mister-bernard/bernard-bootstrap.git
cd bernard-bootstrap
bash setup.sh
```

Then customize:
1. Edit `SOUL.md` — give your agent a personality
2. Edit `USER.md` — tell it about yourself
3. Edit `IDENTITY.md` — name, backstory, operational persona
4. Read the playbook files in `playbook/` for best practices

### Option B: Full VPS Provisioning (Start from Scratch)

If you need to spin up a fresh VPS and install everything:

```bash
# On your local machine or existing server:
bash provision/provision-vps.sh <VPS_IP> <SSH_KEY_PATH>
```

This will:
- Create the `openclaw` user with proper permissions
- Install Node.js, OpenClaw, and dependencies
- Run the bootstrap setup
- Configure systemd services
- Set up firewall basics

See `provision/README.md` for cloud provider-specific instructions (Hetzner, DigitalOcean, etc.).

## Structure

```
bernard-bootstrap/
├── README.md                    ← You are here
├── AGENTS.md                    ← Core operational rules (delegation, memory, safety)
├── setup.sh                     ← One-shot workspace setup
├── provision/
│   ├── README.md                ← VPS provisioning guide
│   ├── provision-vps.sh         ← Automated VPS setup script
│   └── setup-telegram-bot.md   ← Telegram bot creation guide
├── templates/
│   ├── AGENTS.md                ← Full workspace rules template
│   ├── SOUL.md                  ← Personality and core values
│   ├── IDENTITY.md              ← Name, backstory, operational persona
│   ├── USER.md                  ← Template for describing your human
│   ├── HEARTBEAT.md             ← Periodic check configuration
│   ├── TOOLS.md                 ← Service and integration notes
│   └── MEMORY.md               ← Memory architecture template
├── playbook/
│   ├── memory-discipline.md         ← The #1 thing to get right
│   ├── security.md                  ← Access control, secrets, gists, email, document hosting
│   ├── communication.md             ← Speaking, routing, voice, social media, email outreach
│   ├── error-recovery.md            ← Gateway, SSH, services, credits, webhooks, remote machines
│   ├── anti-patterns.md             ← Every mistake already made (40+ entries)
│   ├── subagent-orchestration.md    ← Fan-out/synthesis, pipeline state, cost awareness
│   ├── hallucination-prevention.md  ← 7-dimension watchdog, self-verifying workflows
│   ├── web-services.md             ← Dashboards, auth, APIs, systemd, nginx, Playwright
│   ├── vps-provisioning.md         ← Step-by-step VPS setup guide
│   ├── operational-context.md       ← Services.yaml, knowledge graph, query tools
│   └── password-management.md       ← KeePassXC vault + mobile sync pattern
├── scripts/
│   ├── restart-gateway.sh          ← Safe gateway restart with rollback
│   ├── self-heal.sh                ← Auto-remediate common issues
│   ├── hallucination-watchdog.py   ← Verify file paths, URLs, env vars, memory consistency
│   ├── checkpoint.sh               ← Quick git checkpoint
│   ├── backup-system.py            ← Workspace backup
│   └── emergency-contact.sh        ← Multi-channel emergency notification
├── skills/
│   └── manifest.md                  ← 5-phase skill installation guide
└── tasks/
    ├── add.py                       ← Task queue management (zero LLM tokens)
    └── queue.json                   ← Active task queue
```

## Key Principles

These are the most important lessons from production:

1. **Write-through memory** — If you learn something, write it to a file immediately. "Mental notes" don't survive restarts.
2. **Machine-to-machine first** — If a task can be a bash script or cron job, don't route it through an LLM. Reserve tokens for judgment calls.
3. **Scripts > LLM for plumbing** — Health checks, file syncs, API calls, notifications = pure scripts. Zero LLM involvement.
4. **Delegation protocol** — Main thread is for conversation. Auto-delegate any task needing >1 tool call to a sub-agent. Never block the main thread.
5. **Context preservation** — Every tool call costs ~500-2000 tokens. Delegate aggressively to keep the main session lean and responsive.
6. **Pipeline auto-continuation** — Multi-step workflows auto-continue after trigger. Never make your human manually kick the next stage.
7. **Channel parity** — ALL messaging channels treated equally. No channel is "secondary."
8. **Gmail drafts only** — Never send emails from your human's account. Draft only. Human reviews and sends.
9. **Never host PII on public URLs** — Deliver personal documents directly via messaging. Never on web servers, even "temporarily."
10. **Secret gists by default** — ALL gists are secret unless explicitly asked to be public.
11. **Checkpoint before iterating** — Git commit before making changes. Tag important versions. Cheap insurance.
12. **Groups see only final output** — No progress updates, no system messages, no errors. Deliver the finished product.
13. **Build a hallucination watchdog** — Automate checks for stale file paths, dead URLs, missing env vars. Run daily. Your docs WILL drift from reality.
14. **Skill import rule** — Never adopt skills from other agents without comparing against what you already have. Be analytical, not impressionable.
15. **Never auto-harden** — Always propose security changes and get approval. Never lock yourself out.
16. **Centralized gateway > per-client instances** — One server, one agent, API endpoints per client. Simpler, cheaper, more maintainable.
17. **Operational context as data** — Encode your service topology in YAML/SQLite, not scattered markdown. Query it, don't grep for it.
18. **Silence = healthy** — No cron or heartbeat should message your human unless something is actionable. If everything is fine, say nothing.
19. **Trash > rm** — Use `trash` instead of `rm` for everything. Recoverable beats gone forever.
20. **Read before edit** — Never guess at file contents or anchor text. Always read the file first. Duplicate edits cause ugly failures.

## Changelog

### v6.0 (2026-03-15)
- **NEW: `templates/MEMORY.md`** — Memory architecture template with file hierarchy, knowledge graph patterns, operational context system
- **NEW: `playbook/operational-context.md`** — Services.yaml pattern for encoding service topology as queryable data instead of scattered markdown
- **NEW: `playbook/password-management.md`** — KeePassXC vault pattern with mobile sync (Syncthing + SyncTrain + Strongbox)
- **NEW: `scripts/emergency-contact.sh`** — Multi-channel emergency notification with severity classes
- **AGENTS.md hardened** — Delegation threshold lowered from >2 to >1 tool calls (production lesson: delegate more aggressively for context preservation), active hours concept, context preservation rationale
- **Security playbook expanded** — Routing rules for group vs DM contexts, observe-only group patterns, passphrase auth refinements, PII protection strengthened
- **Anti-patterns +5**: email-check-via-LLM (moved to system cron), observe-only group violations, context bloat from inline tool calls, trusting sub-agent edits to production services, password management sprawl
- **Memory discipline updated** — Knowledge graph pattern (SQLite entities/facts/relationships), services.yaml + query tools, operational context loader
- **Communication updated** — Results-only policy for groups, observe-only group concept, business identity patterns
- **Templates updated** — HEARTBEAT.md with comprehensive service/cron/lead health checks, TOOLS.md with password management and memory search sections, AGENTS.md with context preservation and active hours
- **Hallucination watchdog** — Added service health checks, expanded command verification
- **Self-heal.sh** — Added memory/OOM checks, log rotation, API gateway health
- **Task queue** — Sanitized example queue, added ROI-based prioritization mention
- **Engineering principles** — "Silence = healthy" rule, email-check cron migration pattern, operational context as data

### v5.0 (2026-03-13)
- **AGENTS.md rewrite** — synced delegation protocol, pipeline auto-processing, sub-agent discipline (maxConcurrent=15), memory infrastructure patterns from production
- **NEW: `restart-gateway.sh`** — safe gateway restart with JSON validation and auto-rollback
- **Anti-patterns +5**: hosting PII on public URLs, public gists with secrets, per-client VPSes, channel inequality, importing skills without comparison
- **Security +5**: Gmail drafts-only rule, never host PII publicly, secret gists by default, skill import rule, hallucination watchdog reference
- **Key principles +6**: delegation protocol, channel parity, Gmail drafts only, no PII hosting, secret gists, skill import rule, centralized gateway
- **Templates updated**: AGENTS.md massively expanded (delegation, pipeline, channel parity, Gmail rule, skill imports, gist security)
- **Scripts updated**: self-heal.sh genericized (stripped private service names), restart-gateway.sh added
- **Self-heal.sh** — now a clean template with customizable service checks (no hardcoded service names)

### v4.0 (2026-03-07)
- Added `scripts/` directory with safety tools
- `self-heal.sh` — auto-remediate disk, gateway, services, memory issues
- `hallucination-watchdog.py` — verify file paths, URLs, env vars, memory consistency
- `checkpoint.sh` — quick git checkpoint with tags
- `backup-system.py` — workspace backup utility

### v3.1 (2026-02-28)
- **NEW: `subagent-orchestration.md`** — fan-out/synthesis, pipeline state, model selection, cost awareness
- **NEW: `web-services.md`** — vanilla JS dashboards, URL-param auth, SSE, systemd, nginx, Playwright
- **Anti-patterns +8**: headless vs Cloudflare, CSS/GSAP conflicts, networkidle hangs, systemd PATH, Bot API webhooks, HEIC speed, C compiler deps, env var typos
- **Error recovery +5**: port conflicts, credit exhaustion, webhook debugging, remote SSH, subagent timeouts
- **Security +3**: API key management, Cloudflare tips, hallucination watchdog
- **Communication +3**: voice messages, social media/Twitter, email outreach
- **Skills manifest v2**: 5 phases, custom skills section, TTS options, himalaya tips
- **Templates updated**: AGENTS.md (cost management), TOOLS.md (expanded sections)
- **Key principles +2**: hallucination watchdog, autonomous pipelines

### v3 (2026-02-27)
- Added `provision/` directory with automated VPS provisioning script
- Added Telegram bot setup guide
- Added SMS/voice channel handling patterns to AGENTS.md template
- Added emergency contact protocol pattern to AGENTS.md template
- Added heartbeat vs cron decision guide
- Updated anti-patterns with subagent code injection, model size failures
- Updated skills manifest with latest recommendations
- Setup script now supports `--provision` flag for full VPS setup

### v2 (2026-02-26)
- Added machine-to-machine efficiency principle to AGENTS.md
- Added pipeline auto-continuation rules
- Added routing rule (reply goes to sender, not human)
- Added cron isolated session tools bug to anti-patterns
- Added free model fallback chain anti-pattern
- Added subagent code injection anti-pattern
- Added secrets-in-git anti-pattern
- Added field name mismatch anti-pattern
- Added overwriting-without-checkpoint anti-pattern
- Added system vs OpenClaw cron guidance
- Added API credit/auth recovery to error-recovery
- Added cron job debugging to error-recovery
- Added restart context pattern to memory-discipline
- Added MEMORY.md security rule (main session only)
- Added channel parity rule to security
- Added emergency contact protocol to security
- Added routing rule to communication
- Updated heartbeat template with tips and memory maintenance

### v1 (2026-02-22)
- Initial release: templates, playbook, setup script, skills manifest
