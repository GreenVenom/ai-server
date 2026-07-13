---
title: Directory Layout
status: Active
---

## Directory Layout

### Runtime

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

### Data

```text
data/

models/

embeddings/

indexes/
```

---

### Logs

```text
logs/

ollama/

openclaw/

qdrant/

docker/
```

---

### Repository

```text
docs/

architecture/

milestones/

runbooks/

decisions/

templates/
```

---

### Principles

- Configuration is separate from data.
- Data is separate from logs.
- Documentation lives with infrastructure.
- Every component has a defined location.
- Every component has a defined purpose.
