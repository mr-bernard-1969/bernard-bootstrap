# HEARTBEAT.md

## Every heartbeat
- Check memory/heartbeat-state.json for last check times
- If any background task finished, summarize results

## Rotation (pick based on staleness)
- **Inbox scan** — urgent unread messages?
- **Calendar** — upcoming events in next 24-48h?
- **Memory review** — if >2 days since last: read recent daily notes, extract durable info
- **Workspace git** — if uncommitted changes, auto-commit and push

## Rules
- Late night (23:00-08:00 local): HEARTBEAT_OK unless urgent
- Don't reach out unless something actually matters
- Update heartbeat-state.json after each check
