---
title: ADR-0021 - Standardize MCP Tool Schemas, Errors, and Logging
document: ADR
status: Accepted
created: 2026-07-21
updated: 2026-07-21
platform_version: v0.6.0
owner: GreenVenom
decision_id: ADR-0021
supersedes: null
superseded_by: null
---

# ADR-0021 - Standardize MCP Tool Schemas, Errors, and Logging

## Status

Accepted

## Date

2026-07-21

## Context

MCP tools form an agent-facing API boundary.

Without a shared contract, individual tools may diverge in:

- Request validation.
- Unknown-field handling.
- Response structure.
- Error codes.
- Retry semantics.
- Request identifiers.
- Timeout behavior.
- Result limits.
- Logging behavior.
- Sensitive-data handling.
- Compatibility expectations.

The M06 servers interact with local platform services and indexed personal
knowledge. Their outputs can include:

- Platform versions.
- Health information.
- Collection metadata.
- Indexed note text.
- Source paths relative to a vault.
- Stable document and chunk identifiers.

Their internal failures can include:

- Invalid input.
- Unauthorized vaults or components.
- Missing dependencies.
- Timeouts.
- Malformed local-service responses.
- Internal exceptions.

Because stdio is used for MCP protocol traffic, ordinary application logging to
stdout can corrupt the protocol stream.

Because indexed notes may contain private information, routine logs must not
capture raw queries, full note text, tool results, secrets, absolute private
paths, or internal exception details.

The platform needs a uniform schema, error, and logging contract for all current
and future first-party MCP tools.

## Decision

All first-party MCP tools will use standardized request, response, error,
execution, and logging conventions.

### Strict request schemas

Request models will:

- Reject unknown fields.
- Use explicit types.
- Use enums or literals for bounded choices.
- Use safe identifier validation for IDs.
- Enforce numeric ranges.
- Enforce result-count limits.
- Avoid generic fields such as:
  - `command`
  - `script`
  - `args`
  - `path`
  - `url`
  - `host`
  - `executable`
  - `collection`

unless a future ADR explicitly authorizes such capability.

Validation failures will occur before dependency access or subprocess execution.

### Versioned response envelope

Every tool response will use a versioned envelope containing:

```json
{
  "schema_version": 1,
  "status": "success",
  "request_id": "uuid",
  "data": {},
  "error": null
}
```

Error responses will use:

```json
{
  "schema_version": 1,
  "status": "error",
  "request_id": "uuid",
  "data": null,
  "error": {
    "code": "MCP-VALIDATION",
    "message": "The request is invalid.",
    "retryable": false,
    "request_id": "uuid"
  }
}
```

The envelope will maintain a stable top-level shape.

### Error categories

The initial stable error categories are:

- `MCP-VALIDATION`
- `MCP-AUTHORIZATION`
- `MCP-DEPENDENCY`
- `MCP-TIMEOUT`
- `MCP-NOT-FOUND`
- `MCP-INTERNAL`

Error messages returned to callers will be sanitized.

Responses will not expose:

- Stack traces.
- Shell command lines.
- Environment variables.
- Secret values.
- Absolute private filesystem paths.
- Raw dependency errors.
- Unbounded dependency responses.

### Retry semantics

Errors will include a boolean `retryable` field.

Examples:

- Invalid input: not retryable.
- Unauthorized request: not retryable.
- Missing approved object: generally not retryable without a state change.
- Temporary dependency outage: retryable.
- Timeout: retryable when the operation is safe to repeat.
- Internal validation invariant failure: not retryable by default.

### Request identifiers

Every response will include a request identifier.

The same identifier will be included in the error body when an error is
returned.

Request identifiers may be recorded in operational logs for correlation.

### Timeouts and bounded execution

All dependency calls and subprocesses will have finite timeouts.

Subprocess execution will use:

- Argument arrays.
- `shell=False`.
- A restricted environment.
- Caller-independent executable paths.
- Bounded stdout.
- Bounded stderr.

Tool responses will use bounded:

- Result counts.
- Text lengths.
- Collection sizes.
- Diagnostic details.

### Logging

For stdio MCP servers:

