#!/bin/bash
# self-heal.sh — Auto-remediate common issues before alerting a human
# Runs every 5 min via cron: */5 * * * * bash ~/bernard-bootstrap/scripts/self-heal.sh
set -uo pipefail

LOG="/tmp/self-heal.log"
ALERT_SENT=0

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG"; }
alert() {
  log "ALERT: $1"
  if [ "$ALERT_SENT" -lt 3 ]; then
    # Send alert via your preferred channel (Telegram example below)
    # Replace TELEGRAM_BOT_TOKEN and CHAT_ID with your values
    # curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    #   -d chat_id="${OWNER_CHAT_ID}" \
    #   -d text="🔧 Self-heal: $1" >/dev/null 2>&1 || true
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

# ── Check 3: Custom services (add your own) ──
# Uncomment and customize for your services:
# SERVICES=("my-web-app" "my-api-service")
# for svc in "${SERVICES[@]}"; do
#   if ! systemctl --user is-active "$svc" >/dev/null 2>&1; then
#     systemctl --user restart "$svc" 2>/dev/null
#     sleep 2
#     if systemctl --user is-active "$svc" >/dev/null 2>&1; then
#       log "Restarted $svc"
#     else
#       alert "$svc restart FAILED"
#     fi
#   fi
# done

# ── Check 4: API Gateway health (if running) ──
# Uncomment if you run a centralized API gateway:
# API_GW_PORT=19000
# if systemctl --user is-enabled api-gateway >/dev/null 2>&1; then
#   if ! curl -sf "http://127.0.0.1:${API_GW_PORT}/health" >/dev/null 2>&1; then
#     systemctl --user restart api-gateway 2>/dev/null
#     sleep 2
#     if curl -sf "http://127.0.0.1:${API_GW_PORT}/health" >/dev/null 2>&1; then
#       log "Restarted api-gateway"
#     else
#       alert "api-gateway restart FAILED"
#     fi
#   fi
# fi

# ── Check 5: Log rotation ──
for logfile in /tmp/openclaw/*.log /tmp/self-heal.log; do
  if [ -f "$logfile" ] && [ "$(stat -c%s "$logfile" 2>/dev/null || echo 0)" -gt 104857600 ]; then
    tail -1000 "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
    log "Rotated $logfile (was >100MB)"
  fi
done

# ── Check 6: Memory (OOM prevention) ──
if [ -f /proc/meminfo ]; then
  MEM_AVAIL=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
  if [ "$MEM_AVAIL" -lt 200 ]; then
    alert "Low memory: ${MEM_AVAIL}MB available"
  fi
fi
