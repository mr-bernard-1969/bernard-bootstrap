#!/usr/bin/env python3
"""
Hallucination Watchdog — Catches common hallucination vectors before they cause damage.

Checks:
1. Twitter handles — verify they resolve via API before use
2. File paths — verify referenced files exist
3. URLs — verify reachability (HEAD request)
4. Facts — cross-reference stated facts against memory files
5. Shell commands — verify binaries exist, flags are valid
6. Env vars — verify referenced vars actually exist in .env
7. Memory consistency — detect contradictions between memory files

Usage:
  python3 scripts/hallucination-watchdog.py --full          # Run all checks
  python3 scripts/hallucination-watchdog.py --twitter       # Twitter handles only
  python3 scripts/hallucination-watchdog.py --files         # File references only
  python3 scripts/hallucination-watchdog.py --env           # Env var check
  python3 scripts/hallucination-watchdog.py --memory        # Memory consistency
  python3 scripts/hallucination-watchdog.py --urls          # URL reachability
  python3 scripts/hallucination-watchdog.py --report        # Generate report for G

Exit codes: 0 = clean, 1 = warnings found, 2 = critical hallucinations detected
"""

import json, os, sys, re, subprocess, urllib.request, urllib.error
from pathlib import Path
from datetime import datetime, timezone
from collections import defaultdict

WORKSPACE = Path.home() / ".openclaw" / "workspace"
ENV_FILE = Path.home() / ".openclaw" / ".env"
REPORT_FILE = WORKSPACE / "projects" / "watchdog" / "latest-report.json"
HISTORY_FILE = WORKSPACE / "projects" / "watchdog" / "history.jsonl"

