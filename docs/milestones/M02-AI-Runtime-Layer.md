---
title: M02 - AI Runtime Layer
status: In Progress
version: 2.0
last_updated: 2026-07-12
---

## M02 - AI Runtime Layer

## Objective

Establish a production-quality local AI inference layer that provides reliable, maintainable, and reproducible model execution for all future AI services.

This milestone creates the runtime foundation upon which OpenClaw, Qdrant, Obsidian integrations, and future automation will rely.

---

## Success Criteria

- [ ] Native Ollama installation documented
- [ ] Dedicated runtime directory structure
- [ ] Models stored under `~/server/data/models/ollama`
- [ ] Managed launchd service
- [ ] Automatic startup after reboot
- [ ] Automatic restart after failure
- [ ] Structured logging
- [ ] Health-check framework
- [ ] Operational runbooks completed
- [ ] Production models installed
- [ ] Benchmarks recorded
- [ ] Reboot verification completed

---

## Scope

### Included

- Ollama runtime
- launchd service
- Logging
- Configuration
- Health monitoring
- Model management
- Documentation
- Benchmarking

### Excluded

- OpenClaw
- Qdrant
- Obsidian integration
- MCP Servers
- Monitoring dashboards

---

## Deliverables

### Runtime

- Native Ollama installation
- Managed launchd service

---

### Configuration

```bash
~/server/config/ollama/
```

---

## Models

```bash
~/server/data/models/ollama/
```

---

## Logs

```bash
~/server/logs/ollama/

service.log
service-error.log
benchmark.log
health.log
```

---

## Scripts

```bash
~/server/scripts/

verify-ollama.sh
check-service.sh
check-api.sh
check-storage.sh
check-config.sh
check-network.sh
```

---

## Runbooks

```bash
docs/runbooks/

Install-Ollama.md
Configure-Ollama.md
Update-Ollama.md
Recover-Ollama.md
Benchmark-Ollama.md
Verify-Ollama.md
```

---

## Model Strategy

### Primary Model

Qwen3 14B

Purpose:

- General reasoning
- Planning
- Knowledge work

---

### Secondary Model

Gemma 3 12B

Purpose:

- Coding
- Structured tasks
- Fast responses

---

### Embedding Model

nomic-embed-text

Purpose:

- Semantic search
- Qdrant
- Obsidian
- Retrieval Augmented Generation

---

## Implementation Plan

### Phase 1

- [x] Create runtime directory structure
- [ ] Create launchd service
- [ ] Configure runtime environment
- [ ] Configure logging

---

### Phase 2

- [ ] Build health-check framework
- [ ] Build verification scripts
- [ ] Document operational procedures

---

### Phase 3

- [ ] Download production models
- [ ] Validate model loading
- [ ] Record disk utilization

---

### Phase 4

- [ ] Execute benchmark suite
- [ ] Record latency
- [ ] Record throughput
- [ ] Record memory utilization

---

### Phase 5

- [ ] Reboot server
- [ ] Verify automatic startup
- [ ] Verify health checks
- [ ] Close milestone

---

## Verification Checklist

### Runtime Checklist

- [ ] Service starts automatically
- [ ] Service restarts automatically
- [ ] API available

---

### Configuration Checklist

- [ ] Environment variables loaded
- [ ] Configuration documented

---

### Storage

- [ ] Model directory configured
- [ ] Logs written correctly

---

### Validation

- [ ] Models load successfully
- [ ] Benchmarks completed
- [ ] Reboot successful

---

## Rollback Plan

If deployment fails:

1. Stop the launchd service.
2. Restore previous configuration.
3. Validate Ollama manually.
4. Restore documented configuration.
5. Re-run verification.

---

## Lessons Learned

(To be completed during implementation.)

---

## Future Improvements

- Multiple inference runtimes
- Runtime metrics
- Resource dashboards
- Automatic model updates
- Performance history
- Distributed inference

---

## Dependencies

Completed

- M01 - Foundation

Future

- M03 - OpenClaw Platform
- M04 - Knowledge Layer
- M05 - MCP Services

---

## References

- ADR-0003
- ADR-0004
- ADR-0005
