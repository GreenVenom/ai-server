---
title: M02 — Production Ollama Runtime
document: Milestone
status: Complete
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# M02 — Production Ollama Runtime

**Status:** Complete  
**Release:** v0.2.0  
**Next Milestone:** M03 — OpenClaw Platform

## Objective

Establish a secure, persistent, locally operated model runtime on the Mac mini and provide the operational and benchmarking foundations required for later orchestration, retrieval, and agent services.

M02 delivers both the production Ollama runtime and the first complete benchmark execution path used to validate the platform's primary local models.

## Delivered Capabilities

### Production Runtime

- Ollama installed using the official macOS application.
- Ollama managed by the vendor-provided launchd service.
- Local API bound to `127.0.0.1:11434`.
- Persistent model storage configured at:

  ```text
  ~/server/data/models/ollama
  ```

- Runtime behavior verified after reboot.
- Local service account `openclaw` used for platform operations.
- Remote administration available through hardened SSH over Tailscale.

### Validated Models

Generation models:

```text
qwen3:14b
gemma4:12b
```

Embedding model:

```text
nomic-embed-text:latest
```

### Operational Validation

The following operational scripts pass on the production host:

```text
doctor.sh
status.sh
health.sh
verify.sh
```

### Benchmark Framework

M02 also delivers a provider-neutral benchmark framework with:

- benchmark CLI
- model benchmark engine
- profile-driven execution
- workload and prompt management
- provider abstraction
- model abstraction
- structured Error Repository
- structured Result Repository
- generation and embedding execution
- Markdown, JSON, CSV, and text reporting
- live Ollama validation
- automated smoke tests

The benchmark execution path is:

```text
benchmark.sh
    ↓
engines/benchmark-model.sh
    ↓
core/profile.sh
core/executor.sh
    ↓
api/prompts.sh
api/models.sh
api/providers.sh
api/results.sh
api/errors.sh
api/reporting.sh
    ↓
core/definitions.sh
core/types.sh
core/validators.sh
```

## Architectural Decisions

M02 includes the following benchmark architecture decisions:

- **ADR-0007** — Layered Benchmark Framework
- **ADR-0008** — Standardized Error Framework
- **ADR-0009** — Standardized Repository Pattern

## Compatibility Decisions

The benchmark framework targets the macOS system Bash environment.

Requirements:

- Bash 3.2 compatible
- no associative arrays
- no `declare -g`
- safe under `set -u`
- repository mutation must occur in the current shell

A critical implementation rule discovered during development is:

> Functions that mutate an in-memory repository must not be invoked through command substitution. Command substitution executes in a subshell, and repository state changes made there are discarded.

Sequential ID generation follows the same rule.

## Benchmark Profiles

Available profiles:

```text
quick
standard
extended
stress
```

Profiles provide execution defaults for:

- iterations
- timeout
- workloads
- cold-start policy
- warm-start policy
- CPU measurement flag
- memory measurement flag

Explicit CLI arguments override profile defaults.

The `standard` profile timeout was calibrated to `300` seconds after a `qwen3:14b` reasoning run exceeded the previous `120`-second limit.

## Benchmark Validation

The following benchmark tests pass:

```text
test-results.sh
test-providers.sh
test-models.sh
test-prompts.sh
test-executor.sh
test-reporting.sh
test-profiles.sh
test-benchmark-model.sh
```

Validation includes:

- repository lifecycle and identity
- live Ollama provider access
- model discovery and normalization
- prompt loading
- generation execution
- embedding execution
- reporting
- profile loading
- end-to-end model benchmarking

## Initial Benchmark Evidence

Both primary generation models have completed successful benchmark runs:

```text
qwen3:14b
gemma4:12b
```

One confirmed `qwen3:14b` reasoning run:

```text
Profile             : standard
Iterations          : 1
Timeout             : 300 seconds
Completed           : 1
Failed              : 0
Average Duration    : 134.796 seconds
Average Throughput  : 24.3 tokens/second
```

Multi-iteration Markdown reports have also been successfully generated for both Qwen and Gemma. Generated reports are the authoritative detailed benchmark artifacts.

## Acceptance Criteria

- [x] Ollama is installed and managed as a persistent runtime.
- [x] Ollama is reachable through the local API.
- [x] Model storage persists across reboot.
- [x] Primary generation models are installed and callable.
- [x] Embedding model is installed and callable.
- [x] Operational health and verification scripts pass.
- [x] Benchmark architecture is implemented.
- [x] Benchmark repositories and APIs are tested.
- [x] Profiles control benchmark execution.
- [x] Qwen benchmark path completes successfully.
- [x] Gemma benchmark path completes successfully.
- [x] Reports can be saved to project directories.
- [x] Missing report parent directories are created automatically.

## Known Follow-on Work

The following are enhancements and do not block M02 completion:

- median, minimum, maximum, and standard deviation reporting
- richer per-model and per-workload aggregation
- benchmark scoring against expected outputs
- expanded benchmark baseline matrix
- explicit timeout classification from provider transport errors
- preserving provider-side structured errors across response-capture boundaries
- CPU and memory measurement implementation where profile flags currently act as configuration metadata

## Completion Statement

M02 establishes a secure, persistent local inference runtime and a tested benchmark foundation for the Personal AI Platform.

The platform is ready to proceed to **M03 — OpenClaw Platform**.

## Related documentation

- [Documentation map](../README.md)
