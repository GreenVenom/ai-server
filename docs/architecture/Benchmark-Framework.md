---
title: Benchmark Framework
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# Benchmark Framework

## Purpose

The Benchmark Framework provides a provider-neutral, workload-driven system for measuring local model behavior and producing repeatable benchmark reports.

The framework separates command-line concerns, benchmark orchestration, public APIs, and low-level core utilities.

## Architecture

```text
Applications
    ↓
Engines
    ↓
API
    ↓
Core
```

Current implementation:

```text
benchmarks/
├── benchmark.sh
├── engines/
│   └── benchmark-model.sh
├── lib/
│   ├── api/
│   │   ├── errors.sh
│   │   ├── results.sh
│   │   ├── providers.sh
│   │   ├── models.sh
│   │   ├── prompts.sh
│   │   └── reporting.sh
│   └── core/
│       ├── definitions.sh
│       ├── types.sh
│       ├── validators.sh
│       ├── profile.sh
│       └── executor.sh
├── profiles/
├── prompts/
├── expected/
├── results/
├── reports/
└── tests/
```

## Layer Responsibilities

### Application Layer

`benchmark.sh`

Responsibilities:

- parse CLI arguments
- load profile defaults
- apply CLI overrides
- choose default models or workloads
- invoke the benchmark engine
- emit or save reports
- create missing report parent directories

The application layer does not implement provider logic.

### Engine Layer

`engines/benchmark-model.sh`

Responsibilities:

- hold benchmark configuration
- apply profile configuration
- validate the requested benchmark
- iterate workloads and repetitions
- call the executor
- expose report generation and report saving

The engine coordinates benchmark execution but does not implement provider-specific transport.

### API Layer

Public benchmark interfaces:

- `errors.sh`
- `results.sh`
- `providers.sh`
- `models.sh`
- `prompts.sh`
- `reporting.sh`

The API layer provides stable functions used by engines and applications.

### Core Layer

Internal implementation support:

- `definitions.sh`
- `types.sh`
- `validators.sh`
- `profile.sh`
- `executor.sh`

Core owns framework definitions, validation primitives, profile loading, and execution orchestration.

## Execution Flow

```text
CLI request
    ↓
profile defaults
    ↓
CLI overrides
    ↓
benchmark-model engine
    ↓
executor creates Result
    ↓
Result marked running
    ↓
provider request executed
    ↓
response and metrics captured
    ↓
Result completed or failed
    ↓
reporting consumes Result Repository
```

## Result Lifecycle

Supported states:

```text
created
running
completed
failed
skipped
timeout
cancelled
```

The Result Repository is the authoritative in-memory source for benchmark outcomes during a run.

## Provider Abstraction

Current public provider API:

```text
provider_exists
provider_available
provider_version
provider_models
provider_model_exists
provider_generate
provider_embeddings
```

Ollama is the current concrete provider implementation.

The architecture permits future providers such as:

```text
lmstudio
vllm
llamacpp
openai
claude
openrouter
```

## Workloads

Current workload set:

```text
reasoning
coding
summarization
extraction
classification
creative
embedding
```

Generation workloads read prompt files from:

```text
benchmarks/prompts/
```

Optional expected outputs may be stored under:

```text
benchmarks/expected/
```

Expected-output scoring is not yet part of M02.

## Profiles

Profiles provide benchmark defaults.

Supported configuration includes:

- iterations
- timeout
- workloads
- cold-start flag
- warm-start flag
- CPU measurement flag
- memory measurement flag

Precedence:

```text
framework defaults
    ↓
profile defaults
    ↓
explicit CLI overrides
```

## Reporting

Reporting consumes the Result Repository and currently provides:

- total results
- completed results
- failed results
- skipped results
- timeout results
- cancelled results
- average duration
- average tokens per second
- grouped field counts
- text output
- Markdown output
- JSON output
- CSV output

Future reporting enhancements include median, min/max, standard deviation, success rate, and richer grouped aggregates.

## Bash 3.2 Compatibility

The production host uses the macOS system Bash environment.

Framework constraints:

- no associative arrays
- no `declare -g`
- parallel indexed arrays for repositories
- explicit counters for empty-array safety under `set -u`
- shell return values limited to `0-255`

Framework error codes larger than `255` are stored as structured data rather than returned directly as shell exit statuses.

## Current-Shell Mutation Rule

Repository mutation must happen in the current shell.

Incorrect:

```bash
RESULT_ID="$(result_create ...)"
```

The function runs in a subshell, so repository mutations are lost.

Correct:

```bash
result_create ... >/dev/null
RESULT_ID="$RESULT_LAST_ID"
```

The same rule applies to sequence-based ID generation.

## Model Normalization

Provider model matching normalizes implicit `:latest` tags.

For example:

```text
nomic-embed-text
```

matches:

```text
nomic-embed-text:latest
```

## Current Limitations

- profile CPU and memory flags are defined but measurement is not yet fully implemented
- provider error repository mutations can be lost when provider calls are captured through command substitution
- provider transport timeouts are not yet consistently mapped to the `timeout` Result state
- expected-output scoring is not yet implemented

These limitations do not block the M02 benchmark baseline.

## Related documentation

- [Documentation map](../README.md)
