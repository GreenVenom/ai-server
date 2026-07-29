---
title: 🧠 Personal AI Platform
document: Reference
status: Active
created: 2026-07-12
updated: 2026-07-28
platform_version: v0.8.0
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
M06  MCP Services                  ✅ Complete
M07  Obsidian Retrieval V2 Cutover ✅ Complete
M08  Backup & Disaster Recovery    ✅ Complete
M09  Future Plans                  🔜 Planned
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
├── config/
│   ├── mcp/                 # MCP configuration and development artifacts
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
├── scripts/
│   ├── config/
│   ├── lib/
│   ├── maintenance/
│   ├── profiles/
│   └── tests/
├── services/
│   ├── launchagents/
│   ├── mcp/                 # Local stdio MCP services and tests
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

Current architecture decisions include:

```text
ADR-0014  Authoritative Obsidian Vault and Read-Only Server Mirror
ADR-0015  Constrained OpenClaw Obsidian Retrieval Plugin
ADR-0016  Manifest-Driven Incremental Indexing and Deletion Safety
ADR-0017  Read-Only Obsidian Retrieval for OpenClaw
ADR-0018  First-Party Local STDIO MCP Servers
ADR-0019  MCP Tool Authorization and Exposure
ADR-0020  Read-Only Obsidian MCP Adapter
ADR-0021  MCP Tool Schemas, Errors, and Logging
ADR-0022  Obsidian Index V2 Cutover and V1 Rollback Retention
```

For the complete milestone-to-ADR mapping, see the [architecture index](docs/architecture/Architecture-Index.md).

## 🧱 Development Constraints

The production benchmark framework targets Bash 3.2 compatibility on macOS.

Important rules:

- no associative arrays
- no `declare -g`
- safe under `set -u`
- repository mutation must occur in the current shell

## 🚀 Current Release

v0.8.0 completes M08 with encrypted off-host backups for the active V2 Qdrant index and allow-listed non-secret runtime configuration. The automated backup job verifies checksums after upload and supports controlled restore validation without overwriting production data.

```text
Obsidian vault → read-only mirror → local embeddings → Qdrant → MCP retrieval → OpenClaw
```

The V1 collection and manifest remain read-only rollback data through the documented retention period. Validation confirmed encrypted upload/download integrity, a successful scheduled backup, and a restore into a separate Qdrant collection with matching point counts and manifest reconciliation. See the [M08 milestone record](docs/operations/milestones/M08-Backup-and-Disaster-Recovery.md), [ADR-0023](docs/decisions/ADR-0023-Encrypted-Google-Drive-Off-Host-Backups.md), [backup and recovery runbook](docs/operations/Backup-and-Recovery-Runbook.md), and [v0.8.0 release notes](docs/releases/v0.8.0.md).

## 🚧 Next Milestone

M09 — Future Plans is reserved for future platform work; its scope will be recorded before implementation begins.

## 🔗 Related documentation

- [Documentation map](docs/README.md)
