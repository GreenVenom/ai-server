# Roadmap

## M01 — Foundation ✅

Status: Complete

Delivered:

- initial repository structure
- engineering principles
- documentation architecture
- system architecture documentation
- versioning and release structure
- core host setup
- secure administration foundation

## M02 — Production Ollama Runtime ✅

Status: Complete

Delivered:

- production Ollama runtime
- persistent local model storage
- reboot persistence
- local-only Ollama API binding
- validated primary generation models
- validated embedding model
- operational health and verification scripts
- provider-neutral Benchmark Framework
- structured Error Repository
- structured Result Repository
- model and prompt APIs
- profile-driven benchmark execution
- generation and embedding execution
- Markdown, JSON, CSV, and text reporting
- successful Qwen and Gemma benchmark paths
- benchmark validation test suite

Primary models:

```text
qwen3:14b
gemma4:12b
nomic-embed-text:latest
```

Architecture decisions:

```text
ADR-0007
ADR-0008
ADR-0009
```

## M03 — OpenClaw Platform ⏳

Status: Next

Objectives:

- install and configure OpenClaw
- define orchestration boundaries
- integrate local Ollama models
- establish model routing policy
- preserve local-first behavior
- define cloud fallback strategy
- integrate existing operations and health checks

## M04 — Qdrant ⏳

Objectives:

- deploy Qdrant
- define persistent storage
- configure collection lifecycle
- integrate `nomic-embed-text`
- establish retrieval validation

## M05 — Obsidian Integration ⏳

Objectives:

- connect Obsidian workflows to the AI platform
- define indexing boundaries
- support retrieval and assisted note workflows
- preserve user-controlled source data

## M06 — MCP Servers ⏳

Objectives:

- introduce MCP integrations
- define trust and permission boundaries
- validate local-first tool execution

## M07 — Monitoring ⏳

Objectives:

- runtime visibility
- service health
- benchmark trend tracking
- resource monitoring
- alerting strategy

## M08 — Backup & Disaster Recovery ⏳

Objectives:

- backup runtime configuration
- backup persistent data
- validate restore procedures
- document disaster recovery

## Future Work

Potential later milestones include:

- richer benchmark statistics
- multi-provider benchmark comparison
- automated baseline regression detection
- expanded local model routing
- additional retrieval and agent workflows
