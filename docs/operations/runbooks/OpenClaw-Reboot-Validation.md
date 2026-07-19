---
title: OpenClaw Reboot Validation
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# OpenClaw Reboot Validation

## Before reboot

```bash
cd ~/server
./scripts/verify.sh
openclaw sandbox list
docker ps
```

## Reboot

```bash
sudo shutdown -r now
```

## After login

```bash
cd ~/server
./scripts/status.sh
./scripts/doctor.sh
./scripts/health.sh
./scripts/verify.sh
```

Ask the agent to create `reboot-test.txt` with:

```text
OpenClaw reboot persistence is working.
```

Verify and clean up:

```bash
cat ~/server/workspaces/main/reboot-test.txt
rm ~/server/workspaces/main/reboot-test.txt
```

## Result

```text
[x] Docker auto-started on login
[x] Ollama available
[x] Tailscale available
[x] Gateway available
[x] RPC available
[x] sandbox available
[x] workspace write succeeded
[x] all operations scripts passed
```

## Related documentation

- [Documentation map](../../README.md)
