---
title: Docker Desktop Configuration
status: Active
---

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
