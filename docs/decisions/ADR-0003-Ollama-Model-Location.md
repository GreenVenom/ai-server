---
title: ADR-0003 - Ollama Model Storage
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
decision_id: ADR-0003
supersedes:
superseded_by:
date: 2026-07-12
---

# ADR-0003 - Ollama Model Storage


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

## Related documentation

- [Documentation map](../README.md)
