---
title: ADR-0019 - Standardize MCP Tool Authorization and Exposure
document: ADR
status: Accepted
created: 2026-07-21
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
decision_id: ADR-0019
supersedes: null
superseded_by: null
---

# ADR-0019 - Standardize MCP Tool Authorization and Exposure

## Status

Accepted

## Date

2026-07-21

## Context

MCP server registration does not by itself define the complete production tool
boundary.

OpenClaw applies multiple policy layers:

1. The MCP server determines which functions it exposes.
2. The OpenClaw MCP registration can filter the server's tools.
3. The agent tool policy determines which tools may be used.
4. Sandboxed sessions apply an additional sandbox tool policy.
5. The tool implementation performs request-level validation and authorization.

During M06 end-to-end acceptance testing, both production MCP servers passed
configuration checks and the aggregate MCP probe reported all eight expected
tools. However, sandboxed agent sessions did not receive those tools because
the sandbox policy had not explicitly allowed the namespaced MCP tool names.

The gateway reported that eight tools were removed by sandbox policy.

The initial agent acceptance run also demonstrated a second risk: when the
intended MCP tool was unavailable or not selected, the model could attempt to
use broader native tools such as:

- `exec`
- `read`
- the legacy native `obsidian_search`

This creates a gap between the intended MCP security model and the effective
tool surface available to the agent.

The production system therefore needs an explicit, deterministic, and
verifiable tool authorization model.

## Decision

The platform will use a layered, default-deny MCP authorization model.

### Server exposure

Each MCP server will expose only its approved functions.

The production servers and tools are:

#### `obsidian-retrieval`

- `obsidian_get_chunk`
- `obsidian_list_vaults`
- `obsidian_retrieval_status`
- `obsidian_search`

#### `platform-status`

- `platform_component_status`
- `platform_health`
- `platform_status`
- `platform_versions`

### OpenClaw server filters

Each MCP server registration will use an exact per-server tool filter.

Wildcard filters are prohibited in production.

### Sandbox authorization

The exact namespaced MCP tool names will be added to the sandbox tool policy:

```text
obsidian-retrieval__obsidian_get_chunk
obsidian-retrieval__obsidian_list_vaults
obsidian-retrieval__obsidian_retrieval_status
obsidian-retrieval__obsidian_search
platform-status__platform_component_status
platform-status__platform_health
platform-status__platform_status
platform-status__platform_versions
```

The approved names will be stored under the sandbox policy's exact
`alsoAllow` entries unless an existing policy scope uses `allow`, in which case
the approved names must be merged into that scope instead.

A policy scope must not define both `allow` and `alsoAllow`.

### Prohibited wildcard grants

The platform will not use:

- Broad MCP bundles.
- Server-name wildcards.
- Namespace wildcards.
- Automatic exposure of every tool from an approved server.
- Automatic exposure of future tools.

Every new tool requires an explicit policy change.

### Effective inventory validation

The approved production inventory is:

- Exactly 2 MCP servers.
- Exactly 8 MCP tools.
- Exactly 0 diagnostics.

The inventory will be validated through structured output from:

```bash
openclaw mcp probe --json
```

The validation is integrated into:

- `scripts/status.sh`
- `scripts/health.sh`
- `scripts/verify.sh`
- `scripts/lib/mcp.sh`

Any missing server, missing tool, extra server, extra tool, or diagnostic causes
production validation failure.

### Capability boundary

The M06 MCP tool boundary is read-only.

The following capabilities are outside the approved M06 MCP surface:

- Service restart or service control.
- Arbitrary command execution.
- Arbitrary shell execution.
- Arbitrary filesystem access.
- Arbitrary network destinations.
- Caller-selected executables.
- Caller-selected Qdrant collections.
- Caller-selected local paths.
- Obsidian writes.
- Qdrant administration.
- Configuration mutation.
- Secret retrieval.

### Agent acceptance

End-to-end acceptance tests will verify both allowed and prohibited behavior.

Allowed behavior must demonstrate use of every approved MCP tool.

Prohibited behavior must demonstrate:

- Service-control refusal.
- Arbitrary-command rejection.
- Arbitrary-filesystem rejection.

Session transcripts provide the authoritative evidence of the selected tool name,
arguments, and structured result.

## Rationale

Exact names provide deterministic least privilege.

A server wildcard would allow a future tool to become agent-accessible without a
separate review. A broad MCP bundle would have the same problem across all
servers.

Layered authorization is necessary because no single layer provides the complete
boundary:

- Server exposure prevents unavailable functions from existing.
- Registration filters constrain server-local exposure.
- Sandbox policy controls tool availability to sandboxed agents.
- Tool validation constrains parameters and runtime behavior.
- Operational validation detects drift.
- Acceptance testing verifies the effective behavior seen by the model.

## Consequences

### Positive

- The effective agent tool surface is explicit and auditable.
- Future tools cannot become available accidentally.
- Sandboxed agents can use approved MCP tools without disabling sandboxing.
- Unexpected inventory changes fail production verification.
- Broader native tools remain distinguishable from the MCP boundary.
- The policy is testable using structured OpenClaw output.
- The system preserves least privilege while remaining operational.

### Negative

- Each new MCP tool requires coordinated changes in multiple locations.
- Registration and sandbox policy can drift if not updated together.
- Exact inventory validation intentionally rejects unplanned additions.
- Tool renaming becomes a breaking production change.
- Acceptance testing takes longer because local models process the full tool
  catalog.

### Risks

- An operator may update server code but forget sandbox authorization.
- An agent may select a broader native tool if instructions or policy are
  ambiguous.
- Duplicate legacy and MCP tools may create selection ambiguity.
- An incorrect allowlist could expose an unintended tool.

### Mitigations

- Use exact names.
- Keep the approved inventory in one shared operational helper.
- Run policy tests.
- Run all ten agent acceptance scenarios.
- Inspect session transcripts for the exact tool call.
- Treat tool additions and renames as reviewed changes.
- Prefer explicit tool names during wiring acceptance.
- Maintain separate natural-language behavioral tests after wiring validation.

## Alternatives Considered

### Allow all tools from approved MCP servers

Rejected because future tools would become available without separate review.

### Allow all MCP tools through a bundle

Rejected because it creates an overly broad and non-deterministic boundary.

### Disable sandboxing for the agent

Rejected because it would weaken the platform's broader isolation model.

### Rely only on server implementation checks

Rejected because an agent can select a different tool before the intended server
implementation is reached.

### Rely only on OpenClaw registration filters

Rejected because sandboxed sessions apply an additional policy layer.

### Use prompt instructions as the security boundary

Rejected because model instructions are not a substitute for enforceable policy.

## Implementation Notes

Sandbox configuration must contain the exact namespaced tools.

The structured operational validator is located at:

```text
scripts/lib/mcp.sh
```

Agent acceptance specifications are located at:

```text
services/mcp/tests/acceptance/
```

## Related Decisions

- ADR-0018: Use First-Party Local STDIO MCP Servers
- ADR-0020: Expose Obsidian Retrieval Through a Read-Only MCP Adapter
- ADR-0021: Standardize MCP Tool Schemas, Errors, and Logging
