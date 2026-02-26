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
