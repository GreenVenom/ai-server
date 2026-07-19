---
title: ADR-0007 - Layered Benchmark Architecture
document: ADR
status: Accepted
created: 2026-07-17
updated: 2026-07-18
platform_version: v0.3.0
owner: GreenVenom
decision_id: ADR-0007
milestone: M02
supersedes:
superseded_by:
date: 2026-07-14
---

# ADR-0007 - Layered Benchmark Architecture


## Context

The original implementation plan for benchmarking consisted of a collection of standalone shell scripts for measuring Ollama model performance.

As the design evolved, several new requirements emerged:

- Support multiple inference providers (Ollama today, potentially LM Studio, vLLM, llama.cpp, OpenAI, Claude, and others in the future).
- Support multiple benchmark workloads.
- Generate reusable reports.
- Preserve benchmark history.
- Maintain a stable interface as the platform grows.
- Minimize duplication across benchmark scripts.
- Treat benchmarking as production infrastructure rather than ad hoc utilities.

It became clear that a collection of independent shell scripts would become increasingly difficult to maintain as functionality expanded.

---

## Decision

The benchmarking subsystem will be implemented as a modular Benchmark Framework using a layered architecture.

The framework is divided into distinct layers with clearly defined responsibilities.

```text
Applications
      │
      ▼
Engines
      │
      ▼
API
      │
      ▼
Core
```

Each layer has well-defined responsibilities and dependency rules.

---

## Framework Layers

### Applications

Applications are user-facing entry points.

Examples include:

- benchmark
- benchmark-install
- benchmark-doctor

Applications contain minimal business logic.

They orchestrate engines.

---

### Engines

Engines coordinate benchmark execution.

Examples include:

- benchmark-model.sh
- benchmark-profile.sh
- benchmark-provider.sh
- benchmark-workload.sh

Engines orchestrate the API layer but do not implement benchmark logic themselves.

---

### API Layer

The API layer provides stable interfaces consumed by engines.

Libraries include:

```text
api/
├── providers.sh
├── models.sh
├── prompts.sh
├── results.sh
└── reporting.sh
```

The API layer represents the public programming interface of the Benchmark Framework.

Changes to this layer should be minimized after stabilization.

---

### Core Layer

The Core layer contains framework implementation details.

Libraries include:

```text
core/
├── definitions.sh
├── common.sh
├── executor.sh
├── timer.sh
├── statistics.sh
└── job.sh
```

The Core layer is considered internal implementation.

Its behavior may evolve without changing the public API.

---

## Dependency Rules

Dependencies always flow downward.

```text
Applications
↓

Engines
↓

API
↓

Core
```

The following dependencies are prohibited:

- Core importing API
- API importing Engines
- Engines importing Applications

This ensures clear separation of concerns and minimizes coupling.

---

## Framework Specification

The Benchmark Framework adopts a specification-first design.

The framework specification is defined by:

```text
core/definitions.sh
```

This file defines:

- Supported providers
- Provider capabilities
- Benchmark workloads
- Result schema
- Result lifecycle
- Field types
- Output formats
- Exit codes
- Framework metadata

Implementation libraries consume this specification rather than defining their own constants.

---

## Result Repository Pattern

Benchmark results will be stored using a repository pattern.

Each benchmark execution creates a Result object.

Multiple Result objects are stored within a Result Repository.

Conceptually:

```text
Benchmark Run
├── Result 1
├── Result 2
├── Result 3
└── Result N
```

The repository becomes the canonical data source for reporting, serialization, and future historical analysis.

---

## Provider Abstraction

Benchmark execution is provider-agnostic.

Inference providers are implementation details.

Current provider:

- Ollama

Future providers may include:

- LM Studio
- vLLM
- llama.cpp
- OpenAI
- Claude
- OpenRouter

The Benchmark Framework communicates through the Provider API rather than directly invoking provider-specific commands.

---

## Design Principles

The framework follows these principles:

- Single Responsibility Principle
- Separation of Concerns
- Layered Architecture
- Specification First
- Stable Public API
- Provider Independence
- Extensibility
- Consistent Naming
- Minimal Coupling

---

## Consequences

### Advantages

- Easier to extend.
- Easier to test.
- Easier to maintain.
- Stable public interfaces.
- Multiple providers supported.
- New workloads require minimal changes.
- Historical benchmarking becomes straightforward.
- Dashboard generation becomes simpler.
- Future integrations require fewer architectural changes.

### Costs

- Additional architectural complexity.
- More framework code before benchmark features.
- Greater initial implementation effort.

These costs are considered acceptable in exchange for long-term maintainability.

---

## Alternatives Considered

### Standalone Scripts

Pros:

- Faster initial implementation.

Cons:

- High duplication.
- Tight coupling.
- Difficult to extend.
- Poor long-term maintainability.

Rejected.

---

### Single Monolithic Benchmark Script

Pros:

- Simpler implementation.

Cons:

- Difficult to maintain.
- Difficult to test.
- Provider-specific logic mixed with reporting and execution.
- Large refactors required as functionality grows.

Rejected.

---

## Future Evolution

The architecture is expected to support:

- Historical benchmark repositories.
- Benchmark comparison reports.
- Multiple concurrent providers.
- Additional workload types.
- Dashboard generation.
- Trend analysis.
- Automated regression detection.
- Scheduled benchmark execution.
- Distributed benchmark execution.

No architectural changes are expected to be required for these capabilities.

---

## Implementation Impact

This ADR affects:

- M02 — Production Ollama
- M03 — OpenClaw
- M07 — Operations Framework
- All future benchmark-related milestones

This ADR establishes the Benchmark Framework as a first-class subsystem within the Personal AI Platform.

## Related documentation

- [Documentation map](../README.md)
