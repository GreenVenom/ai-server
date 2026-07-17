---
title: ADR-0008 - Adopt a Standardized Error Framework
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
decision_id: ADR-0008
supersedes:
superseded_by:
date: 2026-07-14
---

# ADR-0008 - Adopt a Standardized Error Framework


## Context

As the Personal AI Platform evolved, multiple framework components required a consistent mechanism for reporting failures, diagnostics, and operational issues.

Initially, shell libraries returned inconsistent combinations of:

- Exit codes
- Printed messages
- Boolean success/failure
- Ad hoc error strings

This approach does not scale across a growing collection of reusable framework libraries.

The platform requires a unified error model that supports:

- Consistent diagnostics
- Human-readable messages
- Machine-readable metadata
- Structured reporting
- Future logging integration
- JSON serialization
- Dashboard integration

---

## Decision

The platform shall implement a shared Error Framework.

The Error Framework becomes a foundational framework used throughout the Benchmark Framework and, over time, the Operations Framework.

---

## Responsibilities

The Error Framework is responsible for:

- Error object creation
- Error lifecycle
- Error codes
- Error categories
- Severity levels
- Error formatting
- Serialization
- Last-error tracking
- Assertion helpers

The framework is intentionally **not** responsible for logging or user interaction.

Applications determine whether errors are displayed, logged, or ignored.

---

## Error Object

Every framework error shall contain the following fields.

| Field | Description |
| ------ | ----------- |
| Timestamp | UTC creation time |
| Component | Library or subsystem |
| Function | Originating function |
| Code | Symbolic error code |
| Exit Code | Numeric process return code |
| Category | Classification |
| Severity | Importance |
| Message | Human-readable summary |
| Details | Optional diagnostic information |
| Suggestion | Optional remediation guidance |

---

## Error Categories

The framework defines standardized categories.

- Validation
- Configuration
- Execution
- Filesystem
- Network
- Provider
- Serialization
- Internal

---

## Severity Levels

The framework defines four severity levels.

- INFO
- WARNING
- ERROR
- FATAL

---

## Return Contract

Framework libraries shall follow a consistent return model.

### Predicate Functions

Predicate functions perform validation only.

Examples:

- provider_valid
- workload_valid
- result_valid

Behavior:

- return 0 on success
- return 1 on failure
- never create error objects
- never print output

---

### Operational Functions

Operational functions perform work.

Examples:

- provider_execute
- result_create
- repository_save

Behavior:

- return 0 on success
- populate the current error object on failure
- return an appropriate framework exit code

---

### Applications

Applications decide how errors are presented.

Applications may:

- Print
- Log
- Serialize
- Ignore
- Retry

---

## Architectural Placement

```text
Applications
      │
      ▼
Operational Libraries
      │
      ▼
Error Framework
      │
      ▼
Primitive Framework Services
```

---

## Consequences

### Advantages

- Consistent diagnostics
- Simpler framework libraries
- Better user experience
- Easier testing
- Structured automation
- Future logging integration
- Dashboard compatibility

### Costs

- Additional framework layer
- Slightly more implementation effort

These costs are acceptable for improved maintainability.

---

## Alternatives Considered

### Print-and-return

Rejected.

Reasons:

- Inconsistent formatting
- Difficult automation
- Poor testing

---

### Exceptions

Rejected.

Shell scripting does not support native exception handling.

---

## Future Evolution

The Error Framework is expected to support:

- Logging backends
- Distributed tracing
- Metrics
- Correlation IDs
- Error history
- Structured logs
- JSON diagnostics

without requiring architectural changes.

## Related documentation

- [Documentation map](../README.md)
