---
title: ADR-0018 - Use First-Party Local STDIO MCP Servers
document: ADR
status: Accepted
created: 2026-07-21
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
decision_id: ADR-0018
supersedes: null
superseded_by: null
---

# ADR-0018 - Use First-Party Local STDIO MCP Servers

## Status

Accepted

## Date

2026-07-21

## Context

M06 introduces Model Context Protocol services as a production capability of the
personal AI server.

The platform requires MCP integrations that are:

- Local-first.
- Compatible with the existing OpenClaw runtime.
- Operable under the standard `openclaw` service account.
- Reproducible from the project repository.
- Auditable and supportable without relying on opaque third-party packages.
- Narrowly scoped and appropriate for a production-quality personal server.
- Safe to run alongside Ollama, Qdrant, Docker, Tailscale, and the Obsidian
  retrieval pipeline.

MCP servers can be deployed through several transports and packaging models,
including:

- Local standard input/output processes.
- Network-accessible HTTP services.
- Third-party packages launched dynamically with tools such as `npx` or `uvx`.
- Prebuilt remote MCP services operated by external providers.
- First-party services maintained directly in this repository.

Remote or dynamically downloaded MCP services create additional concerns:

- Network exposure.
- Dependency drift.
- Unreviewed code execution.
- Supply-chain risk.
- Difficult rollback.
- Inconsistent runtime environments.
- Reduced ability to reproduce and audit production behavior.
- Potential cloud dependency, which conflicts with the local-first design goal.

The first production MCP capabilities are Obsidian retrieval and platform
inspection. Both operate entirely on local services and do not require a
network-listening MCP endpoint.

## Decision

The platform will use first-party MCP servers maintained in the `ai-server`
repository.

Production MCP servers will:

- Use local standard input/output transport.
- Run as child processes launched by OpenClaw.
- Run under the standard `openclaw` account.
- Use the dedicated Python environment located at:

  `~/server/services/mcp/.venv`

- Use pinned, reproducible project dependencies.
- Use explicit absolute executable paths in production configuration.
- Be launched from a fixed working directory.
- Avoid opening MCP-specific TCP or HTTP listeners.
- Avoid dynamic package installation at runtime.
- Avoid unpinned `npx -y`, `uvx`, or equivalent execution.
- Avoid downloading executable server code during startup.
- Be version-controlled with their source, tests, and documentation.
- Be validated through unit, integration, security, policy, and agent
  acceptance tests.

The production servers introduced by M06 are:

- `obsidian-retrieval`
- `platform-status`

The runtime command for each server will use the dedicated Python interpreter
and module execution, for example:

```text
~/server/services/mcp/.venv/bin/python -m personal_ai_mcp.obsidian.server
```

Remote HTTP MCP servers and third-party MCP implementations are deferred. Any
future exception requires a separate security and architecture review.

## Rationale

Local stdio transport provides the smallest production attack surface for the
current requirements.

It avoids:

- New listening ports.
- New firewall rules.
- Remote authentication mechanisms.
- Additional service supervisors.
- TLS certificate management.
- Network-level request routing.
- Accidental exposure outside the host.

First-party implementation provides:

- Full source control.
- Consistent project conventions.
- Direct integration with existing error and testing practices.
- Predictable deployment.
- Easier auditing.
- Controlled upgrades.
- Clear ownership of the security boundary.

A dedicated virtual environment isolates MCP dependencies from the macOS system
Python and from unrelated platform components.

## Consequences

### Positive

- MCP servers remain local and do not increase the network attack surface.
- Runtime code is reviewable and reproducible.
- Dependencies can be pinned and upgraded deliberately.
- Server behavior is covered by the project test suite.
- Rollback can use normal Git and release procedures.
- The solution remains aligned with the platform's local-first architecture.
- Operations remain straightforward because OpenClaw owns process startup.
- Future MCP services can reuse the same package and deployment framework.

### Negative

- The project owns maintenance of the MCP servers.
- SDK upgrades must be tested and documented.
- Each new service requires implementation, tests, registration, and policy
  updates.
- stdio servers are tied to the local OpenClaw runtime and are not directly
  reusable as remote services.
- Operational diagnosis may require inspection of OpenClaw-managed subprocesses.

### Risks

- A dependency update may introduce protocol incompatibility.
- Incorrect stdout logging could corrupt MCP protocol traffic.
- A first-party server can still create excessive privilege if its tool
  boundary is poorly designed.
- Runtime path changes can break server launch configuration.

### Mitigations

- Pin dependencies.
- Reserve stdout for protocol traffic.
- Route logs to stderr or protected files.
- Use exact OpenClaw tool filters.
- Use exact sandbox tool allowlists.
- Run `openclaw mcp doctor` and `openclaw mcp probe --json`.
- Verify the production inventory in `status.sh`, `health.sh`, and `verify.sh`.
- Require tests and security review for every new MCP server.

## Alternatives Considered

### Remote HTTP MCP servers

Rejected for M06 because the required capabilities are local and do not justify
new network listeners, authentication, or TLS management.

### Third-party MCP packages

Rejected as the default production approach because they introduce additional
supply-chain and maintenance risk. They may be evaluated later through a
separate review.

### Dynamic `npx` or `uvx` execution

Rejected because it can download or resolve different code at runtime and
weakens reproducibility.

### OpenClaw native tools only

Rejected because M06 requires standardized, reusable, purpose-built interfaces
with explicit schemas and narrow authorization boundaries.

### Run MCP servers in Docker containers

Deferred. Containerization may be appropriate for future remote or independently
managed MCP services, but it adds complexity without clear benefit for the two
local stdio services in M06.

## Implementation Notes

Repository location:

```text
services/mcp/
```

Production transport:

```text
stdio
```

Production interpreter:

```text
~/server/services/mcp/.venv/bin/python
```

Production validation:

```bash
openclaw config validate
openclaw mcp doctor
openclaw mcp probe --json
```

## Related Decisions

- ADR-0019: Standardize MCP Tool Authorization and Exposure
- ADR-0020: Expose Obsidian Retrieval Through a Read-Only MCP Adapter
- ADR-0021: Standardize MCP Tool Schemas, Errors, and Logging
