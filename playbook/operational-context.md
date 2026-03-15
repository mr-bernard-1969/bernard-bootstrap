# Operational Context System

As your agent's deployment grows from 1-2 services to 10+, scattered notes in MEMORY.md and TOOLS.md become unmanageable. This playbook describes a pattern for encoding your service topology as structured, queryable data.

## The Problem

Early on, you document services in markdown:
```
## SMS Service
- Port: 8443
- Health: curl 127.0.0.1:8443/health
- Restart: systemctl --user restart telnyx-sms
```

This works for 3-5 services. At 10+, you start losing track of:
- Which ports are in use (and which are available)
- What depends on what
- Which services need restarting after a config change
- Whether your health checks cover everything

## Phase 1: services.yaml (Structured Config)

Move service definitions from scattered markdown into a single YAML file:

```yaml
# config/services.yaml
services:
  web-app:
    port: 3000
    health: "http://127.0.0.1:3000/health"
    systemd: "web-app.service"
    restart: "systemctl --user restart web-app"
    depends: []
    description: "Main website"
    
  api-server:
    port: 8080
    health: "http://127.0.0.1:8080/health"
    systemd: "api-server.service"
    restart: "systemctl --user restart api-server"
    depends: ["web-app"]
    description: "REST API backend"
    
  sms-gateway:
    port: 8443
    health: "http://127.0.0.1:8443/health"
    systemd: "sms-gateway.service"
    restart: "systemctl --user restart sms-gateway"
    depends: []
    description: "SMS sending/receiving"
```

### Query Script

```python
#!/usr/bin/env python3
"""Query service info from services.yaml"""
import yaml, sys
from pathlib import Path

SERVICES_FILE = Path.home() / ".openclaw" / "workspace" / "config" / "services.yaml"

def load():
    return yaml.safe_load(SERVICES_FILE.read_text())

def show(name):
    data = load()
    svc = data["services"].get(name)
    if not svc:
        print(f"Unknown service: {name}")
        return
    for k, v in svc.items():
        print(f"  {k}: {v}")

def all_ports():
    data = load()
    for name, svc in sorted(data["services"].items(), key=lambda x: x[1].get("port", 0)):
        print(f"  {svc.get('port', '?'):>5}  {name}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        all_ports()
    elif sys.argv[1] == "--all-ports":
        all_ports()
    else:
        show(sys.argv[1])
```

### Benefits
- **Self-heal.sh** reads `services.yaml` instead of hardcoded service lists
- **Heartbeat** health checks auto-generated from service definitions
- **Port conflicts** caught at config time (scan for duplicate ports)
- **Dependency ordering** for restart sequences

## Phase 2: Operational Context Loader

Write a boot script that reads `services.yaml` + memory files and generates a compact summary:

```bash
# scripts/load-operational-context.py
# Runs at session start, produces memory/operational-context.md
# Agent reads this instead of scanning 15 files
```

This keeps your agent's boot cost low even as complexity grows. The loader runs once, produces a 10-15KB summary, and the agent reads that instead of grepping through dozens of files.

## Phase 3: Knowledge Graph (Optional, Advanced)

For deployments with 50+ entities (people, services, projects, credentials):

```python
# SQLite knowledge graph
# Tables: entities, facts, relationships
# CLI: query.py entity|facts|deps|search|stats

# Example queries:
# python3 query.py entity "api-gateway"     → all facts about the gateway
# python3 query.py deps "web-app"           → what depends on web-app
# python3 query.py search "port 3000"       → find anything referencing port 3000
# python3 query.py stats                    → entity/fact/relationship counts
```

Schema:
```sql
CREATE TABLE entities (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    type TEXT,  -- service, person, project, credential
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE facts (
    id INTEGER PRIMARY KEY,
    entity_id INTEGER REFERENCES entities(id),
    key TEXT,
    value TEXT,
    source TEXT,  -- which file/conversation this came from
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE relationships (
    id INTEGER PRIMARY KEY,
    from_entity INTEGER REFERENCES entities(id),
    to_entity INTEGER REFERENCES entities(id),
    relation TEXT,  -- depends-on, manages, connects-to, owns
    metadata TEXT
);
```

### Import Scripts

Build importers that read from your existing files:
```python
# import_services.py — reads config/services.yaml → knowledge graph
# import_entities.py — reads memory/entities.md → knowledge graph
# import_facts.py    — reads memory/facts.md → knowledge graph
```

### When You Need This

You probably don't need Phase 3 until you have:
- 50+ entities across your system
- Frequent "what connects to what?" questions
- Multiple people/agents working on the same infrastructure
- Services with complex dependency chains

Phase 1 (services.yaml) is sufficient for most single-operator deployments.

## Migration Strategy

1. Start with Phase 1 immediately — it's a few minutes of work
2. Add the context loader when boot times feel slow or you're reading too many files
3. Only build the knowledge graph when you feel the pain of not having it

Don't over-engineer. The simplest system that works is the best system.