- stdout is reserved for MCP protocol traffic.
- Logs must go to stderr or a protected file.
- Routine logs must use metadata rather than content.
- Raw note text must not be logged.
- Raw search queries should not be logged by default.
- Secret values must not be logged.
- Full tool results must not be logged.
- Stack traces may be written only to protected diagnostic logs when explicitly
  enabled.
- Request IDs, tool names, durations, status, and stable error codes may be
  logged.
- Absolute private paths should be redacted or replaced with logical resource
  names.

### Tool descriptions

Tool names, descriptions, and parameter documentation are part of the security
boundary.

Descriptions must:

- State that the tool is read-only where applicable.
- State the approved scope.
- Avoid implying unsupported write or administrative capabilities.
- Avoid instructing the model to use fallback native tools for prohibited
  operations.
- Describe authorization failures clearly.

### Compatibility

The following changes are considered breaking:

- Renaming a tool.
- Removing a tool.
- Renaming a required field.
- Changing a field type.
- Removing a response field relied upon by clients.
- Changing the meaning of a stable error code.
- Changing authorization behavior in a less restrictive direction.
- Changing the response envelope shape.

The following changes may be non-breaking when documented:

- Adding an optional request field.
- Adding an optional response field.
- Adding a new non-conflicting error code.
- Improving a sanitized message without changing the error category.

Breaking changes require:

- A schema-version review.
- Updated tests.
- Updated OpenClaw configuration.
- Updated operational validation.
- Updated acceptance tests.
- Updated documentation.
- A release note.

## Rationale

Strict schemas reduce ambiguity and prevent tools from becoming generic execution
interfaces.

A stable envelope gives agents, tests, and operators a predictable response
shape.

Stable error categories allow callers to distinguish invalid, unauthorized,
transient, and internal failures without revealing sensitive implementation
details.

Bounded execution protects the local platform from runaway commands, excessive
output, and oversized model context.

Metadata-only logging provides operational value while reducing exposure of
personal knowledge and system details.

## Consequences

### Positive

- Tool behavior is consistent across servers.
- Invalid input is rejected early.
- Tests can assert stable response shapes.
- Agents receive actionable but sanitized errors.
- Operations can correlate failures using request IDs.
- Protocol traffic is protected from stdout logging.
- Sensitive note and system content is less likely to enter logs.
- Future MCP servers have a defined engineering standard.
- Breaking changes are easier to identify and manage.

### Negative

- Tool implementations require additional schema and envelope code.
- Sanitized errors may make debugging less convenient.
- Strict validation can reject inputs that a permissive implementation might
  interpret successfully.
- Compatibility discipline increases the work required for changes.
- Bounded output may require pagination or follow-up tools in future milestones.

### Risks

- A developer may log raw tool arguments or results.
- An unhandled exception may leak implementation details.
- A dependency may return unexpectedly large content.
- Tool descriptions may encourage unsafe fallback behavior.
- Schema drift may occur between implementation and documentation.

### Mitigations

- Centralize common models and error handling.
- Test unknown-field rejection.
- Test error response envelopes.
- Test bounded output.
- Test `shell=False`.
- Audit source for dangerous subprocess and logging patterns.
- Review tool descriptions during security acceptance.
- Run integration and agent acceptance tests before release.
- Keep acceptance outputs out of Git.

## Alternatives Considered

### Return raw Python exceptions

Rejected because exceptions can expose internal paths, command lines, and
dependency details.

### Allow each server to define its own response format

Rejected because it creates inconsistency and weakens testability.

### Use unstructured text responses only

Rejected because structured status, errors, and operational checks require a
stable machine-readable contract.

### Log full tool requests and results

Rejected because the system processes private indexed knowledge and sensitive
platform metadata.

### Permit unbounded output

Rejected because large outputs can consume memory, model context, logs, and
operator attention.

## Implementation Notes

Common code belongs under:

```text
services/mcp/src/personal_ai_mcp/common/
```

Acceptance output belongs under:

```text
services/mcp/tests/acceptance/results/
```

Live acceptance outputs are local artifacts and must not be committed.

## Related Decisions

- ADR-0018: Use First-Party Local STDIO MCP Servers
- ADR-0019: Standardize MCP Tool Authorization and Exposure
- ADR-0020: Expose Obsidian Retrieval Through a Read-Only MCP Adapter
