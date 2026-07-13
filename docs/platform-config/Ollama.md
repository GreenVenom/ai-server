---
title: Ollama Configuration
status: Active
last_updated: 2026-07-13
application: Ollama
version: 0.31.2
owner: Revan
---

## Ollama

### Purpose

Provides the local inference runtime for all Large Language Models used by the Personal AI Platform.

---

## Installation

Installation Method

- Official Ollama macOS Application

Version

- 0.31.2

Management

- Native macOS application
- Native launchd service

---

## Model Storage

Configured through the Ollama application preferences.

Current Location

```bash
/Users/openclaw/server/data/models/ollama
```

Verification

```bash
ollama list
```

Models should appear in:

```bash
~/server/data/models/ollama
```

---

## API

Host

```bash
127.0.0.1
```

Port

```bash
11434
```

Verification

```bash
curl http://127.0.0.1:11434/api/version
```

---

## Runtime

Managed By

```bash
com.ollama.ollama
```

Verification

```bash
launchctl list | grep ollama
```

---

## Logs

Application Logs

```bash
~/.ollama/logs/
```

Project Logs

```bash
~/server/logs/ollama/
```

---

## Production Models

Primary

- Qwen3 14B

Secondary

- Gemma 3 12B

Embeddings

- nomic-embed-text

---

## Recovery

1. Install Ollama.
2. Configure model directory.
3. Verify API.
4. Download production models.
5. Run benchmark suite.

---

## Notes

Use vendor-supported configuration whenever possible.

Do not modify vendor launchd services.
