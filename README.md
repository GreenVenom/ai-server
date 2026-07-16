# Personal AI Platform

A production-quality, local-first personal AI platform running on a Mac mini M4 Pro.

The platform is designed to keep routine inference and data processing local while preserving the option to use cloud models when larger capabilities are required.

## Current Status

```text
M01  Foundation                    Complete
M02  Production Ollama Runtime     Complete
M03  OpenClaw Platform             Complete
M04  Qdrant                        Next
M05  Obsidian Integration          Planned
M06  MCP Servers                   Planned
M07  Monitoring                    Planned
M08  Backup & Disaster Recovery    Planned
```

## Current Runtime

```text
Host        : Mac mini M4 Pro
Memory      : 24 GB
Provider    : Ollama
API         : http://127.0.0.1:11434
Service     : com.ollama.ollama
Model Store : ~/server/data/models/ollama
OpenClaw    : 2026.7.1 (loopback Gateway, Docker sandbox)
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

## Project Goals

- local-first AI execution
- minimal cloud dependency
- provider-neutral architecture
- secure remote administration
- reproducible operations
- Obsidian integration
- vector retrieval with Qdrant
- OpenClaw orchestration
- MCP server integration
- observable and recoverable services

## Repository Structure

```text
docs/
├── architecture/
├── decisions/
├── glossary/
├── milestones/
├── operations/
├── platform-config/
├── releases/
├── runbooks/
└── templates/

benchmarks/
├── benchmark.sh
├── engines/
├── lib/
│   ├── api/
│   └── core/
├── profiles/
├── prompts/
├── expected/
├── results/
├── reports/
└── tests/

configs/
infrastructure/
scripts/
services/
```

## Documentation

Start with the [documentation map](docs/README.md). New or substantially revised documentation should follow the [documentation standards](docs/templates/Documentation-Standards.md).

## Operations

Primary operational validation:

```bash
./scripts/doctor.sh
./scripts/status.sh
./scripts/health.sh
./scripts/verify.sh
```

## Benchmarking

List available models:

```bash
./benchmarks/benchmark.sh --list-models
```

Run a benchmark:

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 3
```

Save a Markdown report:

```bash
./benchmarks/benchmark.sh \
  --model qwen3:14b \
  --profile standard \
  --workload reasoning \
  --iterations 3 \
  --format markdown \
  --output benchmarks/reports/qwen3-14b-reasoning-standard.md
```

## Benchmark Architecture

```text
benchmark.sh
    ↓
benchmark-model.sh
    ↓
profile.sh
executor.sh
    ↓
prompts.sh
models.sh
providers.sh
results.sh
errors.sh
reporting.sh
```

See:

```text
docs/architecture/Benchmark-Framework.md
docs/architecture/Benchmark-Profiles.md
docs/architecture/Error-Framework.md
docs/architecture/Repository-Pattern.md
docs/runbooks/Running-Benchmarks.md
docs/runbooks/Benchmark-Validation.md
```

## Architecture Decisions

Current benchmark architecture decisions include:

```text
ADR-0007  Layered Benchmark Framework
ADR-0008  Standardized Error Framework
ADR-0009  Standardized Repository Pattern
```

## Development Constraints

The production benchmark framework targets Bash 3.2 compatibility on macOS.

Important rules:

- no associative arrays
- no `declare -g`
- safe under `set -u`
- repository mutation must occur in the current shell

## Current Release

v0.3.0 completes M03 and adds the OpenClaw orchestration layer. See the [M03 milestone record](docs/milestones/M03-OpenClaw-Platform.md) and [v0.3.0 release notes](docs/releases/v0.3.0.md).

## Next Milestone

M04 introduces Qdrant as the local vector database and retrieval foundation.
