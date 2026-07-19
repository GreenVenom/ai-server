---
title: 🧠 Personal AI Platform
document: Reference
status: Active
created: 2026-07-12
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# 🧠 Personal AI Platform

A production-quality, local-first personal AI platform running on a Mac mini M4 Pro.

The platform is designed to keep routine inference and data processing local while preserving the option to use cloud models when larger capabilities are required.

## 📍 Current Status

```text
M01  Foundation                    ✅ Complete
M02  Production Ollama Runtime     ✅ Complete
M03  OpenClaw Platform             ✅ Complete
M04  Qdrant                        ✅ Complete
M05  Obsidian Integration          ✅ Complete
M06  MCP Servers                   🚧 Next
M07  Monitoring                    🔜 Planned
M08  Backup & Disaster Recovery    🔜 Planned
```

## ⚙️ Current Runtime

```text
Host        : Mac mini M4 Pro
Memory      : 24 GB
Provider    : Ollama
API         : http://127.0.0.1:11434
Service     : com.ollama.ollama
Model Store : ~/server/data/models/ollama
OpenClaw    : 2026.7.1 (loopback Gateway, Docker sandbox)
Qdrant      : 1.18.2 (loopback REST and gRPC, Docker Compose)
```

## 🤖 Models

Generation:

```text
qwen3:14b
gemma4:12b
```

Embedding:

```text
nomic-embed-text:latest
```

## 🎯 Project Goals

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

## 🗂️ Repository Structure

```text
ai-server/
├── backups/                 # Runtime backup destination
├── benchmarks/              # Benchmark runner, libraries, profiles, prompts, and tests
├── bootstrap/               # Host and service bootstrap scripts
├── configs/
│   └── obsidian/            # Vault registration and mirror configuration
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── engineering/
│   ├── glossary/
│   ├── operations/
│   │   ├── milestones/
│   │   └── runbooks/
│   ├── platform-config/
│   ├── releases/
│   └── templates/
├── infrastructure/          # Docker, launchd, SSH, and Tailscale definitions
├── inventory/               # Hardware and environment inventory
├── logs/                    # Runtime logs
├── mcp/                     # MCP server work area
├── scripts/
│   ├── config/
│   ├── lib/
│   ├── maintenance/
│   ├── profiles/
│   └── tests/
├── services/
│   ├── launchagents/
│   ├── obsidian/
│   └── openclaw-obsidian-plugin/
└── templates/               # Repository-level reusable templates
```

## 📚 Documentation

Start with the [documentation map](docs/README.md). New or substantially revised documentation should follow the [documentation standards](docs/templates/Documentation-Standards.md).

## 🛠️ Operations

Primary operational validation:

```bash
./scripts/doctor.sh
./scripts/status.sh
./scripts/health.sh
./scripts/verify.sh
```

## 📊 Benchmarking

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
docs/operations/runbooks/Running-Benchmarks.md
docs/operations/runbooks/Benchmark-Validation.md
```

## 🧭 Architecture Decisions

Current benchmark architecture decisions include:

```text
ADR-0007  Layered Benchmark Framework
ADR-0008  Standardized Error Framework
ADR-0009  Standardized Repository Pattern
```

## 🧱 Development Constraints

The production benchmark framework targets Bash 3.2 compatibility on macOS.

Important rules:

- no associative arrays
- no `declare -g`
- safe under `set -u`
- repository mutation must occur in the current shell

## 🚀 Current Release

v0.5.0 completes M05 and adds controlled Obsidian knowledge retrieval. The platform maintains a read-only mirror of an authoritative vault, parses and chunks Markdown, creates local Ollama embeddings, indexes them in Qdrant, and exposes constrained retrieval through OpenClaw's `obsidian_search` tool.

```text
Obsidian vault → read-only mirror → local embeddings → Qdrant → OpenClaw
```

Operational safeguards include deterministic manifests, incremental reconciliation, deletion thresholds, scheduled synchronization, health checks, source-grounded results, and snapshot-backed backups. See the [M05 milestone record](docs/operations/milestones/M05-Obsidian-Integration.md) and [v0.5.0 release notes](docs/releases/v0.5.0.md).

## 🚧 Next Milestone

M06 introduces narrow MCP interfaces over approved platform capabilities, beginning with the M05 Obsidian retrieval boundary.

## 🔗 Related documentation

- [Documentation map](docs/README.md)
