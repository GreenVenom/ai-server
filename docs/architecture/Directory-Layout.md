---
title: Directory Layout
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-18
platform_version: v0.3.0
owner: GreenVenom
---

# Directory Layout

## Runtime

```text
~/server/

config/

data/

logs/

scripts/

services/

docker/

backups/

runbooks/
```

---

## Data

```text
data/

models/

embeddings/

indexes/
```

---

## Logs

```text
logs/

ollama/

openclaw/

qdrant/

docker/
```

---

## Repository

```text
ai-server/
├── backups/                 # Runtime backup destination
├── benchmarks/              # Runner, engines, libraries, profiles, prompts, and tests
├── bootstrap/               # Host and service bootstrap scripts
├── configs/
│   └── obsidian/            # Vault registration and mirror configuration
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── engineering/
│   ├── glossary/
│   ├── operations/
│   │   ├── milestones/
│   │   └── runbooks/
│   ├── platform-config/
│   ├── releases/
│   └── templates/
├── infrastructure/          # Docker, launchd, SSH, and Tailscale definitions
├── inventory/               # Hardware and environment inventory
├── logs/                    # Runtime logs
├── mcp/                     # MCP server work area
├── scripts/
│   ├── config/
│   ├── lib/
│   ├── maintenance/
│   ├── profiles/
│   └── tests/
├── services/
│   ├── launchagents/
│   ├── obsidian/
│   └── openclaw-obsidian-plugin/
└── templates/               # Repository-level reusable templates
```

---

## Principles

- Configuration is separate from data.
- Data is separate from logs.
- Documentation lives with infrastructure.
- Every component has a defined location.
- Every component has a defined purpose.

## Related documentation

- [Documentation map](../README.md)
