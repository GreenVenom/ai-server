---
title: OpenClaw Security Baseline
document: Architecture
status: Active
created: 2026-07-17
updated: 2026-07-17
platform_version: v0.3.0
owner: GreenVenom
---

# OpenClaw Security Baseline

## Gateway

```text
Bind:               loopback
Port:               18789
Authentication:     token
Tailscale exposure: off
Reverse proxy:      none
```

`gateway.trustedProxies` remains unset because no reverse proxy is deployed.

## Control UI

Insecure Control UI authentication is disabled. The dashboard remains local-only unless an explicit tunnel is created.

## Models

```text
Primary:  ollama/gemma4:12b
Fallback: ollama/qwen3:14b
```

No cloud model is configured.

## Memory Search

```text
agents.defaults.memorySearch.enabled = false
```

Local retrieval will be addressed in the Qdrant milestone.

## Web and Browser Tools

Disabled globally:

```text
group:web
browser
```

## Sandbox

```text
agents.defaults.sandbox.mode = all
agents.defaults.sandbox.workspaceAccess = rw
```

The only read-write host path exposed to the main agent is the dedicated productive workspace.

## Elevated Execution

```text
tools.elevated.enabled = false
```

## Audit Status

Latest known state:

```text
0 critical
2 warnings
2 informational
```

Accepted warnings:

- missing trusted proxies: accepted because the Gateway is loopback-only and no proxy exists
- missing `operator.read`: accepted because it limits deep diagnostics but not normal operation

## Completion Criteria

```text
[x] Gateway loopback-only
[x] Token authentication enabled
[x] Insecure Control UI auth disabled
[x] Web/browser tools disabled
[x] Sandbox mode all
[x] Elevated execution disabled
[x] Dedicated workspace boundary
[x] Local models only
[x] Cloud memory search disabled
[x] Zero critical security findings
```

## Related documentation

- [Documentation map](../README.md)
