---
title: Standardize Repository Pattern
status: Accepted
date: 2026-07-14
decision_id: ADR-0009
supersedes:
superseded_by:
---

## Context

The Personal AI Platform has evolved from a collection of automation scripts into a set of reusable frameworks.

Multiple framework components now manage structured objects, including:

- Benchmark Results
- Framework Errors
- Jobs
- Future Tasks
- Future Metrics
- Future Events

Each of these components requires a consistent mechanism for:

- Creating objects
- Updating objects
- Querying objects
- Validating objects
- Serializing objects
- Managing object lifecycles

Without a shared convention, each library would develop its own API, increasing maintenance cost and reducing consistency.

---

## Decision

The project adopts a standardized Repository Pattern.

Every library responsible for managing collections of objects shall expose a common public interface while allowing implementation details to remain private.

The Repository Pattern is an architectural convention rather than a reusable code library.

---

## Goals

The Repository Pattern shall provide:

- Consistent APIs
- Predictable naming
- Separation of concerns
- Reusable implementations
- Low coupling
- Testability
- Framework-wide consistency

---

## Repository Responsibilities

Repositories own collections of objects.

Repositories are responsible for:

- Object creation
- Object deletion
- Object storage
- Object lookup
- Object enumeration
- Object serialization
- Repository statistics

Repositories are **not** responsible for:

- Business validation
- Primitive type validation
- Logging
- User interaction
- Execution logic

Those responsibilities belong to other framework components.

---

## Object Lifecycle

Every repository object follows the same lifecycle.

```text
Create

↓

Populate

↓

Validate

↓

Store

↓

Query

↓

Serialize

↓

Delete
```

Repositories do not assume objects are immutable.

Objects may be modified until explicitly finalized by the owning framework.

---

## Public Repository API

Repositories should expose a consistent set of operations.

### Collection Operations

```text
<count>()

<ids>()

<exists>()

<clear>()

<clear_all>()
```

Examples:

```text
errors_count()

results_count()

jobs_count()
```

---

### Object Operations

```text
create()

delete()

exists()

get()

set()
```

Examples:

```text
error_create()

result_create()

job_create()
```

---

### Serialization of Public Repository API

Repositories should support multiple serialization targets.

```text
json()

markdown()

text()
```

Examples:

```text
errors_json()

results_markdown()
```

---

## Naming Convention

Repository APIs shall follow a standard naming convention.

### Private Functions

Private implementation details begin with an underscore.

Examples:

```text
_result_set()

_error_get()
```

---

### Object Functions

Operate on a single object.

Examples:

```text
result_create()

error_delete()
```

---

### Repository Functions

Operate on collections.

Examples:

```text
results_count()

errors_clear()
```

---

## Object Identity

Every object managed by a repository shall have a unique identifier.

Identifiers must:

- Be immutable
- Be unique within the repository
- Be suitable for serialization
- Remain stable for the object's lifetime

Repositories are responsible for generating identifiers.

---

## Validation

Repositories shall delegate validation.

Validation responsibilities belong to:

- definitions.sh
- types.sh
- validators.sh

Repositories consume validation services but do not implement business rules.

---

## Error Handling

Repositories shall integrate with the Error Framework.

Operational failures:

- Create structured error objects.
- Return standardized framework error codes.

Predicate functions:

- Return success or failure only.
- Never create error objects.

---

## Serialization

Repositories should provide consistent serialization interfaces.

Supported formats include:

- Text
- JSON
- Markdown

Additional formats may be added in the future.

---

## Threading Model

Repositories are designed for single-process execution.

Cross-process synchronization is outside the scope of this architecture.

Future implementations may introduce persistent repositories.

---

## Future Evolution

The Repository Pattern is expected to support future framework components including:

- Metrics
- Tasks
- Events
- Sessions
- Logs
- Caches

without requiring architectural changes.

---

## Consequences

### Advantages

- Consistent APIs
- Reduced cognitive load
- Easier testing
- Easier maintenance
- Improved documentation
- Shared implementation patterns

### Disadvantages

- Additional design work
- Slightly larger framework surface

These costs are acceptable for improved maintainability.

---

## Alternatives Considered

### Independent APIs

Rejected.

Each repository would evolve independently, increasing maintenance costs and reducing consistency.

### Generic Repository Library

Deferred.

Bash lacks native object-oriented constructs, making a reusable repository implementation unnecessarily complex.

The project instead standardizes the interface while allowing independent implementations.
