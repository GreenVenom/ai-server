---
title: M10 Secure Primary-Workstation Web UI
document: Milestone
status: Planned
created: 2026-08-04
updated: 2026-08-04
platform_version: v0.8.0
owner: GreenVenom
---

# M10 Secure Primary-Workstation Web UI

## Objective

Provide an authenticated control plane for the primary workstation over Tailscale without directly exposing internal platform services.

## Scope

Included:

- A separate UI service with authentication, protected sessions, and Tailscale-only access.
- Chat and retrieval through approved backend APIs.
- Health, status, model inventory, and model-selection views.
- Deployment, verification, backup integration, and operational documentation.

Excluded:

- Direct browser exposure of Ollama, Qdrant, OpenClaw, or backup endpoints.
- Public internet access.

## Success Criteria

- The UI is reachable only from the authorized Tailscale path and requires authentication.
- Browser clients use the UI or approved backend APIs, never internal service endpoints.
- Health and status views accurately report supported platform state.
- Deployment, recovery, and security checks are documented and pass.

## Exit Criteria

M10 is complete when the authenticated UI, its controls, operational integration, security validation, and documentation are verified.

## Related Documentation

- [Roadmap](../../../ROADMAP.md)
- [M09 Model Lifecycle, Selection, and Routing](M09-Model-Lifecycle-Selection-and-Routing.md)
