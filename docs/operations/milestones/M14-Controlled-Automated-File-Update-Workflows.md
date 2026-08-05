---
title: M14 Controlled Automated File-Update Workflows
document: Milestone
status: Planned
created: 2026-08-04
updated: 2026-08-04
platform_version: v0.8.0
owner: GreenVenom
---

# M14 Controlled Automated File-Update Workflows

## Objective

Allow agents to propose and apply file changes only inside tightly governed boundaries.

## Scope

Included:

- Explicit approved repository or workspace scopes with deny-by-default writes.
- Dry runs, diff previews, approval gates, and execution records.
- Git-backed commits, rollback, recovery procedures, and queue/status visibility.
- Audit logging, backup coverage, and security acceptance tests.

Excluded:

- Unattended writes outside approved scopes.
- Changes without preview, authorization, and recoverable Git history.

## Success Criteria

- Out-of-scope writes are denied before execution.
- Every applied change has a reviewed diff, approval record, and Git recovery path.
- Operators can inspect the queue, status, audit record, and rollback instructions.

## Exit Criteria

M14 is complete when constrained file automation, approval and audit controls, recovery verification, security tests, and documentation are verified.

## Related Documentation

- [Roadmap](../../../ROADMAP.md)
- [M13 Guided AI Agent Creation](M13-Guided-AI-Agent-Creation.md)
