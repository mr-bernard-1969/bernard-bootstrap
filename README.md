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

## What This Isn't

- Not a copy of Mr. Bernard (you'll build your own persona)
- Not a replacement for OpenClaw itself (you need OpenClaw installed first)
- Not magic — your agent still needs to learn and grow, but it starts from a much better foundation

## Quick Start

### Option A: Manual Setup (You Have a VPS Already)

```bash
git clone https://github.com/<your-username>/bernard-bootstrap.git
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
├── setup.sh                     ← One-shot workspace setup
├── provision/
│   ├── README.md                ← VPS provisioning guide
│   ├── provision-vps.sh         ← Automated VPS setup script
│   └── setup-telegram-bot.md   ← Telegram bot creation guide
├── templates/
│   ├── AGENTS.md                ← Workspace rules, memory habits, efficiency principles
│   ├── SOUL.md                  ← Personality and core values
│   ├── IDENTITY.md              ← Name, backstory, operational persona
│   ├── USER.md                  ← Template for describing your human
│   ├── HEARTBEAT.md             ← Periodic check configuration
│   └── TOOLS.md                 ← Service and integration notes
├── playbook/
│   ├── memory-discipline.md     ← The #1 thing to get right
│   ├── security.md              ← Access control, secrets, public persona
│   ├── communication.md         ← When to speak, when to shut up, routing rules
│   ├── error-recovery.md        ← Gateway, SSH, config, service recovery
│   └── anti-patterns.md         ← Every mistake already made (save yourself the pain)
└── skills/
    └── manifest.md              ← Phased skill installation guide
```

## Key Principles

These are the most important lessons from production:

1. **Write-through memory** — If you learn something, write it to a file immediately. "Mental notes" don't survive restarts.
2. **Machine-to-machine first** — If a task can be a bash script or cron job, don't route it through an LLM. Reserve tokens for judgment calls.
3. **Scripts > LLM for plumbing** — Health checks, file syncs, API calls, notifications = pure scripts. Zero LLM involvement.
4. **System crontab for deterministic tasks** — OpenClaw cron isolated sessions have a known bug where tools may not be provided to models. Use `crontab -e` for anything that doesn't need LLM judgment.
5. **Never auto-harden** — Always propose security changes and get approval. Never lock yourself out.
6. **Fallback within tier** — If your primary API key runs out, fall back to another key on the same provider. Never fall back to free/incapable models.
7. **Checkpoint before iterating** — Git commit before making changes. Tag important versions. Cheap insurance.
8. **Groups see only final output** — No progress updates, no system messages, no errors. Deliver the finished product.

## Changelog

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
