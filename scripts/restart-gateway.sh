#!/bin/bash
# restart-gateway.sh — Safe gateway restart with config validation and rollback
# Usage: bash scripts/restart-gateway.sh "reason for restart"
#
# ALWAYS use this instead of bare `systemctl restart` or `openclaw gateway restart`.
# This validates config, backs up, and auto-rolls back on failure.
set -uo pipefail

REASON="${1:-manual restart}"
CONFIG="$HOME/.openclaw/openclaw.json"
BACKUP="$CONFIG.bak.$(date +%s)"
LOG="/tmp/gateway-restart.log"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }

log "Gateway restart requested: $REASON"

# 1. Validate JSON config before doing anything
if ! python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
  log "ABORT: openclaw.json is INVALID JSON — not restarting"
  exit 1
fi
log "Config JSON validated ✓"

# 2. Backup current config
cp "$CONFIG" "$BACKUP"
log "Config backed up to $BACKUP"

# 3. Restart gateway
openclaw gateway restart 2>&1 | tee -a "$LOG"

# 4. Wait and verify
sleep 5
if openclaw gateway status 2>/dev/null | grep -qi "running\|active"; then
  log "Gateway restarted successfully ✓"
  # Clean up old backups (keep last 5)
  ls -t "$CONFIG".bak.* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
else
  log "Gateway FAILED to start — rolling back config"
  cp "$BACKUP" "$CONFIG"
  openclaw gateway restart 2>&1 | tee -a "$LOG"
  sleep 3
  if openclaw gateway status 2>/dev/null | grep -qi "running\|active"; then
    log "Rollback successful — gateway running with previous config"
  else
    log "CRITICAL: Gateway won't start even with rollback config!"
    log "Manual intervention required."
    exit 2
  fi
fi
