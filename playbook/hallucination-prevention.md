# Hallucination Prevention Playbook

## Why AI Agent Docs Drift from Reality

AI agents face a unique challenge: **documentation becomes outdated in real-time** as systems change faster than memory updates. This creates a dangerous gap where the agent's beliefs (in MEMORY.md, TOOLS.md, etc.) diverge from ground truth.

Common causes:
- **API changes** — endpoints deprecated, keys rotated, services moved
- **File reorganization** — paths change, files deleted/renamed
- **Service churn** — new services added, old ones stopped
- **Memory compaction** — details lost during summarization
- **Optimistic assumptions** — "this should work" becomes "this works" in memory

The result: hallucinated facts that compound over time. An agent confidently references tools that don't exist, files that were deleted, or APIs that changed months ago.

## The 7 Check Dimensions

The hallucination watchdog (`scripts/hallucination-watchdog.py`) verifies agent beliefs against reality across 7 dimensions:

### 1. Twitter Handles
**What:** Resolve all @handles mentioned in watchlists and memory  
**Why:** Hallucinated usernames break automation, waste API calls  
**How:** X API user lookup for each handle  
**Red flags:** 404 errors, suspended accounts, renamed users

### 2. File References
**What:** Verify all file paths mentioned in docs exist on disk  
**Why:** Broken paths cause silent failures in scripts  
**How:** Scan .md files for paths, check with `os.path.exists()`  
**Filters:** Skip old daily notes, audit reports, upstream docs  
**Red flags:** Missing config files, deleted scripts, moved directories

### 3. Environment Variables
**What:** Cross-reference `*_KEY`, `*_TOKEN`, `*_SECRET` mentions against `.env`  
**Why:** Missing keys break integrations at runtime  
**How:** Regex scan docs, compare to actual `.env` contents  
**Filters:** Skip upstream docs, script-local vars, examples  
**Red flags:** Documented keys not in `.env`, typos in var names

### 4. Memory Consistency
**What:** Detect bloat and duplication across memory files  
**Why:** Large MEMORY.md slows every session, duplicates confuse the agent  
**How:** Line count MEMORY.md (target ~200), hash chunks to find exact duplicates  
**Red flags:** >250 lines in MEMORY.md, identical blocks in multiple files

### 5. URL Reachability
**What:** HEAD requests to URLs in MEMORY.md and TOOLS.md  
**Why:** Dead links waste time, broken webhooks fail silently  
**How:** HTTP HEAD with 3s timeout  
**Filters:** Skip POST-only endpoints (e.g., Lob API)  
**Red flags:** 404s, connection timeouts, SSL errors

### 6. Command Availability
**What:** Verify CLI tools mentioned in TOOLS.md exist in PATH  
**Why:** Missing binaries cause script failures  
**How:** `which <command>` for each referenced tool  
**Red flags:** Missing CLIs (gh, himalaya, ffmpeg, etc.)

### 7. Service Health
**What:** Check systemd services mentioned in TOOLS.md are running  
**Why:** Down services mean broken integrations  
**How:** `systemctl is-active <service>` for each  
**Red flags:** Inactive/failed services that should be running

## Recovery Procedures

When the watchdog flags issues:

### Critical Issues (Exit Code 2)
- **Stop all automation** — don't compound errors
- **Fix immediately** — restore missing files, restart services, update keys
- **Re-run watchdog** to confirm resolution
- **Update memory** to reflect new ground truth

### Warnings (Exit Code 1)
- **Triage** — assess impact (is this breaking anything now?)
- **Schedule fix** — add to task queue if not urgent
- **Monitor** — check if it resolves itself (e.g., temporary service restart)

### Common Fixes
- **Missing file:** Restore from backup or recreate, update docs
- **Dead URL:** Update to new endpoint or remove if obsolete
- **Missing env var:** Rotate key, add to `.env`, restart services
- **Stale memory:** Archive to entities/decisions, trim MEMORY.md
- **Down service:** `systemctl --user restart <service>`, check logs

## Designing Self-Verifying Workflows

Build verification into your automation:

### 1. Pre-Flight Checks
Before running critical operations:
```python
# Check dependencies exist
assert shutil.which('ffmpeg'), "ffmpeg not installed"
assert Path('~/.openclaw/.env').exists(), "env file missing"

# Verify credentials loaded
assert os.getenv('API_KEY'), "API_KEY not set"
```

### 2. Post-Action Verification
After making changes:
```python
# Create file → verify it exists
Path('output.json').write_text(data)
assert Path('output.json').exists(), "write failed"

# Call API → verify response
resp = requests.post(url, data=payload)
assert resp.status_code == 200, f"API error: {resp.status_code}"
```

### 3. Idempotency
Make operations safe to retry:
```python
# Safe: check before creating
if not Path('output.json').exists():
    process_data()

# Unsafe: blindly append
with open('log.txt', 'a') as f:  # could duplicate on retry
    f.write(entry)
```

### 4. Graceful Degradation
Handle missing dependencies:
```python
try:
    import fancy_lib
    use_fancy_method()
except ImportError:
    use_fallback_method()
```

### 5. State Tracking
Record what you've done:
```json
{
  "last_run": "2026-03-07T13:32:00Z",
  "processed": ["file1.txt", "file2.txt"],
  "errors": []
}
```

Then check state before acting:
```python
state = load_state()
if file not in state['processed']:
    process_file(file)
    state['processed'].append(file)
    save_state(state)
```

### 6. Automated Watchdog
Run checks on a schedule:
```cron
0 6 * * * python3 ~/.openclaw/workspace/scripts/hallucination-watchdog.py --full >> /tmp/watchdog.log 2>&1
```

Send alerts on failure:
```bash
if [ $? -eq 2 ]; then
    # Critical failure, notify immediately
    bash scripts/emergency-contact.sh sms "Watchdog: critical issues detected"
fi
```

## Best Practices

1. **Trust but verify** — assume docs are stale, check ground truth
2. **Small surface area** — fewer dependencies = fewer drift points
3. **Explicit over implicit** — state assumptions in code/docs
4. **Fail fast** — crash on inconsistency rather than hallucinate
5. **Version everything** — git commits are your time machine
6. **Checkpoint often** — `bash scripts/checkpoint.sh "before risky change"`
7. **Read before edit** — never guess at file contents or anchor text
8. **Log aggressively** — future you will thank present you
9. **Automate verification** — cron the watchdog, script the checks
10. **Update memory immediately** — don't defer to "later"

## Red Flags (Human Check Required)

Some drift is too subtle for automated checks:

- Agent confidently citing sources it can't access
- Repeating outdated information from compacted memory
- Claiming tools/features that were deprecated
- Mixing up similar-sounding services/endpoints
- Using stale pricing/quotas for external APIs
- Referencing people/projects no longer active

When you see these patterns: **pause, verify, update docs, checkpoint.**

---

**Remember:** Hallucinations aren't lying. They're the agent's honest belief based on incomplete information. Your job is to keep that information accurate.
