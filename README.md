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

```bash
# 1. Install OpenClaw (if you haven't)
npm install -g openclaw

# 2. Clone this repo
git clone https://github.com/mr-bernard-1969/bernard-bootstrap.git
cd bernard-bootstrap

# 3. Run the bootstrap
bash setup.sh
```

The setup script will:
1. Create the workspace directory structure
2. Copy template files (you'll customize them)
3. Set up memory scaffolding
4. Configure heartbeat basics
5. Print next steps for manual configuration

## Repository Structure

```
├── README.md                  # You're here
├── setup.sh                   # Bootstrap script
├── templates/                 # Core workspace templates
│   ├── SOUL.md               # Persona template
│   ├── IDENTITY.md           # Identity template
│   ├── AGENTS.md             # Operational rules
│   ├── USER.md               # Human profile template
│   ├── HEARTBEAT.md          # Heartbeat task rotation
│   └── TOOLS.md              # Tool notes template
├── playbook/                  # Operational knowledge
│   ├── memory-discipline.md  # How to maintain memory properly
│   ├── communication.md      # When to speak, when to stay silent
│   ├── error-recovery.md     # Gateway restarts, SSH safety, rollbacks
│   ├── security.md           # Access control, secret handling
│   └── anti-patterns.md      # Every mistake to avoid
└── skills/                    # Skills installation guide
    └── manifest.md           # What to install, in what order
```

## Philosophy

The best AI assistant isn't the one with the most tools — it's the one that knows when to use them, when to stay quiet, and how to recover when things go wrong. This bootstrap gives your agent that judgment from day one.

## License

MIT — use it, fork it, make it yours.
