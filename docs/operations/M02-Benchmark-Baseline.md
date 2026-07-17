---
title: M02 Benchmark Baseline
document: Operation
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: Personal AI Platform maintainers
---

# M02 Benchmark Baseline

## Purpose

This document records the initial benchmark environment and successful baseline execution completed during M02.

Generated benchmark reports are the authoritative detailed benchmark artifacts.

## Host

```text
Hardware     : Mac mini M4 Pro
Memory       : 24 GB unified memory
Storage      : 512 GB SSD
Service User : openclaw
```

## Runtime

```text
Provider     : Ollama
Ollama       : 0.31.2
API          : http://127.0.0.1:11434
Model Store  : ~/server/data/models/ollama
```

## Models

Generation:

```text
qwen3:14b
gemma4:12b
```

Embedding:

```text
nomic-embed-text:latest
```

## Baseline Profile

Primary comparison profile:

```text
standard
```

Current standard timeout:

```text
300 seconds
```

## Successful Benchmark Paths

The following primary generation models have completed successful benchmark runs:

```text
qwen3:14b
gemma4:12b
```

Multi-iteration Markdown report generation has also completed successfully for both models.

## Confirmed Qwen Reasoning Result

One confirmed single-iteration baseline:

```text
Model                : qwen3:14b
Provider             : ollama
Profile              : standard
Workload             : reasoning
Iterations           : 1
Timeout              : 300 seconds
Completed            : 1
Failed               : 0
Average Duration     : 134.796 seconds
Average Throughput   : 24.3 tokens/second
```

## Report Artifacts

Expected report locations:

```text
benchmarks/reports/qwen3-14b-reasoning-standard.md
benchmarks/reports/gemma4-12b-reasoning-standard.md
```

The exact multi-iteration metrics should be read from the generated report files rather than duplicated manually here.

## Validation Context

Before baseline collection, the benchmark test suite passed:

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

## Interpretation

The M02 baseline demonstrates:

- the production Ollama runtime is stable enough for repeated execution
- both primary local generation models are callable through the same provider-neutral benchmark path
- profile-controlled timeout behavior works
- benchmark results can be aggregated and exported
- the current Mac mini can complete the selected local reasoning workloads within the calibrated standard profile budget

## Follow-on Baseline Work

Future benchmark expansion may include:

- reasoning
- coding
- summarization
- extraction
- classification

for both:

```text
qwen3:14b
gemma4:12b
```

Future reporting should also add:

- minimum
- maximum
- median
- standard deviation
- success rate
- per-model aggregates
- per-workload aggregates

## Related documentation

- [Documentation map](../README.md)
