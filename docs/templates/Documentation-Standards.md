---
title: Documentation Standards
document: Standard
status: Active
created: 2026-07-15
updated: 2026-07-15
platform_version: v0.3.0
owner: GreenVenom
---

# Documentation Standards

## Purpose

This standard makes documentation predictable to navigate, maintain, and review. Apply it to new documents and when substantially revising existing ones. Historical documents do not need cosmetic-only rewrites.

## File and Heading Conventions

- Use descriptive, Title-Case filenames with hyphens: `OpenClaw-Sandbox-Validation.md`. `README.md` and versioned release notes such as `v0.3.0.md` are intentional exceptions.
- Prefix ADRs and milestones with their identifiers: `ADR-0010-Example.md`, `M07-Monitoring.md`.
- Begin every document with YAML front matter, followed by exactly one level-one heading that matches `title`.
- Use sentence-style section headings and keep heading levels sequential; do not skip from `##` to `####`.
- Prefer relative Markdown links with meaningful link text instead of bare paths or duplicated content.

## Required Front Matter

All new documents use this baseline. Omit only fields that do not apply.

```yaml
---
title: Clear document title
document: Architecture | ADR | Milestone | Runbook | Configuration | Operation | Release | Reference | Standard | Template
status: Draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
platform_version: vX.Y.Z
owner: GreenVenom
---
```

The default documentation owner is `GreenVenom`. ADR front matter also includes `decision_id`, `supersedes`, and `superseded_by`.

## Required Content

Every document should include:

1. A concise `Purpose` or `Summary` near the beginning.
2. The information required by its document type.
3. A `Related documentation` section with links when related material exists.

Use the following type-specific sections when applicable:

| Type | Required sections |
| --- | --- |
| Architecture | Purpose, design or structure, constraints, related documentation |
| ADR | Context, decision, consequences |
| Milestone | Objective, scope, deliverables, validation, exit criteria |
| Runbook | Purpose, prerequisites, procedure, validation or expected result, troubleshooting |
| Configuration | Purpose, installation or setup, configuration, verification, recovery |
| Operation | Summary, scope or environment, current state or evidence, follow-on work |
| Release | Summary, highlights, known limitations, next steps or migration notes |

## Maintenance Rules

- Update `updated` when changing substantive content; do not update it for mechanical formatting alone.
- Keep `status` current and replace stale current-state claims with a dated operational record when possible.
- Add a revision history only for long-lived design, milestone, or reference documents where it provides useful context; Git remains the detailed change history.
- Link to the authoritative source rather than copying commands, versions, or benchmark results into multiple documents.

## Templates

Use the [milestone template](Milestone-Template.md), [ADR template](ADR-Template.md), or [runbook template](Runbook-Template.md) as appropriate.

## Related documentation

- [Documentation map](../README.md)