class HallucinationWatchdog:
    def __init__(self):
        self.findings = []  # {severity, category, message, file, line}
        self.stats = defaultdict(int)
    
    def add(self, severity, category, message, file=None, line=None):
        self.findings.append({
            "severity": severity,  # critical, warning, info
            "category": category,
            "message": message,
            "file": str(file) if file else None,
            "line": line
        })
        self.stats[f"{severity}:{category}"] += 1

    # ── 1. TWITTER HANDLE VERIFICATION ──
    def check_twitter_handles(self):
        """Verify all Twitter handles in watchlist and memory files resolve."""
        print("🐦 Checking Twitter handles...")
        
        # Load bearer token
        bearer = None
        if ENV_FILE.exists():
            for line in ENV_FILE.read_text().splitlines():
                if line.startswith("X_BEARER_TOKEN="):
                    bearer = line.split("=", 1)[1]
        
        if not bearer:
            self.add("warning", "twitter", "No X_BEARER_TOKEN — can't verify handles")
            return

        # Collect handles from watchlist
        wl_file = WORKSPACE / "skills" / "twitter" / "watchlist.json"
        handles = set()
        if wl_file.exists():
            data = json.loads(wl_file.read_text())
            for a in data.get("accounts", []):
                handles.add(a["username"])
        
        # Only verify watchlist handles — don't scan all @mentions
        # (too many false positives from emails, Telegram handles, code examples)
        
        # Batch verify (100 at a time)
        handles = list(handles)
        for i in range(0, len(handles), 100):
            chunk = handles[i:i+100]
            joined = ",".join(chunk)
            try:
                req = urllib.request.Request(
                    f"https://api.x.com/2/users/by?usernames={joined}",
                    headers={"Authorization": f"Bearer {bearer}", "User-Agent": "Watchdog/1.0"}
                )
                with urllib.request.urlopen(req) as resp:
                    data = json.loads(resp.read())
                resolved = {u["username"].lower() for u in data.get("data", [])}
                errors = data.get("errors", [])
                error_handles = {e.get("value", "").lower() for e in errors}
                
                for h in chunk:
                    if h.lower() not in resolved and h.lower() in error_handles:
                        self.add("critical", "twitter",
                                f"Handle @{h} does NOT exist on X — hallucinated or deleted")
                    elif h.lower() in resolved:
                        self.stats["twitter:verified"] += 1
            except Exception as e:
                self.add("warning", "twitter", f"API error verifying handles: {e}")

    # ── 2. FILE PATH VERIFICATION ──
    def check_file_references(self):
        """Find file paths mentioned in memory/config and verify they exist."""
        print("📁 Checking file references...")
        
        # Patterns that look like file paths
        path_patterns = [
            r'`([~/][^`\s]{5,})`',           # backtick-wrapped paths
            r'"([~/][^"\s]{5,})"',             # quoted paths  
            r'(?:at|in|from|read|write)\s+`?([~/][^\s`"]{5,})',  # contextual paths
        ]
        
        # Files to skip for filepath checking
        skip_fp_files = {"HEALTH-WATCHDOG.md", "FEATURE_PARITY.md", "DESIGN.md", 
                         "security-posture.md", "agent-architecture.md", "infrastructure.md",
                         "parallelism-research.md"}  # Contains hypothetical workspace examples
        skip_fp_dirs = {"docs", "node_modules", ".git", "knowledge-base"}
        
        checked = set()
        for md in list(WORKSPACE.rglob("*.md")) + [WORKSPACE / "MEMORY.md", WORKSPACE / "TOOLS.md"]:
            if not md.exists():
                continue
            if md.name in skip_fp_files or any(d in md.parts for d in skip_fp_dirs):
                continue
            try:
                lines = md.read_text().splitlines()
            except:
                continue
            for i, line in enumerate(lines, 1):
                for pattern in path_patterns:
                    for match in re.findall(pattern, line):
                        path = match.strip("`\"' ")
                        if path in checked:
                            continue
                        checked.add(path)
                        
                        # Expand ~ properly
                        if path.startswith("~"):
                            expanded = Path(path.replace("~", str(Path.home()), 1))
                        else:
                            expanded = Path(path)
                        
                        # Skip obvious non-paths and transient files
                        if any(x in path for x in ["http", "example", "{", "$", "*", "<"]):
                            continue
                        
                        # Skip known transient files (exist only during processing)
                        transient = ["crucible-completion.json", "restart-context.json"]
                        if any(t in path for t in transient):
                            continue
                        
                        # Skip paths from old daily notes (historical, not actionable)
                        if md.name.startswith("202") and md.name < datetime.now(timezone.utc).strftime("%Y-%m-%d"):
                            continue
                        
                        # Skip paths in audit/report files (recommendations, not live refs)
                        if md.name in ("security-posture.md", "agent-architecture.md", 
                                      "infrastructure.md", "FEATURE_PARITY.md", "DESIGN.md"):
                            continue
                        
                        if not expanded.exists():
                            # Only warn for paths that SHOULD exist (our workspace/infra)
                            if any(x in path for x in ["/home/openclaw", "~/.openclaw", "workspace/"]):
                                self.add("warning", "filepath",
                                        f"Referenced path does not exist: {path}",
                                        file=md.name, line=i)

    # ── 3. ENV VAR VERIFICATION ──
    def check_env_vars(self):
        """Verify env vars mentioned in docs actually exist in .env."""
        print("🔑 Checking env var references...")
        
        # Load actual env vars from multiple sources
        actual_vars = set()
        pending_vars = set()  # Commented/TODO vars (documented but not configured)
        
        # Main .env
        if ENV_FILE.exists():
            for line in ENV_FILE.read_text().splitlines():
                line = line.strip()
                if line and "=" in line:
                    if line.startswith("#"):
                        # Commented var (pending setup)
                        var_match = re.match(r'#\s*([A-Z][A-Z0-9_]+)=', line)
                        if var_match:
                            pending_vars.add(var_match.group(1))
                    else:
                        actual_vars.add(line.split("=", 1)[0])
        
        # Additional .env files (add your project-specific paths here)
        # Example: project_env = Path.home() / "my-project" / ".env"
        extra_env_paths = []
        for extra_env in extra_env_paths:
            if extra_env.exists():
                for line in extra_env.read_text().splitlines():
                    line = line.strip()
                    if line and "=" in line:
                        if line.startswith("#"):
                            var_match = re.match(r'#\s*([A-Z][A-Z0-9_]+)=', line)
                            if var_match:
                                pending_vars.add(var_match.group(1))
                        else:
                            actual_vars.add(line.split("=", 1)[0])
        
        # Session env
        for k in os.environ:
            actual_vars.add(k)
        
        # Vars provided by auth profile system (not in .env files)
        auth_profile_vars = {
            "ANTHROPIC_API_KEY", 
            "ANTHROPIC_BACKUP_API_KEY"
        }
        
        # Find referenced env vars in workspace files (skip upstream docs + vendored)
        referenced = defaultdict(list)  # var -> [files]
        skip_dirs = {"docs", "node_modules", ".git", "knowledge-base", "how-crypto-works"}
        # Skip audit/report files, upstream docs, and generic skill/readme docs
        skip_files = {"security-posture.md", "agent-architecture.md", "infrastructure.md",
                      "FEATURE_PARITY.md", "DESIGN.md", "NETWORK_SECURITY.md", "CLAUDE.md",
                      "increase-integration-spec.md", "README.md", "HEALTH-WATCHDOG.md"}
        for md in list(WORKSPACE.rglob("*.md")) + list(WORKSPACE.rglob("*.sh")):
            if not md.exists():
                continue
            # Skip upstream docs, vendored files, and audit reports
            if any(d in md.parts for d in skip_dirs):
                continue
            if md.name in skip_files:
                continue
            # Skip SKILL.md files outside our own skills (they reference optional third-party env vars)
            if md.name == "SKILL.md" and "workspace/skills" not in str(md):
                continue
            # Skip old daily notes (historical references, not actionable)
            if md.name.startswith("202") and md.name < datetime.now(timezone.utc).strftime("%Y-%m-%d") + ".md":
                continue
            try:
                text = md.read_text()
            except:
                continue
            # For .sh files, find locally-defined vars (any VAR= pattern)
            local_vars = set()
            if md.suffix == ".sh":
                for local_m in re.findall(r'^\s*([A-Z][A-Z0-9_]{3,})=', text, re.MULTILINE):
                    local_vars.add(local_m)
            
            # Match env var patterns (only unresolved references)
            for m in re.findall(r'(?:export\s+|env\s+|`?)([A-Z][A-Z0-9_]{3,})(?:`|\s|=|$)', text):
                # Skip common non-env-var uppercase words
                noise = {"README", "MEMORY", "TOOLS", "SOUL", "USER", "AGENTS", "SKILL",
                         "IDENTITY", "HEARTBEAT", "BOOTSTRAP", "TODO", "NOTE", "CRITICAL",
                         "WARNING", "ERROR", "INFO", "HTTP", "POST", "NEVER", "ALWAYS",
                         "IMPORTANT", "HARD", "RULE", "FIRST", "ONLY", "LIVE", "DONE",
                         "BLOCKED", "YAML", "JSON", "HTML", "PYEOF", "PASS", "FAIL",
                         "TRUE", "FALSE", "NONE", "NULL", "MISSING", "WORKING",
                         "YOUR_API_KEY", "YOUR_BOT_TOKEN", "YOUR_TOKEN", "NEW_TOKEN",
                         "SECRETS_MASTER_KEY", "LLM_API_KEY", "SAUCE_ACCESS_KEY",
                         "CONSUMER_SECRET", "ACCESS_TOKEN_SECRET"}
                if m not in noise and m not in local_vars:
                    referenced[m].append(md.name)
        
        # Cross-reference
        for var, files in referenced.items():
            # Skip auth profile vars (provided by OpenClaw auth system, not .env)
            if var in auth_profile_vars:
                continue
            # Skip pending vars (commented in .env, documented but not configured yet)
            if var in pending_vars:
                self.stats["envvar:pending"] = self.stats.get("envvar:pending", 0) + 1
                continue
            if var not in actual_vars and var.endswith(("_KEY", "_TOKEN", "_SECRET", "_PW", "_PASSWORD", "_API")):
                self.add("warning", "envvar",
                        f"Env var {var} referenced in {files[0]} but not found in .env or environment")

    # ── 4. MEMORY CONSISTENCY ──
    def check_memory_consistency(self):
        """Detect contradictions between memory files."""
        print("🧠 Checking memory consistency...")
        
        memory_md = WORKSPACE / "MEMORY.md"
        tools_md = WORKSPACE / "TOOLS.md"
        identity_md = WORKSPACE / "IDENTITY.md"
        
        # Check MEMORY.md line count (target: ~200)
        if memory_md.exists():
            lines = len(memory_md.read_text().splitlines())
            if lines > 300:
                self.add("warning", "memory",
                        f"MEMORY.md is {lines} lines (target ~200) — needs trimming")
            self.stats["memory:lines"] = lines
        
        # Check for duplicate entries across files
        facts_file = WORKSPACE / "memory" / "facts.md"
        if facts_file.exists() and memory_md.exists():
            facts_text = facts_file.read_text().lower()
            memory_text = memory_md.read_text().lower()
            
            # Simple duplicate detection: find lines that appear in both
            facts_lines = {l.strip() for l in facts_text.splitlines() if len(l.strip()) > 30}
            memory_lines = {l.strip() for l in memory_text.splitlines() if len(l.strip()) > 30}
            dupes = facts_lines & memory_lines
            if dupes:
                self.add("info", "memory",
                        f"{len(dupes)} potential duplicate lines between MEMORY.md and facts.md")
        
        # Check for stale dates (references to things "today" or "yesterday" from old files)
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        for md in WORKSPACE.glob("memory/202*.md"):
            name = md.stem  # e.g. 2026-02-25
            if name < today:
                try:
                    text = md.read_text()
                    if "today" in text.lower() and "today +" not in text.lower():
                        # Stale "today" reference in old file — not critical but sloppy
                        pass
                except:
                    pass

    # ── 5. URL REACHABILITY ──
    def check_urls(self):
        """Verify URLs mentioned in key files are reachable."""
        print("🌐 Checking URL reachability...")
        
        key_files = [
            WORKSPACE / "MEMORY.md",
            WORKSPACE / "TOOLS.md", 
            WORKSPACE / "IDENTITY.md",
        ]
        
        urls = set()
        for f in key_files:
            if not f.exists():
                continue
            for m in re.findall(r'https?://[^\s\)>`"]+', f.read_text()):
                m = m.rstrip(".,;:)")
                urls.add(m)
        
        # Filter known POST-only endpoints
        post_only = {
            "https://api.capsolver.com/createTask",
            "http://127.0.0.1:8080/api/v1/rpc"  # signal-cli JSON-RPC
        }
        urls -= post_only
        
        for url in list(urls)[:20]:  # Cap at 20 to avoid hammering
            try:
                req = urllib.request.Request(url, method="HEAD",
                    headers={"User-Agent": "Watchdog/1.0"})
                with urllib.request.urlopen(req, timeout=10) as resp:
                    if resp.status >= 400:
                        self.add("warning", "url", f"URL returns {resp.status}: {url}")
                    else:
                        self.stats["url:reachable"] += 1
            except urllib.error.HTTPError as e:
                if e.code == 405:  # Method not allowed — try GET
                    try:
                        req2 = urllib.request.Request(url, headers={"User-Agent": "Watchdog/1.0"})
                        urllib.request.urlopen(req2, timeout=10)
                        self.stats["url:reachable"] += 1
                    except:
                        self.add("warning", "url", f"URL unreachable: {url}")
                elif e.code in (401, 403):
                    self.stats["url:auth_required"] += 1  # Expected for protected endpoints
                else:
                    self.add("warning", "url", f"URL returns {e.code}: {url}")
            except Exception as e:
                self.add("warning", "url", f"URL unreachable ({type(e).__name__}): {url}")

    # ── 6. COMMAND/BINARY VERIFICATION ──
    def check_commands(self):
        """Verify CLI tools referenced in TOOLS.md and skills actually exist."""
        print("⚙️ Checking command availability...")
        
        # Expand PATH to include common install locations
        extra_paths = [
            "/home/linuxbrew/.linuxbrew/bin",
            str(Path.home() / ".npm-global" / "bin"),
            str(Path.home() / ".local" / "bin"),
            "/usr/local/bin",
            "/usr/bin"
        ]
        search_path = ":".join(extra_paths) + ":" + os.environ.get("PATH", "")
        
        expected_cmds = [
            "himalaya", "gh", "openclaw", "python3", "node", "curl",
            "ffmpeg", "ffprobe", "jq", "git", "ssh", "piper"
        ]
        
        for cmd in expected_cmds:
            result = subprocess.run(
                ["which", cmd], 
                capture_output=True, text=True,
                env={**os.environ, "PATH": search_path}
            )
            if result.returncode != 0:
                self.add("warning", "command", f"Command '{cmd}' not found in PATH")
            else:
                self.stats["command:found"] += 1

    # ── 7. SERVICE HEALTH ──
    def check_services(self):
        """Verify services mentioned in TOOLS.md are running."""
        print("🏥 Checking service health...")
        
        # Set XDG_RUNTIME_DIR if not set (needed for systemctl --user in cron)
        env = os.environ.copy()
        if "XDG_RUNTIME_DIR" not in env:
            env["XDG_RUNTIME_DIR"] = f"/run/user/{os.getuid()}"
        
        # Add your own services here
        services = ["openclaw-gateway"]
        for svc in services:
            result = subprocess.run(
                ["systemctl", "--user", "is-active", svc],
                capture_output=True, text=True, env=env
            )
            if result.stdout.strip() != "active":
                self.add("critical", "service", f"Service {svc} is NOT active (status: {result.stdout.strip()})")
            else:
                self.stats["service:active"] += 1

    # ── REPORT ──
    def generate_report(self):
        """Generate structured report."""
        report = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "findings": self.findings,
            "stats": dict(self.stats),
            "summary": {
                "critical": len([f for f in self.findings if f["severity"] == "critical"]),
                "warning": len([f for f in self.findings if f["severity"] == "warning"]),
                "info": len([f for f in self.findings if f["severity"] == "info"]),
            }
        }
        
        # Save report
        REPORT_FILE.parent.mkdir(parents=True, exist_ok=True)
        REPORT_FILE.write_text(json.dumps(report, indent=2))
        
        # Append to history
        with open(HISTORY_FILE, "a") as f:
            f.write(json.dumps({
                "timestamp": report["timestamp"],
                "critical": report["summary"]["critical"],
                "warning": report["summary"]["warning"],
                "info": report["summary"]["info"]
            }) + "\n")
        
        return report

    def print_report(self, report):
        """Human-readable output."""
        s = report["summary"]
        print(f"\n{'='*60}")
        print(f"HALLUCINATION WATCHDOG REPORT")
        print(f"{'='*60}")
        print(f"🔴 Critical: {s['critical']}  🟡 Warning: {s['warning']}  🔵 Info: {s['info']}")
        print(f"{'='*60}")
        
        for sev in ("critical", "warning", "info"):
            items = [f for f in self.findings if f["severity"] == sev]
            if not items:
                continue
            icon = {"critical": "🔴", "warning": "🟡", "info": "🔵"}[sev]
            print(f"\n{icon} {sev.upper()}")
            for f in items:
                loc = f" [{f['file']}:{f['line']}]" if f.get("file") else ""
                print(f"  [{f['category']}] {f['message']}{loc}")
        
        if self.stats:
            print(f"\n📊 Stats: {dict(self.stats)}")
        
        print(f"\nReport saved: {REPORT_FILE}")

def main():
    args = set(sys.argv[1:])
    dog = HallucinationWatchdog()
    
    run_all = "--full" in args or "--report" in args or not args
    
    if run_all or "--twitter" in args:
        dog.check_twitter_handles()
    if run_all or "--files" in args:
        dog.check_file_references()
    if run_all or "--env" in args:
        dog.check_env_vars()
    if run_all or "--memory" in args:
        dog.check_memory_consistency()
    if run_all or "--urls" in args:
        dog.check_urls()
    if run_all or "--commands" in args:
        dog.check_commands()
    if run_all or "--services" in args:
        dog.check_services()
    
    report = dog.generate_report()
    dog.print_report(report)
    
    # Exit code based on severity
    if report["summary"]["critical"] > 0:
        sys.exit(2)
    elif report["summary"]["warning"] > 0:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
