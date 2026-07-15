# Repository Pattern

## Purpose

The Repository Pattern standardizes how the Personal AI Platform represents collections of structured in-memory objects in Bash.

It provides consistent conventions for:

- object identity
- lifecycle
- querying
- validation
- serialization
- reset behavior
- testing

Design reference:

- ADR-0009 — Standardized Repository Pattern

## Current Implementations

| Repository | Status | Purpose |
|---|---|---|
| Error Repository | Implemented | Structured framework errors |
| Result Repository | Implemented | Benchmark execution results |
| Job Repository | Future | Long-running or queued work |
| Metrics Repository | Future | Collected runtime measurements |
| Event Repository | Future | Platform event records |

## Storage Model

The production environment uses Bash 3.2.

Repositories therefore use parallel indexed arrays rather than associative arrays.

Example:

```text
OBJECT_IDS[0]
OBJECT_STATUS[0]
OBJECT_MESSAGE[0]
```

All arrays use the same index for the same object.

The ID array is the canonical object index.

## Required Repository Properties

A repository should provide:

- unique immutable IDs
- deterministic object creation
- existence checks
- object count
- first and last object lookup
- field access
- field validation
- repository reset
- object deletion
- serialization where appropriate
- automated tests

## Identity

Sequence generation must occur in the current shell.

Incorrect:

```bash
id="$(_generate_id)"
```

when `_generate_id` mutates repository sequence state.

Correct:

```bash
_generate_id
id="$GENERATED_ID"
```

The generator updates a global result variable while preserving sequence state in the active shell.

## Current-Shell Mutation Rule

All mutating repository functions must execute in the current shell.

Command substitution executes in a subshell and discards in-memory mutations.

Incorrect:

```bash
RESULT_ID="$(result_create ...)"
```

Correct:

```bash
result_create ... >/dev/null
RESULT_ID="$RESULT_LAST_ID"
```

This rule is mandatory for all future in-memory repositories.

## Empty Repository Safety

Repository functions must be safe under:

```bash
set -u
```

and Bash 3.2.

Do not assume an empty indexed array can always be expanded safely.

Prefer:

- explicit counters
- count-guarded loops
- index-based iteration

## Reset Semantics

A full repository reset should:

- remove all objects
- reset count to zero
- clear first/last tracking
- reset sequence state when deterministic IDs are expected for tests

A clear-all operation may remove objects without resetting sequence state, depending on repository semantics.

## Validation

Validation should be layered:

```text
definitions
    ↓
primitive type validation
    ↓
business validation
    ↓
repository object validation
```

Repositories should not redefine framework enums or primitive type rules.

## Serialization

Where useful, repositories should provide stable serializers such as:

- text
- JSON
- Markdown
- CSV

Serialization failures should use the Error Framework rather than only writing unstructured messages.

## Testing Requirements

Each repository should test:

- empty initial state
- creation
- unique IDs
- count changes
- first/last lookup
- field storage
- field mutation
- invalid field rejection
- invalid value rejection
- deletion
- reset
- serialization
- Bash 3.2 behavior
- `set -u` behavior
- subshell mutation safety
