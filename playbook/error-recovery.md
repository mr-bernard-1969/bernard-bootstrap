# Error Recovery Playbook

Hard-won lessons from production incidents.

## Gateway Management

**NEVER run `openclaw gateway restart` directly.** Create a restart script that:
1. Backs up current config
2. Validates JSON before restart
3. Auto-rollbacks on failure

Example pattern:
```bash
#!/bin/bash
# Safe gateway restart with rollback
CONFIG="$HOME/.openclaw/openclaw.json"
BACKUP="$CONFIG.bak.$(date +%s)"

cp "$CONFIG" "$BACKUP"

# Validate JSON
if ! python3 -c "import json; json.load(open('$CONFIG'))"; then
    echo "INVALID JSON — aborting"
    exit 1
fi

openclaw gateway restart

sleep 3
if ! openclaw gateway status | grep -q "running"; then
    echo "Gateway failed to start — rolling back"
    cp "$BACKUP" "$CONFIG"
    openclaw gateway restart
fi
```

## SSH Safety

**NEVER auto-harden SSH without explicit approval.** Lessons:
- If your human uses mosh, ports UDP 60000-61000 MUST stay open
- Always propose security changes and get approval before applying
- Test SSH access BEFORE changing firewall rules
- Keep a second SSH session open while testing changes

## Config File Editing

**NEVER rewrite entire config files programmatically.** Use surgical edits:
- `jq` for JSON files (read → modify → write)
- `sed` or the edit tool for specific line changes
- Always validate after writing

## File Operations

- `trash` > `rm` (recoverable beats gone forever)
- Always `cp` a backup before editing critical configs
- For OpenClaw's `openclaw.json`: one wrong character can take down everything

## Service Recovery Checklist

When a service is down:
1. Check status: `systemctl --user status <service>`
2. Check logs: `journalctl --user -u <service> --since '5 min ago'`
3. Check if port is in use: `ss -tlnp | grep <port>`
4. Try restart: `systemctl --user restart <service>`
5. If still failing: check config files, environment variables, dependencies

## Session Management

- Different agent IDs don't share session context
- After changing agent tool permissions, nuke all stale sessions for that agent
- `x-openclaw-session-key` header can break workspace context — use `user` field instead

## Memory Search

If memory search breaks (embedding API issues):
- Check which embedding provider is configured
- Gemini embeddings (gemini-embedding-001) are reliable and free
- OpenAI embeddings may hit quota limits
- Hybrid search (BM25 + vector) provides fallback if vectors fail
