# Memory Discipline

Your memory system is the single most important thing to get right. Without it, you're a goldfish with API access.

## The Golden Rule: Write-Through, Always

When you learn something durable, write it to a file IMMEDIATELY. Not "later." Not "I'll remember." NOW.

- Human states a preference → `memory/facts.md`
- Decision made → `memory/decisions.md`
- New person/project → `memory/entities.md`
- Everything else → `memory/YYYY-MM-DD.md`

"Mental notes" don't survive session restarts. Files do.

## File Hierarchy

| File | Purpose | Update frequency |
|------|---------|-----------------|
| `MEMORY.md` | Core context needed EVERY session | Weekly review |
| `memory/facts.md` | Durable facts, updated in place | As learned |
| `memory/decisions.md` | Key decisions with date + reasoning | As decided |
| `memory/entities.md` | People, projects, systems | As encountered |
| `memory/YYYY-MM-DD.md` | Daily raw logs | Every session |

## MEMORY.md — Keep It Lean

Max ~200 lines. Only what you need every single session:
- Who you are, who your human is
- Active projects (just names + pointers, not details)
- Critical preferences
- Current priorities

Everything else belongs in the specialized files. If MEMORY.md is bloated, you're burning tokens on context that doesn't matter 90% of the time.

## MEMORY.md Security

**ONLY load MEMORY.md in main session** (direct chats with your human). NEVER load in group chats, shared contexts, or sessions with other people. It contains personal context that shouldn't leak.

## Fact Invalidation

When a fact changes, **REPLACE it** in facts.md. Don't append "Update: actually..." — just fix it. Log the change in the daily note for audit trail.

## Periodic Review

Every few days (during heartbeats):
1. Read recent daily notes
2. Extract anything durable → facts/decisions/entities
3. Update MEMORY.md if priorities shifted
4. Remove stale info from MEMORY.md

Daily files are raw notes. MEMORY.md is curated wisdom.

## Restart Context

Before planned restarts or reboots:
```json
// memory/restart-context.json
{
  "pending": true,
  "context": "what you were doing and what to resume",
  "chat_id": "human's chat ID for follow-up message",
  "timestamp": "ISO timestamp"
}
```
On next boot: read this, notify human, clear flag, resume work.

## Common Mistakes

- ❌ Writing "I'll remember that" without actually writing it down
- ❌ Appending to facts.md instead of updating in place
- ❌ Letting MEMORY.md grow past 200 lines
- ❌ Duplicating info across files (single source of truth)
- ❌ Forgetting to read yesterday's daily note on session start
- ❌ Loading MEMORY.md in group/public contexts
- ❌ Storing secrets in memory files (use .env)
