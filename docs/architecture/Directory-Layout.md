---
title: Directory Layout
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
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
docs/

architecture/

milestones/

runbooks/

decisions/

templates/
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
