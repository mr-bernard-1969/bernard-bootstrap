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

## API Credit / Auth Recovery

When API calls start failing:
1. Check if it's a credit/quota issue (look for 402/429 errors in logs)
2. Check auth profile status: `~/.openclaw/agents/<agent>/agent/auth-profiles.json`
3. **Fallback chain must stay within capable providers** — never fall back to free models
4. Auth order matters: put the working key first (e.g., `["backup", "default"]`)
5. Clear any cooldown on exhausted profiles so they auto-recover when credits refill

## Session Management

- Different agent IDs don't share session context
- After changing agent tool permissions, nuke all stale sessions for that agent (stale history teaches the LLM to fake tool use)
- `x-openclaw-session-key` header can break workspace context — use `user` field instead

## Memory Search

If memory search breaks (embedding API issues):
- Check which embedding provider is configured
- Gemini embeddings (gemini-embedding-001) are reliable and free
- OpenAI embeddings may hit quota limits
- QMD (local BM25 + vectors + reranking) is another option
- Hybrid search (BM25 + vector) provides fallback if vectors fail

## Cron Job Failures

If cron jobs run but don't complete their work:
- Check `openclaw cron runs --id <jobId>` — look at output tokens and summary
- If the model outputs text descriptions instead of tool calls: **this is the known cron tools bug**
- Fix: convert the job to a system crontab script (pure bash, no LLM)
- For jobs that genuinely need LLM: add "You MUST use the exec tool" to the prompt

## Restart Context

Before planned restarts/reboots:
1. Write `memory/restart-context.json` with `{"pending": true, "context": "what to resume", "chat_id": "..."}`
2. Commit and push to git
3. On next boot, read the file, notify human, clear flag, resume work

## Subagent Failures

When subagents break things (e.g., editing server files with invalid syntax):
- Always review subagent changes to production services before restarting
- Keep subagent work isolated to tmp/workspace files when possible
- If a subagent crashes a service, check `git diff` or recent file modifications
