#!/bin/bash
# self-heal.sh — Auto-remediate common issues before alerting a human
# Runs every 5 min via cron
set -uo pipefail

LOG="/tmp/self-heal.log"
ALERT_SENT=0

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG"; }
alert() {
  log "ALERT: $1"
  if [ "$ALERT_SENT" -lt 3 ]; then
    # Telegram alert to G (fire-and-forget)
    curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d chat_id=39172309 \
      -d text="🔧 Self-heal: $1" >/dev/null 2>&1 || true
    ALERT_SENT=$((ALERT_SENT + 1))
  fi
}

# ── Check 1: Disk space ──
DISK_USED=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USED" -gt 95 ]; then
  log "CRITICAL: Disk at ${DISK_USED}%"
  find /tmp -mtime +3 -delete 2>/dev/null
  find /home/openclaw/.cache -mtime +7 -delete 2>/dev/null
  journalctl --user --vacuum-time=3d 2>/dev/null
  alert "Disk at ${DISK_USED}%, cleaned /tmp and old logs"
elif [ "$DISK_USED" -gt 90 ]; then
  find /tmp -mtime +7 -delete 2>/dev/null
  log "Disk at ${DISK_USED}%, cleaned old /tmp files"
fi

# ── Check 2: OpenClaw gateway ──
if ! systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
  systemctl --user restart openclaw-gateway 2>/dev/null
  sleep 3
  if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
    log "Restarted openclaw-gateway"
  else
    alert "openclaw-gateway restart FAILED"
  fi
fi

# ── Check 3: mrb-sh ──
if ! systemctl --user is-active mrb-sh >/dev/null 2>&1; then
  systemctl --user restart mrb-sh 2>/dev/null
  sleep 2
  if systemctl --user is-active mrb-sh >/dev/null 2>&1; then
    log "Restarted mrb-sh"
  else
    alert "mrb-sh restart FAILED"
  fi
fi

# ── Check 4: API Gateway ──
if systemctl --user is-enabled api-gateway >/dev/null 2>&1; then
  if ! curl -sf http://127.0.0.1:19000/health >/dev/null 2>&1; then
    systemctl --user restart api-gateway 2>/dev/null
    sleep 2
    if curl -sf http://127.0.0.1:19000/health >/dev/null 2>&1; then
      log "Restarted api-gateway"
    else
      alert "api-gateway restart FAILED"
    fi
  fi
fi

# ── Check 5: N-Number tracking ──
if systemctl --user is-enabled n-number-tracking >/dev/null 2>&1; then
  if ! systemctl --user is-active n-number-tracking >/dev/null 2>&1; then
    systemctl --user restart n-number-tracking 2>/dev/null
    log "Restarted n-number-tracking"
  fi
fi

# ── Check 6: Telnyx SMS ──
if ! systemctl --user is-active telnyx-sms >/dev/null 2>&1; then
  systemctl --user restart telnyx-sms 2>/dev/null
  sleep 2
  if systemctl --user is-active telnyx-sms >/dev/null 2>&1; then
    log "Restarted telnyx-sms"
  else
    alert "telnyx-sms restart FAILED"
  fi
fi

# ── Check 7: Log rotation ──
for logfile in /tmp/openclaw/*.log /tmp/self-heal.log /tmp/ai-news-digest.log; do
  if [ -f "$logfile" ] && [ "$(stat -f%z "$logfile" 2>/dev/null || stat -c%s "$logfile" 2>/dev/null)" -gt 104857600 ]; then
    tail -1000 "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
    log "Rotated $logfile (was >100MB)"
  fi
done

# ── Check 8: Memory (OOM prevention) ──
MEM_AVAIL=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
if [ "$MEM_AVAIL" -lt 200 ]; then
  alert "Low memory: ${MEM_AVAIL}MB available"
fi
