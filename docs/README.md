---
title: Documentation
document: Reference
status: Active
created: 2026-07-15
updated: 2026-07-28
platform_version: v0.8.0
owner: GreenVenom
---

# Documentation

This directory is the source of truth for platform documentation. Start here to find the document type that matches your question.

## Documentation Map

| Area | Use it for |
| --- | --- |
| [Architecture](architecture/Architecture-Index.md) | System design, engineering principles, and reusable patterns. |
| [Decisions](decisions/) | The context and consequences of significant technical decisions. |
| [Milestones](operations/milestones/) | Planned, in-progress, and completed platform work. |
| [Operations](operations/) | Recorded operational state and benchmark baselines. |
| [Platform configuration](platform-config/) | Configuration of vendor-managed platform software. |
| [Runbooks](operations/runbooks/) | Repeatable operational procedures and validation steps. |
| [Releases](releases/) | Version-specific capabilities, limitations, and upgrade notes. |
| [Glossary](glossary/Glossary.md) | Canonical platform terminology. |
| [Templates](templates/) | Starting points for new documentation. |

## Writing Standard

Use [Documentation Standards](templates/Documentation-Standards.md) for all new or materially revised documents. It defines front matter, headings, links, filenames, and document-specific required sections.

## Reading Paths

- New to the platform: [root README](../README.md), [Platform Charter](operations/milestones/M00-Platform-Charter.md), then [System Overview](architecture/System-Overview.md).
- Making a technical change: architecture, related [ADRs](decisions/), the active milestone, and relevant runbooks.
- Operating the platform: platform configuration followed by the relevant runbook.
- Reviewing the current release: [M08 milestone record](operations/milestones/M08-Backup-and-Disaster-Recovery.md), [ADR-0023](decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md), [backup and recovery runbook](operations/Backup-and-Recovery-Runbook.md), and [v0.8.0 release notes](releases/v0.8.0.md).

## Status Conventions

Use `Draft`, `Active`, `In Progress`, `Complete`, `Deprecated`, or `Superseded` as appropriate. ADRs use `Proposed`, `Accepted`, `Deprecated`, or `Superseded`.

## Related documentation

- [Documentation map](README.md)
