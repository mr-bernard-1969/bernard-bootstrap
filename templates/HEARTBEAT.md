# HEARTBEAT.md — Periodic Health Checks

## Every Heartbeat
- Check `memory/heartbeat-state.json` for last check times
- If any background task finished, summarize results

## Service Health
Quick port checks on critical services:
```bash
# Customize with your own service ports
for port_name in 18789:Gateway; do
    p=$(echo $port_name | cut -d: -f1)
    name=$(echo $port_name | cut -d: -f2)
    if ! nc -z 127.0.0.1 $p 2>/dev/null; then
        echo "⚠️ $name (port $p) is DOWN"
    fi
done
```

## Cron Health
Check recent cron logs for errors:
```bash
for log in /tmp/self-heal.log; do
    if [ -f "$log" ]; then
        errors=$(tail -5 "$log" | grep -iE "error|fail|traceback" | wc -l)
        if [ $errors -gt 0 ]; then
            echo "⚠️ $(basename $log): $errors error(s) in last 5 lines"
        fi
    fi
done
```

## Task Queue
Check for overdue or high-priority tasks:
```bash
python3 tasks/add.py list
```

## Rotation (pick based on staleness)
- **Inbox scan** — urgent unread messages?
- **Calendar** — upcoming events in next 24-48h?
- **Memory review** — if >2 days since last: read recent daily notes, extract durable info
- **Workspace git** — if uncommitted changes, auto-commit and push

## Rules
- Late night (23:00-08:00 local): HEARTBEAT_OK unless urgent
- Don't reach out unless something actually matters
- **Silence = healthy** — if everything is fine, say nothing
- Update heartbeat-state.json after each check

## Tips
- Batch similar periodic checks into heartbeats instead of creating multiple cron jobs
- Use cron for precise schedules and standalone tasks
- Track check timestamps in `memory/heartbeat-state.json`:
  ```json
  {"lastChecks": {"email": 1703275200, "calendar": 1703260800}}
  ```
- Periodically (every few days) use a heartbeat for memory maintenance:
  review recent daily notes, extract durable info, update MEMORY.md, prune stale entries
- Add your own service ports to the health check as you deploy services
