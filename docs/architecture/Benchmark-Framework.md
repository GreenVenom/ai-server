---
title: Benchmark Framework Architecture
status: Active
---

## Purpose

The Benchmark Framework provides a standardized, provider-agnostic mechanism for evaluating AI models running on the Personal AI Platform.

The framework is designed as reusable infrastructure rather than a collection of benchmark scripts. It separates benchmark execution, provider integration, reporting, and framework implementation into distinct architectural layers.

This document describes the architecture of the Benchmark Framework. It intentionally avoids implementation-specific details that may evolve over time.

---

## Goals

The framework is designed to satisfy the following goals:

- Provider independence
- Repeatable benchmark execution
- Consistent benchmark reporting
- Extensible workload definitions
- Stable public APIs
- Minimal coupling
- High cohesion
- Long-term maintainability
- Future support for multiple inference providers

---

## Non-Goals

The Benchmark Framework is **not** responsible for:

- Managing AI models
- Installing providers
- Operating system configuration
- Docker orchestration
- Monitoring platform services
- Backup and recovery

Those responsibilities belong to other components of the Personal AI Platform.

---

## Architectural Principles

The framework follows the engineering principles defined in:

```text
docs/Engineering-Principles.md
```

Key principles include:

- Separation of Concerns
- Layered Architecture
- Specification First
- Provider Independence
- Stable Public Interfaces
- Single Responsibility Principle
- Extensibility over Specialization

---

## High-Level Architecture

```text
                 User
                  │
                  ▼
        benchmark (Application)
                  │
                  ▼
        Benchmark Engines
                  │
                  ▼
         Public Framework API
                  │
                  ▼
        Framework Core Services
                  │
                  ▼
      AI Inference Provider Layer
                  │
                  ▼
          Local / Remote Models
```

Each layer has clearly defined responsibilities.

Dependencies always flow downward.

---

## Layer Responsibilities

### Applications

Applications are the user-facing commands.

Responsibilities:

- Parse command-line arguments
- Load benchmark profiles
- Select workloads
- Invoke benchmark engines

Applications contain minimal business logic.

Examples:

- benchmark
- benchmark-install
- benchmark-doctor

---

### Engines

Engines orchestrate benchmark execution.

Responsibilities:

- Create benchmark jobs
- Execute providers
- Coordinate reporting
- Aggregate benchmark runs

Examples:

- benchmark-model.sh
- benchmark-profile.sh
- benchmark-provider.sh
- benchmark-workload.sh

Engines coordinate framework components but do not implement provider-specific logic.

---

### Public API

The Public API exposes stable interfaces used by the benchmark engines.

```bash
benchmarks/lib/api/
```

Current APIs include:

- Provider API
- Model API
- Prompt API
- Result API
- Reporting API

The API layer represents the supported programming interface of the Benchmark Framework.

Breaking changes to this layer should be minimized.

---

### Framework Core

The Core layer contains implementation details.

```bash
benchmarks/lib/core/
```

Responsibilities include:

- Framework definitions
- Job lifecycle
- Execution engine
- Timing
- Statistics
- Shared utilities

Core libraries are internal implementation details.

They may evolve without affecting benchmark engines.

---

## Dependency Rules

Dependencies follow a strict hierarchy.

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

The following dependencies are prohibited:

- Core → API
- API → Engines
- Engines → Applications

These rules minimize coupling and improve maintainability.

---

## Framework Specification

The framework is specification-driven.

The canonical specification is:

```bash
benchmarks/lib/core/definitions.sh
```

This specification defines:

- Supported providers
- Workloads
- Capabilities
- Result schema
- Result lifecycle
- Output formats
- Exit codes
- Default values

Implementation libraries consume the specification rather than redefining constants.

---

## Provider Architecture

The framework treats inference providers as interchangeable implementations.

```text
             Provider API
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
  Ollama      LM Studio       vLLM
     │
     ▼
 Models
```

Current provider:

- Ollama

Planned providers:

- LM Studio
- vLLM
- llama.cpp
- OpenAI
- Claude
- OpenRouter

Provider-specific behavior is isolated behind the Provider API.

---

## Benchmark Job Lifecycle

Each benchmark executes as a Job.

```text
Create Job
      │
      ▼
Validate
      │
      ▼
Execute
      │
      ▼
Collect Metrics
      │
      ▼
Create Result
      │
      ▼
Generate Report
```

Jobs are immutable once execution begins.

---

## Result Repository

Each benchmark execution produces a Result object.

Results are stored within a Result Repository.

```text
Benchmark Run

├── Result
├── Result
├── Result
└── Result
```

The repository becomes the authoritative data source for:

- Reporting
- Serialization
- Historical analysis
- Dashboard generation
- Trend analysis

---

## Reporting Pipeline

Reporting consumes Result objects.

```text
Results
    │
    ▼
Report Generator
    │
    ├── Console
    ├── Markdown
    ├── JSON
    ├── CSV
    └── HTML (Future)
```

Reporting never communicates directly with providers.

---

## Workload Architecture

Benchmarks are organized into workloads.

Examples include:

- Reasoning
- Coding
- Summarization
- Classification
- Extraction
- Creative Writing
- Embeddings

Workloads are independent of providers.

Each workload defines:

- Prompt
- Description
- Timeout
- Expected output
- Scoring policy

---

## Profiles

Profiles define benchmark suites.

Examples:

- Quick
- Standard
- Full
- Regression

Profiles select:

- Models
- Workloads
- Iterations
- Reporting options

Profiles enable repeatable benchmark execution.

---

## Execution Flow

```text
Application
      │
      ▼
Engine
      │
      ▼
Create Job
      │
      ▼
Provider API
      │
      ▼
Inference Provider
      │
      ▼
Execution Metrics
      │
      ▼
Result Repository
      │
      ▼
Reporting API
```

Each layer performs a single responsibility.

---

## Design Decisions

The framework adopts the following architectural decisions:

- Layered Architecture
- Repository Pattern
- Provider Abstraction
- Specification-First Design
- Stable Public API
- Framework Core Separation

Rationale for these decisions is documented in:

```bash
docs/decisions/ADR-0007-Layered-Benchmark-Architecture.md
```

---

## Future Evolution

The architecture is expected to support:

- Historical benchmark repositories
- Benchmark dashboards
- Regression detection
- Scheduled benchmark execution
- Distributed benchmarking
- Multiple concurrent providers
- Additional workload types
- Vision benchmarks
- Audio benchmarks
- Tool-calling benchmarks
- Automated performance baselines

These capabilities should require minimal architectural changes.

---

## Related Documents

Architecture

- System-Overview.md
- Runtime-Architecture.md
- Service-Management.md
- Network-Architecture.md
- Directory-Layout.md

Engineering

- Engineering-Principles.md
- Glossary.md

Decisions

- ADR-0007-Layered-Benchmark-Architecture.md

Milestones

- M02-Production-Ollama.md
- M03-OpenClaw.md
