---
title: Benchmark Validation
document: Runbook
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# Benchmark Validation

## Purpose

This runbook validates the Benchmark Framework before collecting production baselines.

Run from:

```text
~/server
```

## Prerequisites

- Ollama service is running.
- Ollama API is reachable.
- `qwen3:14b` is installed.
- `gemma4:12b` is installed.
- `nomic-embed-text:latest` is installed.
- Benchmark prompt files exist.

## Test Sequence

Run:

```bash
./benchmarks/tests/test-results.sh
./benchmarks/tests/test-providers.sh
./benchmarks/tests/test-models.sh
./benchmarks/tests/test-prompts.sh
./benchmarks/tests/test-executor.sh
./benchmarks/tests/test-reporting.sh
./benchmarks/tests/test-profiles.sh
./benchmarks/tests/test-benchmark-model.sh
```

## Expected Result

All tests should complete with zero failures.

Current validated suite:

```text
test-results.sh          PASS
test-providers.sh        PASS
test-models.sh           PASS
test-prompts.sh          PASS
test-executor.sh         PASS
test-reporting.sh        PASS
test-profiles.sh         PASS
test-benchmark-model.sh  PASS
```

## What Each Test Validates

### `test-results.sh`

Validates:

- repository reset
- Result creation
- unique IDs
- field storage
- count behavior
- first/last behavior
- lifecycle and repository integrity

### `test-providers.sh`

Validates:

- Ollama availability
- provider metadata
- model discovery
- generation path
- embedding path

### `test-models.sh`

Validates:

- model normalization
- model existence
- generation classification
- embedding classification
- preferred model selection

### `test-prompts.sh`

Validates:

- workload discovery
- prompt file resolution
- prompt loading
- workload metadata
- optional expected-output behavior

### `test-executor.sh`

Validates:

- Result creation
- live generation
- prompt-file workload execution
- embedding execution
- failure Result creation
- invalid workload rejection

### `test-reporting.sh`

Validates:

- deterministic seeded results
- summary counts
- aggregate calculations
- report generation

### `test-profiles.sh`

Validates:

- profile discovery
- profile loading
- iteration configuration
- timeout configuration
- profile validation
- Bash 3.2 empty-workload safety

### `test-benchmark-model.sh`

Validates:

- profile application
- model selection
- engine configuration
- live model benchmark execution
- Result creation
- completed and failed counts
- report generation

## Troubleshooting

### Run ends near an exact timeout

Inspect the selected profile timeout.

Example:

```bash
grep TIMEOUT_SECONDS benchmarks/profiles/standard.profile
```

The standard profile is currently calibrated to:

```text
300 seconds
```

### Empty-array error under `set -u`

Use count-guarded, index-based iteration.

Do not rely on unsafe expansion of an empty indexed array in Bash 3.2.

### Repository state disappears

Check for command substitution around mutating functions.

Incorrect:

```bash
id="$(result_create ...)"
```

Correct:

```bash
result_create ... >/dev/null
id="$RESULT_LAST_ID"
```

### Report path fails

Use a correct project-relative path:

```text
benchmarks/reports/report.md
```

The root CLI now creates missing parent directories automatically.

## Related documentation

- [Documentation map](../README.md)
