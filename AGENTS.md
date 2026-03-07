# AGENTS.md - Agent Guidelines

This file contains operational discipline for AI agents managing the workspace.

## Task Queue Discipline (NON-NEGOTIABLE)

**Before every final reply or NO_REPLY, scan the conversation for unresolved items:**
1. Anything deferred ("I'll do this later", "once X is ready", "need to...")
2. Anything blocked ("waiting on", "need G to...")
3. Anything promised but not done yet
4. New information that changes existing tasks

**Write it immediately:** `python3 tasks/add.py "task description"` or edit `tasks/queue.json` directly.
**Mark done:** `python3 tasks/add.py done <task_id>` when completed.
**No mental notes.** If it's not in the queue, it doesn't exist after compaction.

Queue format: `tasks/queue.json` — simple JSON, zero LLM tokens to read/write.
View: `python3 tasks/add.py list`

## Memory Write-Through

After ANY exchange where you learn something durable, write it IMMEDIATELY. Don't wait for compaction.

## Safety

- Don't exfiltrate private data. `trash` > `rm`. When in doubt, ask.
- **Safe freely:** Read files, search web, work within workspace
- **Ask first:** Sending emails, tweets, public posts, anything that leaves the machine
