#!/usr/bin/env python3
"""Add a task to queue.json. Zero LLM tokens."""
import json, sys, hashlib, datetime

QUEUE = "tasks/queue.json"

def load():
    try:
        with open(QUEUE) as f:
            return json.load(f)
    except:
        return {"version": 2, "tasks": []}

def save(q):
    with open(QUEUE, "w") as f:
        json.dump(q, f, indent=2)

def add(task, priority="med", context="", status="pending"):
    q = load()
    tid = "t" + hashlib.md5(task.encode()).hexdigest()[:6]
    # Dedup by task text
    if any(t["task"] == task for t in q["tasks"]):
        print(f"Already exists: {task[:50]}")
        return
    q["tasks"].append({
        "id": tid,
        "task": task,
        "priority": priority,
        "status": status,
        "added": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "context": context
    })
    save(q)
    print(f"Added [{priority}]: {task[:60]}")

def done(task_id):
    q = load()
    for t in q["tasks"]:
        if t["id"] == task_id:
            t["status"] = "done"
            t["completed"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
            save(q)
            print(f"Done: {t['task'][:60]}")
            return
    print(f"Not found: {task_id}")

def block(task_id, reason=""):
    q = load()
    for t in q["tasks"]:
        if t["id"] == task_id:
            t["status"] = "blocked"
            if reason:
                t["context"] = f"{t.get('context', '')} | BLOCKED: {reason}".strip(" |")
            save(q)
            print(f"Blocked: {t['task'][:60]}")
            return
    print(f"Not found: {task_id}")

def unblock(task_id):
    q = load()
    for t in q["tasks"]:
        if t["id"] == task_id:
            t["status"] = "pending"
            save(q)
            print(f"Unblocked: {t['task'][:60]}")
            return
    print(f"Not found: {task_id}")

def ls():
    q = load()
    for t in q["tasks"]:
        if t["status"] != "done":
            print(f"[{t['status']:7}] {t['priority']:4} {t['id']} — {t['task'][:70]}")

def parse_args(args):
    """Parse --priority, --context, --status flags from args."""
    priority = "med"
    context = ""
    status = "pending"
    task_parts = []
    
    i = 0
    while i < len(args):
        if args[i] == "--priority" and i + 1 < len(args):
            priority = args[i + 1]
            i += 2
        elif args[i] == "--context" and i + 1 < len(args):
            context = args[i + 1]
            i += 2
        elif args[i] == "--status" and i + 1 < len(args):
            status = args[i + 1]
            i += 2
        else:
            task_parts.append(args[i])
            i += 1
    
    return " ".join(task_parts), priority, context, status

if __name__ == "__main__":
    if len(sys.argv) < 2:
        ls()
    elif sys.argv[1] == "done" and len(sys.argv) > 2:
        done(sys.argv[2])
    elif sys.argv[1] == "block" and len(sys.argv) > 2:
        reason = sys.argv[3] if len(sys.argv) > 3 else ""
        block(sys.argv[2], reason)
    elif sys.argv[1] == "unblock" and len(sys.argv) > 2:
        unblock(sys.argv[2])
    elif sys.argv[1] == "list":
        ls()
    else:
        task, priority, context, status = parse_args(sys.argv[1:])
        if task:
            add(task, priority, context, status)
        else:
            print("Usage: tasks/add.py \"task description\" [--priority low|med|high] [--context \"details\"] [--status pending|blocked]")
            print("       tasks/add.py list")
            print("       tasks/add.py done <task_id>")
            print("       tasks/add.py block <task_id> [reason]")
            print("       tasks/add.py unblock <task_id>")
