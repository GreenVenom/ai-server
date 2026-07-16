# M03 Release Notes — OpenClaw Platform

## Added

- OpenClaw 2026.7.1
- LaunchAgent-managed Gateway
- loopback-only control plane
- token authentication
- Ollama integration
- Gemma 4 12B primary model
- Qwen3 14B fallback model
- Docker sandboxing
- dedicated productive workspace
- OpenClaw-aware operational scripts
- reboot-persistence validation
- Docker Desktop auto-start on user login

## Security

- web/browser tools disabled
- elevated execution disabled
- cloud memory search disabled
- dedicated workspace boundary
- zero critical deep-audit findings

## Verification

```text
status.sh  PASS
doctor.sh  31/31 PASS
health.sh  30/30 PASS
verify.sh  26/26 PASS
```

## Known Constraint

Docker Desktop requires an active `openclaw` user login session after reboot.

## Next Milestone

M04 — Qdrant vector database and local retrieval foundation.
