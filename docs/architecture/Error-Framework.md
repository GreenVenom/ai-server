---
title: Error Framework Architecture
status: Active
---

## Purpose

The Error Framework provides a standardized mechanism for representing, reporting, and transporting errors throughout the Personal AI Platform.

It serves as a foundational framework used by reusable libraries while remaining independent of user interfaces and logging systems.

---

## Goals

The framework is designed to provide:

- Consistent diagnostics
- Structured errors
- Human-readable output
- Machine-readable serialization
- Stable APIs
- Low coupling

---

## Architecture

```text
Application
      │
      ▼
Framework Library
      │
      ▼
errors.sh
      │
      ▼
definitions.sh
```

---

## Responsibilities

The Error Framework owns:

- Error lifecycle
- Error objects
- Error metadata
- Error formatting
- Serialization
- Assertions

It does **not** own:

- Logging
- User interaction
- Process termination
- Retry logic

---

## Error Lifecycle

```text
Create

↓

Populate

↓

Return

↓

Application decides

↓

Print
Log
Serialize
Retry
Ignore
```

---

## Error Object

```text
Timestamp
Component
Function
Code
Exit Code
Category
Severity
Message
Details
Suggestion
```

---

## Categories

- Validation
- Configuration
- Execution
- Filesystem
- Network
- Provider
- Serialization
- Internal

---

## Severity

- INFO
- WARNING
- ERROR
- FATAL

---

## Public API

The framework exposes a small public API.

```bash
error_create()

error_clear()

error_last()

error_exists()

error_print()

error_json()

error_markdown()
```

---

## Design Principles

- Errors are data.
- Validation never creates errors.
- Operational failures create structured errors.
- Applications control presentation.
- Errors are immutable after creation.

---

## Related Documents

- ADR-0008
- Benchmark-Framework.md
- Engineering-Principles.md
