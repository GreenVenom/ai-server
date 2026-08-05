---
title: M09 Model Lifecycle, Selection, and Routing
document: Milestone
status: Planned
created: 2026-08-04
updated: 2026-08-04
platform_version: v0.8.0
owner: GreenVenom
---

# M09 Model Lifecycle, Selection, and Routing

## Objective

Make approved local models safe to acquire, evaluate, select, activate, roll back, and route on the 24 GB Mac mini.

## Scope

Included:

- A pinned, approved model catalog with profiles and compatibility metadata.
- Disk-space, memory, and concurrent-runtime safeguards.
- Controlled download, verification, activation, rollback, removal, inventory, and selection workflows.
- Routing policy for primary, fallback, embedding, and agent-specific models.

Excluded:

- Treating optional Hermes integration as a platform-wide model replacement.
- Unapproved or unmanaged model installation.

## Deliverables

- Versioned model catalog, profiles, and routing configuration.
- Lifecycle, inventory, selection, and validation commands.
- Capacity checks in operational validation and current documentation.
- Tests and runbooks for activation, rollback, and routing.

## Success Criteria

- Only catalog-approved, pinned models can be activated through the managed workflow.
- Capacity checks fail before an unsafe download or concurrent runtime starts.
- Primary, fallback, embedding, and agent-specific routing is explicit and testable.
- Activation and rollback leave an auditable record and pass operational verification.

## Exit Criteria

M09 is complete when managed model lifecycle and routing controls, tests, documentation, and rollback evidence are committed and verified.

## Related Documentation

- [Roadmap](../../../ROADMAP.md)
- [M10 Secure Primary-Workstation Web UI](M10-Secure-Primary-Workstation-Web-UI.md)
