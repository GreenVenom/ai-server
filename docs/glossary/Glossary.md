---
title: Platform Glossary
document: Reference
status: Active
created: 2026-07-13
updated: 2026-07-13
platform_version: v0.2.0
owner: Revan
version: 1.0
---

# Platform Glossary

## Purpose

This glossary defines the standard terminology used throughout the Personal AI Platform documentation.

The glossary exists to ensure consistency across:

* Architecture documentation
* Milestones
* ADRs
* Runbooks
* Configuration guides
* Release notes

Where multiple terms could describe the same concept, the preferred term is identified here.

---

## Naming Conventions

| Preferred Term         | Avoid                                          |
| ---------------------- | ---------------------------------------------- |
| Platform               | Server, Machine                                |
| Platform Configuration | Settings                                       |
| Runbook                | Instructions                                   |
| Milestone              | Phase                                          |
| Operations Framework   | Utility Scripts                                |
| Component              | Program                                        |
| Service                | Process (when referring to managed software)   |
| Health Check           | Status Script                                  |
| Repository             | Project Folder                                 |
| Platform Version       | Build                                          |
| Release                | Snapshot                                       |
| Architecture           | Design (when referring to the complete system) |

---

## Platform Concepts

### Platform

The complete Personal AI Platform, including hardware, operating system, infrastructure services, AI services, documentation, and operational tooling.

This is the preferred term for the overall system.

---

### Platform Version

The released state of the platform.

Versions follow Semantic Versioning.

Example:

v0.2.0

---

### Milestone

A planned body of work that introduces a major platform capability.

Each milestone has:

* Objectives
* Deliverables
* Validation
* Documentation
* Exit criteria

Milestones correspond to minor platform versions.

---

### Release

A completed platform version.

Each release includes:

* Documentation updates
* Validation
* Git tag
* Release notes

---

### Repository

The Git repository that serves as the authoritative source for platform documentation, scripts, and configuration.

---

## Architecture Section

### Architecture

The overall structure of the platform.

Architecture defines:

* Components
* Responsibilities
* Relationships
* Data flow
* Operational boundaries

---

### Architecture Decision Record (ADR)

A permanent engineering record describing a significant architectural decision.

An ADR contains:

* Context
* Decision
* Alternatives
* Consequences
* Rationale

ADRs are never rewritten. Future decisions supersede earlier ADRs when necessary.

---

### Layer

A logical boundary within the platform architecture.

Current layers include:

* Applications
* AI Services
* Infrastructure Services
* Operating System
* Hardware

---

### Component

A discrete functional unit within the platform.

Examples include:

* Ollama
* OpenClaw
* Docker Desktop
* Qdrant
* Tailscale

---

### Dependency

A required component, service, or capability that another component relies upon.

Dependencies should be explicitly documented.

---

## Operations

### Operations Framework

The collection of scripts, tooling, and procedures used to operate the platform.

Responsibilities include:

* Health verification
* Benchmarking
* Maintenance
* Backup
* Recovery
* Updates

---

### Runbook

A documented operational procedure.

Runbooks describe how to perform recurring operational tasks safely and consistently.

Examples:

* Updating Ollama
* Restoring backups
* Health verification

---

### Health Check

A repeatable validation used to verify that a component or service is operating correctly.

Health checks should be deterministic and scriptable.

---

### Validation

The process of confirming that a component behaves as expected.

Validation may include:

* Functional testing
* Performance testing
* Operational testing
* Security verification

---

### Benchmark

A repeatable measurement of platform performance.

Benchmarks establish baseline performance and help detect regressions after upgrades.

---

### Observability

The ability to understand the current state of the platform using logs, metrics, health checks, and monitoring tools.

---

### Incident

Any unexpected event that disrupts normal platform operation.

Incidents should be documented and resolved using established runbooks where possible.

---

## Infrastructure

### Infrastructure as Code (IaC)

The practice of managing platform configuration through version-controlled files and automation rather than undocumented manual changes.

---

### Platform Configuration

Configuration files, settings, and environment values that define platform behavior.

Platform configuration should be documented and recoverable.

---

### Service

A managed software component that provides a long-running capability.

Examples:

* Ollama
* OpenClaw
* Qdrant

---

### Runtime

The environment in which a service executes.

Examples include:

* Native macOS service
* Docker container

---

### Container

An isolated runtime environment managed by Docker.

Containers package software together with its runtime dependencies.

---

### Volume

Persistent storage used by containers or services.

Volumes preserve data independently of the application lifecycle.

---

## Artificial Intelligence

### Model

A machine learning model capable of performing inference.

Examples include language models and embedding models.

---

### Inference

The process of generating output from a model using a supplied prompt or input.

---

### Embedding

A numerical representation of data that enables semantic similarity search.

Embeddings are typically stored in a vector database.

---

### Vector Database

A database optimized for storing and searching embeddings.

Qdrant is the planned vector database for the platform.

---

### Context Window

The amount of information a model can consider during a single inference request.

---

### Token

A unit of text processed by a language model.

Model performance is commonly measured in tokens per second.

---

### Local Model

A model executed entirely on platform hardware without relying on external AI providers.

---

### Cloud Model

A model hosted by an external provider and accessed through an API.

Cloud models complement local models when additional capability is required.

---

### MCP (Model Context Protocol)

A standardized interface that enables AI applications to communicate with external tools, services, and knowledge sources.

Planned MCP integrations include:

* Obsidian
* GitHub
* Filesystem
* Browser
* Calendar

---

## Security

### Principle of Least Privilege

Users and services receive only the permissions required to perform their intended functions.

---

### Service Account

A dedicated operating system account used to run platform services.

The platform uses a dedicated `openclaw` account for AI-related services.

---

### SSH Hardening

The process of improving SSH security by reducing attack surface and enforcing secure authentication methods.

---

### Secure by Default

An engineering philosophy in which the default configuration favors security without requiring additional manual configuration.

---

## Documentation

### Charter

The highest-level document describing why the platform exists and the principles that guide its evolution.

---

### Engineering Principles

The document defining how engineering decisions are made throughout the platform.

---

### Milestone Definition

A documented implementation phase that introduces new platform capabilities.

---

### Template

A reusable document used to ensure consistency across the repository.

---

### Release Notes

A summary of changes introduced in a platform version.

---

### Revision History Definition

A record of document changes over time.

---

## Repository Standards

The repository should remain:

* Consistent
* Reproducible
* Well documented
* Version controlled
* Self-contained
* Easy to navigate

Documentation should always prioritize clarity over brevity.

---

## Related Documentation

* Platform Charter
* Engineering Principles
* Architecture
* Milestones
* ADRs
* Runbooks
* VERSION.md
* ROADMAP.md

---

## Revision History

| Version | Date       | Author | Changes          |
| ------- | ---------- | ------ | ---------------- |
| 1.0     | 2026-07-13 | Revan  | Initial glossary |
