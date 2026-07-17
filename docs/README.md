---
title: Documentation
document: Reference
status: Active
created: 2026-07-15
updated: 2026-07-15
platform_version: v0.3.0
owner: GreenVenom
---

# Documentation

This directory is the source of truth for platform documentation. Start here to find the document type that matches your question.

## Documentation Map

| Area | Use it for |
| --- | --- |
| [Architecture](architecture/Architecture-Index.md) | System design, engineering principles, and reusable patterns. |
| [Decisions](decisions/) | The context and consequences of significant technical decisions. |
| [Milestones](milestones/) | Planned, in-progress, and completed platform work. |
| [Operations](operations/) | Recorded operational state and benchmark baselines. |
| [Platform configuration](platform-config/) | Configuration of vendor-managed platform software. |
| [Runbooks](runbooks/) | Repeatable operational procedures and validation steps. |
| [Releases](releases/) | Version-specific capabilities, limitations, and upgrade notes. |
| [Glossary](glossary/Glossary.md) | Canonical platform terminology. |
| [Templates](templates/) | Starting points for new documentation. |

## Writing Standard

Use [Documentation Standards](templates/Documentation-Standards.md) for all new or materially revised documents. It defines front matter, headings, links, filenames, and document-specific required sections.

## Reading Paths

- New to the platform: [root README](../README.md), [Platform Charter](milestones/M00-Platform-Charter.md), then [System Overview](architecture/System-Overview.md).
- Making a technical change: architecture, related [ADRs](decisions/), the active milestone, and relevant runbooks.
- Operating the platform: platform configuration followed by the relevant runbook.

## Status Conventions

Use `Draft`, `Active`, `In Progress`, `Complete`, `Deprecated`, or `Superseded` as appropriate. ADRs use `Proposed`, `Accepted`, `Deprecated`, or `Superseded`.

## Related documentation

- [Documentation map](README.md)
