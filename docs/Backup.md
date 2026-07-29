---
title: Backup and Recovery
document: Reference
status: Active
created: 2026-07-17
updated: 2026-07-28
platform_version: v0.8.0
owner: GreenVenom
---

# Backup and Recovery

## Purpose

This document directs readers to the authoritative backup and recovery policy and operating procedure delivered in M08.

## Scope

The platform backs up the active V2 Qdrant index, its integrity metadata, and explicit non-secret runtime configuration to an encrypted off-host destination. The authoritative Obsidian vault, secrets, private keys, logs, and broad runtime artifacts remain outside these backup sets.

## Related documentation

- [Roadmap](../ROADMAP.md)
- [M08 milestone record](operations/milestones/M08-Backup-and-Disaster-Recovery.md)
- [Backup and recovery runbook](operations/Backup-and-Recovery-Runbook.md)
- [ADR-0023](decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md)
- [Documentation map](README.md)
