---
title: M02 - AI Runtime Layer
status: In Progress
version: 2.1
last_updated: 2026-07-13
---

## M02 - AI Runtime Layer

### Objective

Build a production-quality local AI runtime that is reproducible, observable, and resilient across system updates and reboots.

---

## Phase 1 - Runtime Foundation

- [x] Install Ollama
- [x] Verify runtime
- [x] Create runtime directory structure
- [x] Create configuration directory

---

## Phase 2 - Persistent Runtime Configuration

- [x] Configure Ollama model storage from Ollama app UI
- [x] Verify persistent model storage
- [ ] Document required application preferences
- [ ] Verify configuration after reboot

---

## Phase 3 - Service Validation

- [ ] Verify automatic startup
- [ ] Verify automatic recovery
- [ ] Verify API availability
- [ ] Verify logging

---

## Phase 4 - Health Monitoring

- [ ] verify-ollama.sh
- [ ] check-api.sh
- [ ] check-storage.sh
- [ ] check-runtime.sh

---

## Phase 5 - Production Models

- [ ] Install nomic-embed-text
- [ ] Install Gemma 3 12B
- [ ] Install Qwen3 14B

---

## Phase 6 - Benchmarking

- [ ] Cold start
- [ ] Warm start
- [ ] Tokens/sec
- [ ] Memory usage
- [ ] Concurrent requests

---

## Phase 7 - Production Validation

- [ ] Reboot validation
- [ ] Documentation review
- [ ] Milestone close
