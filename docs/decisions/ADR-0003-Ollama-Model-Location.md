---
title: Ollama Model Storage
status: Accepted
date: 2026-07-12
---

## Context

The default Ollama model location is inside the user's home directory.

Large model files should be organized alongside other server data.

---

## Decision

Store all Ollama models under:

~/server/data/models/ollama

---

## Consequences

### Positive

- Consistent directory structure
- Easier backups
- Easier migration
- Better separation of configuration and data

### Negative

Requires configuring Ollama to use a non-default storage location.
