---
title: Running Benchmarks
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# Running Benchmarks

## Purpose

This runbook describes how to execute benchmarks on the Personal AI Platform.

Run commands from:

```text
~/server
```

## Prerequisites

Verify:

- Ollama is running.
- Required models are installed.
- Benchmark prompt files exist.
- Benchmark tests pass.

Current models:

```text
qwen3:14b
gemma4:12b
nomic-embed-text:latest
```

## Discover Available Inputs

List models:

```bash
./benchmarks/benchmark.sh --list-models
```

List workloads:

```bash
./benchmarks/benchmark.sh --list-workloads
```

List profiles:

```bash
./benchmarks/benchmark.sh --list-profiles
```

## Basic Benchmark

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 1
```

## Multi-Iteration Benchmark

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 3
```

## Save a Markdown Report

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 3 \
  --format markdown \
  --output benchmarks/reports/qwen3-14b-reasoning-standard.md
```

The CLI creates missing parent directories for the output path.

## Compare Qwen and Gemma

Qwen:

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 3 \
  --format markdown \
  --output benchmarks/reports/qwen3-14b-reasoning-standard.md
```

Gemma:

```bash
./benchmarks/benchmark.sh \
  --model gemma4:12b \
  --profile standard \
  --workload reasoning \
  --iterations 3 \
  --format markdown \
  --output benchmarks/reports/gemma4-12b-reasoning-standard.md
```

## Override Profile Timeout

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 1 \
  --timeout 600
```

Explicit CLI values override profile defaults.

## Path Semantics

Project-relative path:

```text
benchmarks/reports/report.md
```

From `~/server`, this resolves under the project.

Absolute path:

```text
/benchmarks/reports/report.md
```

This resolves from the filesystem root.

Do not add a leading slash unless an absolute filesystem path is intended.

## Output Formats

Supported formats:

```text
text
json
markdown
csv
```

Example:

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --format json
```

## Exit Behavior

A benchmark may still generate a report even when one or more executions fail.

Use both:

- process exit status
- Result status counts in the report

to evaluate the run.

## Recommended Baseline Practice

For comparable baselines:

- use the same provider
- use the same profile
- use the same workload
- use the same iteration count
- avoid other heavy workloads on the Mac mini
- record runtime and model versions
- preserve generated reports in version-controlled or archived benchmark directories

## Related documentation

- [Documentation map](../README.md)
