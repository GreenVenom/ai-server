---
title: Repository Pattern
status: Active
---

## Purpose

The Repository Pattern defines how framework libraries manage collections of structured objects.

It provides a consistent interface for object storage while separating data management from validation, execution, and presentation.

---

## Design Principles

Repositories should:

- Own data
- Hide implementation details
- Expose consistent APIs
- Delegate validation
- Support serialization
- Be framework independent

---

## Architectural Placement

```text
Applications
        │
        ▼
Framework Libraries
        │
        ▼
Repositories
        │
        ▼
Definitions
Types
Validators
Errors
```

Repositories act as the bridge between business logic and data.

---

## Responsibilities

Repositories are responsible for:

- Creating objects
- Storing objects
- Updating objects
- Retrieving objects
- Deleting objects
- Enumerating objects
- Serializing objects

Repositories are not responsible for:

- Validation
- Logging
- Execution
- User interaction

---

## Repository Lifecycle

```text
Initialize Repository

↓

Create Object

↓

Populate Object

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

---

## Repository API

Every repository should expose a common vocabulary.

### Repository Operations

```text
count()

ids()

exists()

clear()

clear_all()
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

---

### Serialization of Repository API

```text
json()

markdown()

text()
```

---

## Naming Convention

The framework distinguishes between repository-level operations and object-level operations.

| Scope | Prefix | Example |
| ------ | ------ | ------- |
| Private | `_` | `_result_set()` |
| Object | singular | `result_create()` |
| Repository | plural | `results_count()` |

---

## Object Identity

Each object has:

- Immutable identifier
- Repository ownership
- Independent lifecycle

Repositories generate identifiers automatically.

---

## Validation Pipeline

Repositories delegate validation.

```text
Repository

↓

validators.sh

↓

types.sh

↓

definitions.sh
```

Validation never resides inside repository implementations.

---

## Error Handling

Repositories integrate with the Error Framework.

Operational failures produce structured errors.

Predicate functions return only success or failure.

---

## Serialization

Repositories should support multiple output targets.

Current formats:

- Text
- JSON
- Markdown

Future formats may include:

- CSV
- YAML
- SQLite
- REST

---

## Current Repository Implementations

| Repository | Status |
| ---------- | ------ |
| Error Repository | Planned |
| Result Repository | Planned |
| Job Repository | Planned |
| Metrics Repository | Future |
| Event Repository | Future |

---

## Relationship to Other Frameworks

The Repository Pattern is shared across:

- Operations Framework
- Benchmark Framework
- Error Framework

Future frameworks are expected to follow the same architecture.

---

## Benefits

- Consistency
- Predictability
- Reusability
- Easier testing
- Lower maintenance
- Clear separation of concerns

---

## Related Documents

- ADR-0007 — Benchmark Framework Architecture
- ADR-0008 — Standardized Error Framework
- ADR-0009 — Standardize Repository Pattern
- Engineering-Principles.md
