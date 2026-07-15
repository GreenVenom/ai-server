# Error Framework

## Purpose

The Error Framework provides structured, queryable error information for the Benchmark Framework.

It replaces ad hoc stderr-only failures with an in-memory Error Repository that can preserve diagnostic context during execution.

## Architecture

Implementation:

```text
benchmarks/lib/api/errors.sh
```

Supporting dependencies:

```text
definitions.sh
validators.sh
```

Design references:

- ADR-0008 — Standardized Error Framework
- ADR-0009 — Standardized Repository Pattern

## Error Schema

Structured fields:

```text
timestamp
component
function
code
exit_code
category
severity
message
details
suggestion
```

## Categories

```text
validation
configuration
execution
filesystem
network
provider
serialization
internal
```

## Severities

```text
info
warning
error
fatal
```

## Identity

Errors receive unique sequential identifiers:

```text
error-000001
error-000002
...
```

Identifiers are immutable after creation.

## Repository Capabilities

The Error Repository supports:

- create
- read
- update
- delete
- clear
- reset
- count
- first
- last
- existence checks
- category filters
- severity filters
- validation
- diagnostics

## Serialization

Supported formats:

- text
- JSON
- Markdown

The repository also provides save helpers for persistent diagnostics.

## Shell Exit Codes vs Framework Error Codes

Bash function return values are limited to `0-255`.

Framework error codes such as:

```text
1001  invalid provider
1004  invalid result
4000  serialization failure
9000  internal failure
```

are therefore stored as structured Error fields.

Functions return shell-compatible exit codes separately.

## Bash 3.2 Implementation

The Error Repository uses parallel indexed arrays because the production host's system Bash does not support associative arrays.

The canonical index is the Error ID array. Each field has a corresponding indexed array using the same position.

## Mutation and Subshell Safety

Error Repository mutations must occur in the current shell.

Command substitution creates a subshell:

```bash
value="$(some_mutating_error_function)"
```

Any repository state changes made inside that subshell are discarded when it exits.

Mutating functions should therefore be invoked directly, with output redirected when necessary.

## Integration

The Result Repository creates structured errors for:

- invalid fields
- invalid values
- invalid state transitions
- serialization failures

Provider and executor layers also use framework exit codes and error structures.

## Known Limitation

When a provider call is itself executed inside command substitution so the provider response can be captured, provider-side Error Repository mutations occur in the subshell and may not survive.

Current Result failure handling still records the execution failure.

A future provider API may set a global response variable or write response data to a temporary file so provider execution can remain in the current shell.
