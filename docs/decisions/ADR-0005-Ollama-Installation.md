---
title: Official Ollama Installation
status: Accepted
date: 2026-07-12
decision_id: ADR-0005
supersedes:
superseded_by:
---

## ADR-0005: Official Ollama Installation

## Status

Accepted

---

## Context

The AI server requires a reliable, maintainable, and reproducible inference runtime for local large language models.

Two installation options were considered:

1. Install Ollama using Homebrew and manage it with `brew services`.
2. Install Ollama using the official upstream installation method provided by the Ollama project and manage the service independently.

Initially, Homebrew was preferred due to its package management and service integration.

After evaluating the long-term architecture of the server, this approach was reconsidered.

---

## Decision

The server will use the **official Ollama installation** provided by the Ollama project.

Service management, configuration, logging, and operational behavior will be managed independently through infrastructure maintained in this repository.

The installation method and the service management layer are intentionally treated as separate concerns.

---

## Rationale

Using the official installation provides several advantages:

- Receives upstream releases immediately.
- Avoids dependency on Homebrew packaging schedules.
- Uses the installation method recommended by the Ollama developers.
- Simplifies compatibility with Apple Silicon.
- Reduces external packaging dependencies.

Managing the runtime separately provides:

- Version-controlled infrastructure.
- Standardized logging.
- Controlled environment variables.
- Automated startup and recovery.
- Consistent deployment procedures.

---

## Consequences

### Positive

- Native installation supported by Ollama.
- Fully controlled runtime configuration.
- Infrastructure remains reproducible.
- Easy recovery from repository documentation.
- Independent of Homebrew service definitions.

### Negative

- Service definitions are maintained by this repository.
- Updates require following the documented runbook.

---

## Alternatives Considered

### Homebrew Installation

Advantages

- Integrated package management.
- `brew services` support.

Disadvantages

- Dependent on Homebrew packaging.
- Less control over service implementation.
- Adds another infrastructure dependency.

---

## Future Considerations

Future runtime enhancements may include:

- Runtime metrics
- Resource monitoring
- Automated updates
- Service health monitoring
- Multiple inference runtimes

These improvements should not require changing the installation method.

---

## References

- M02 - AI Runtime Layer
- Install-Ollama.md
- Update-Ollama.md
