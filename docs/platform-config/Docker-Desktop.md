---
title: Docker Desktop Configuration
document: Configuration
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# Docker Desktop Configuration


## Docker Desktop

### Purpose

Provides container runtime for infrastructure services.

---

## Installation

- Docker Desktop
- Apple Silicon

---

## Managed Services

Future services include:

- Qdrant
- Grafana
- Prometheus
- Uptime Kuma

---

## Philosophy

Native applications remain vendor-managed.

Containers are project-managed.

---

## Storage

Docker manages container images.

Persistent project data belongs under:

```bash
~/server/data/
```

---

## Verification

```bash
docker version

docker compose version

docker ps
```

---

## Notes

Containers should never store production data internally.

All persistent storage must be mounted from:

```bash
~/server/data
```

## Related documentation

- [Documentation map](../README.md)
