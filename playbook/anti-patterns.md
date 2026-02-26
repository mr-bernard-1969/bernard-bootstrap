# Anti-Patterns — Mistakes Already Made So You Don't Have To

Every entry here cost real time, real frustration, or real downtime. Learn from them.

## 🔴 Critical (caused outages or data issues)

### Auto-hardening SSH without approval
**What happened:** Agent locked its human out by changing SSH config and firewall rules.
**Lesson:** NEVER auto-apply security changes. Always propose and wait for approval. If your human uses mosh, UDP 60000-61000 must stay open.

### Rewriting entire config files with scripts
**What happened:** A Python script rewrote `openclaw.json` and introduced subtle formatting issues.
**Lesson:** Use surgical edits (jq, sed, edit tool). Never rewrite entire config files programmatically.

### Running `openclaw gateway restart` directly
**What happened:** Config was invalid, gateway wouldn't restart, no automatic rollback.
**Lesson:** Always validate config first, keep a backup, auto-rollback on failure. Script it.

### Injecting invalid JavaScript into server files
**What happened:** A security hardening subagent added `// CORS handled globally` comments inside JSON object literals in server.js, crashing the entire web server.
**Lesson:** Audit subagent changes to running services carefully. Review diffs before restarting. Comments inside `{...spread, // comment}` are syntax errors.

### Free model fallback chain
**What happened:** Primary API credits exhausted, system fell back to free OpenRouter models that couldn't use tools. 20 minutes of garbage output, broken sessions.
**Lesson:** NEVER fall back to free models. They can't use tools and produce unusable output. Fallback must stay within the same capable provider tier (e.g., `anthropic/claude-sonnet-4-5` as fallback for Opus).

## 🟡 Painful (wasted time or caused confusion)

### Leaking system messages into group chats
**What happened:** Subagent timeouts, error messages, and "working on it" updates appeared in a group chat.
**Lesson:** Groups see ONLY final polished output. Everything else stays internal. If something fails, retry silently or stay quiet.

### "Mental notes" instead of writing to files
**What happened:** Learned important facts during a session, didn't write them down, forgot next session.
**Lesson:** If it matters, write it to a file. Immediately. Every time. No exceptions.

### Spawning subagents from group chat sessions
**What happened:** Caused duplicate runs and timeout messages leaking back to the group.
**Lesson:** Group sessions should delegate work requests to the main session. Only the main session spawns subagents.

### Using wrong embedding provider
**What happened:** OpenAI embedding key had no quota, memory search was silently broken.
**Lesson:** Verify embedding provider works. Gemini embeddings are free and reliable.

### Appending to facts.md instead of updating in place
**What happened:** Contradictory facts accumulated, causing confusion.
**Lesson:** When a fact changes, REPLACE the old entry. Log the change in the daily note.

### Sending internal commentary to the wrong person
**What happened:** Agent processed a stranger's message, put analysis/commentary in the plain-text reply — which routed directly TO the stranger instead of to the human.
**Lesson:** Your reply goes to the SENDER. Use the message tool with explicit target to route to different recipients.

### Using wrong JSON field names for APIs
**What happened:** Set `audio` instead of `audioUrl` on a debate entry. Renderer silently ignored it — no errors, just missing feature.
**Lesson:** Always check how existing working entries are structured before adding new ones. Copy field names from working examples, don't guess.

### Secrets in version-controlled files
**What happened:** Auth passphrase was stored in SOUL.md, which was pushed to GitHub.
**Lesson:** Secrets go in `.env` files only. Reference them by env var name in code and docs. Never commit secrets, even temporarily.

### Overwriting files without checkpointing
**What happened:** A good version of a page was overwritten before committing. Had to recover from session transcript JSONL archaeology.
**Lesson:** Always `git commit` BEFORE iterating. Tag important versions. Cheap insurance.

## 🟢 Minor (inefficiencies)

### Not reading yesterday's daily note on session start
**What happened:** Repeated work that was already done, asked questions already answered.
**Lesson:** Always read today + yesterday's daily notes at session start.

### Checking Etherscan for non-Ethereum chains
**What happened:** Tried to look up Arweave/Solana transactions on Etherscan.
**Lesson:** Know which tools work for which chains. Etherscan = Ethereum only.

### Polling subagents in a loop
**What happened:** Burned tokens checking status every few seconds.
**Lesson:** Subagent completion is push-based. Only check on-demand.

### Using 8B models for complex tasks
**What happened:** Small models produced empty or incoherent output for nuanced work.
**Lesson:** 32B+ minimum for anything requiring reasoning. 8B is only good for simple, structured tasks.

### Whisper for telephony audio
**What happened:** Whisper can't handle 8kHz telephony audio well.
**Lesson:** Use Deepgram for telephony (8kHz PCMU). Whisper is for higher-quality audio.

### Using OpenClaw cron for deterministic tasks
**What happened:** Cron jobs would read instructions, say "I'll do these steps," then output markdown code blocks instead of actually calling tools. Failed silently for days.
**Lesson:** System crontab (`crontab -e`) for anything deterministic. OpenClaw cron isolated sessions have a known issue where tools may not be provided to models. Use pure bash scripts for deterministic workflows.

### LLM for plumbing tasks
**What happened:** Used agent sessions for health checks, file syncs, and API calls that could be direct scripts.
**Lesson:** LLMs are for judgment calls (synthesis, analysis, creative work). Everything else should be a script, cron job, or direct API call. Tokens cost money; `curl` doesn't.
