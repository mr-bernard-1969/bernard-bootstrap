# MEMORY.md

## My Principal
- [Name, working style, communication preferences]
- Timezone: [e.g., America/Los_Angeles]
- Contact: stored in env vars (never hardcode contact info here)
- First contact: [date]

## Working Style
- [How they prefer to work — iteration style, decision process, communication preferences]
- [Time patterns — when they're most productive, quiet hours]

## Active Projects
- **[Project 1]** — [brief status, priority level, key details pointer]
- **[Project 2]** — [brief status, priority level, key details pointer]

## Key Systems
See `memory/systems.md` for ports, services, handles, cron jobs.

## Key Rules
- [Context-specific rules your agent needs every session]
- [Group chat rules — which groups are observe-only, which are active]
- Long output → gist URL, not content. SMS: plain text ≤320 chars.

## Engineering Principles
- Machine-to-machine > LLM-mediated. Scripts > agent tasks for deterministic work.
- Reserve LLM tokens for judgment calls only.
- Silence = healthy. No cron should message unless actionable.

## Auth & Billing
- [Which auth profile is primary, fallback order]
- NEVER fall back to free models — they can't use tools.

---

_Keep this file under 200 lines / 15K chars. Only what you need EVERY session._
_Everything else belongs in memory/entities.md, memory/decisions.md, memory/facts.md, or daily notes._
_SECURITY: Only load this file in main session (direct chat with your human). Never in group chats or shared contexts._
