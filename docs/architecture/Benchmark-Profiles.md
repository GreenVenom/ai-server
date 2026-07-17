---
title: Benchmark Profiles
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# Benchmark Profiles

## Purpose

Benchmark profiles define reusable execution defaults for common benchmark scopes.

Profiles allow benchmark behavior to be selected by intent rather than repeatedly specifying all execution parameters.

## Available Profiles

```text
quick
standard
extended
stress
```

Profile files are stored under:

```text
benchmarks/profiles/
```

## Supported Configuration

Profiles may define:

```text
ITERATIONS
TIMEOUT_SECONDS
WORKLOADS
COLD_START
WARM_START
MEASURE_MEMORY
MEASURE_CPU
```

`TIMEOUT` is accepted for compatibility, but `TIMEOUT_SECONDS` is the preferred name.

## Precedence

Configuration precedence is:

```text
framework defaults
    ↓
selected profile
    ↓
explicit CLI arguments
```

For example:

```bash
./benchmarks/benchmark.sh \
  --profile standard \
  --iterations 1 \
  --timeout 600
```

uses the `standard` profile but overrides its iteration count and timeout.

## Quick Profile

Purpose:

- smoke validation
- rapid provider or model checks
- short development feedback loops

Typical characteristics:

- low iteration count
- limited workloads
- smaller execution budget

## Standard Profile

Purpose:

- routine model comparison
- repeatable baseline collection
- primary development benchmark

The standard profile currently uses:

```text
TIMEOUT_SECONDS=300
```

The timeout was increased after a real `qwen3:14b` reasoning benchmark exceeded the previous `120`-second limit.

## Extended Profile

Purpose:

- broader workload coverage
- more repetitions
- higher execution budget
- deeper model characterization

## Stress Profile

Purpose:

- repeated sustained execution
- stability observation
- long-running model and runtime evaluation

The stress profile should not be treated as the default development workflow.

## Workload Selection

A profile may define workloads.

Explicit `--workload` CLI arguments replace the profile workload selection.

Example:

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning
```

runs only the requested reasoning workload.

## Measurement Flags

Profiles expose:

```text
MEASURE_MEMORY
MEASURE_CPU
```

These flags are part of the profile contract.

Full CPU and memory measurement is a future enhancement and is not required for M02 completion.

## Cold and Warm Flags

Profiles also expose:

```text
COLD_START
WARM_START
```

These are intended to support explicit cold-start and warm-start benchmark policies.

The current M02 engine records profile configuration but does not yet implement full cache-reset or service-restart semantics for every cold-start mode.

## Validation

Profile loading verifies:

- profile file exists
- iteration count is a positive integer
- timeout is a positive integer
- workload names are valid
- boolean values normalize correctly

The profile loader is Bash 3.2-compatible and safe under `set -u`.

## Related documentation

- [Documentation map](../README.md)
