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

### Headless browser blocked by Cloudflare
**What happened:** Playwright headless mode was detected and blocked by Cloudflare on our own domain. Screenshots always returned challenge pages.
**Lesson:** Use headed browser with off-screen window position (`--window-position=9999,9999`) + stealth plugin. Or use `http://127.0.0.1:<port>` to bypass Cloudflare entirely for your own services.

### CSS conflicts with GSAP animations
**What happened:** CSS rule `.card-enter { opacity: 0 }` conflicted with GSAP's `gsap.from({opacity: 0})`. Cards were permanently invisible because CSS applied first.
**Lesson:** Don't set initial hidden states in CSS when GSAP controls the animation. Let GSAP own the full lifecycle.

### networkidle hangs with SSE/long-poll
**What happened:** Playwright `waitUntil: 'networkidle'` hung forever on pages with Server-Sent Events.
**Lesson:** Use `domcontentloaded` for pages with persistent connections. `networkidle` requires ALL network activity to stop — SSE never stops.

### systemd PATH doesn't include user bin directories
**What happened:** `openclaw` command not found when called from systemd service.
**Lesson:** Use full paths in systemd scripts: `/home/user/.npm-global/bin/openclaw`. Or set `Environment=PATH=...` in the service file.

### Bot API getUpdates returns 404 with webhooks
**What happened:** Tried `getUpdates` to discover chats, got 404. Bot was in webhook mode.
**Lesson:** When webhooks are active, `getUpdates` is disabled. Use message logs as the primary data source.

### HEIC encoding is extremely slow
**What happened:** Full-resolution HEIC crops took ~60 seconds per crop, blocking the upload pipeline.
**Lesson:** Store crop coordinates in metadata, serve JPEG web crops immediately, defer HEIC generation to background.

### Dependencies requiring C compiler on minimal VPS
**What happened:** `pyroomacoustics` and `audiomentations` failed — no C compiler on VPS.
**Lesson:** Use `scipy` and `numpy` only (ship pre-built wheels). Anything needing compilation must run on a machine with build tools.

### Env var typos are permanent
**What happened:** `X_COMSUMER_SECRET` (missing N) was baked into `.env` and 5+ scripts before anyone noticed.
**Lesson:** Once an env var name is in production across multiple scripts, document the typo rather than fix it everywhere.

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

### `openclaw onboard` fails non-interactively
**What happened:** `openclaw onboard --anthropic-api-key` has an interactive security confirmation prompt that auto-selects "No" in non-TTY. Blocks automated provisioning.
**Lesson:** For automated VPS setup, write the API key to `.env` as `ANTHROPIC_API_KEY=...` and configure the model via `openclaw config set agents.defaults.model.primary`. Skip `onboard`.

### systemd user services unavailable under `su`
**What happened:** `su - openclaw -c 'openclaw gateway start'` failed because systemd user bus isn't available under `su`.
**Lesson:** Use a system-level service (`/etc/systemd/system/`) with `User=openclaw` and `EnvironmentFile` instead. Or enable linger + SSH as the user directly.

### Wrong index.js in node_modules
**What happened:** `find` returned a nested dependency's index.js instead of OpenClaw's entry point.
**Lesson:** The correct entry point is `/usr/lib/node_modules/openclaw/dist/index.js`. Verify with `head -5 /usr/bin/openclaw` which shows the shebang and entry point.
