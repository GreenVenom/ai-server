# Project Plan

This is a plan for my personal AI server.
My goal would be to make it something that you can leave running for months, update safely, recover from backups, and expand over time.

---

## Overall Architecture

Here's the architecture I would build:

```text
                           Main Workstation
                    (Obsidian / VS Code / Browser)
                                 │
                           Tailscale VPN
                                 │
                     ┌──────────────────────┐
                     │     Mac mini M4 Pro  │
                     ├──────────────────────┤
                     │ SSH                  │
                     │ Ollama               │
                     │ OpenClaw             │
                     │ Qdrant               │
                     │ Docker               │
                     │ MCP Servers          │
                     │ launchd Services     │
                     │ Time Machine         │
                     └──────────────────────┘
```

Every service should have:

* one purpose
* one configuration location
* one log location
* one backup location

---

## Phase 2 — SSH Hardening (Next Priority)

Before adding anything else, I'd lock down SSH.

### 1. Create a new Ed25519 key

On your primary workstation (the computer you'll SSH **from**):

```bash
ssh-keygen -t ed25519 -a 100
```

Use a passphrase.

---

### 2. Copy the key

```bash
ssh-copy-id ai@<tailscale-name>
```

or manually append the public key to:

```text
~/.ssh/authorized_keys
```

for the AI account.

---

### 3. Verify key login

Before changing any SSH settings, make sure you can log in with the key and no password prompt.

---

### 4. Harden `sshd`

Edit:

```text
/etc/ssh/sshd_config
```

I would recommend these settings:

```text
PermitRootLogin no

PasswordAuthentication no

ChallengeResponseAuthentication no

PubkeyAuthentication yes

MaxAuthTries 3

X11Forwarding no

AllowUsers ai
```

This means:

* only the AI account can SSH in
* only with an SSH key
* root cannot log in remotely
* no password logins

Always keep an existing SSH session open while testing new settings so you can recover if you make a mistake.

---

## Phase 3 — Directory Layout

I like to separate **configuration**, **data**, and **logs**.

For example:

```text
~/server/
│
├── config/
│
├── data/
│
├── logs/
│
├── backups/
│
├── docker/
│
├── services/
│
└── scripts/
```

Then:

```text
config/
    openclaw/
    qdrant/
    docker/

data/
    embeddings/
    indexes/
    models/

logs/
    openclaw/
    ollama/
```

This pays dividends later when you need to back up or migrate.

---

## Phase 4 — Service Management

Rather than launching things manually from Terminal, I would use **launchd** (the native macOS service manager).

For each long-running service:

* Ollama
* OpenClaw
* future automation

create a LaunchAgent (or LaunchDaemon if truly needed).

Benefits:

* automatic startup
* automatic restart
* logging
* no Terminal window required

---

## Phase 5 — Docker Philosophy

I would keep Docker for **supporting services**, not everything.

For example:

```text
Docker

Qdrant

Postgres (future)

Redis (future)

Grafana (future)

Prometheus (future)
```

Keep Ollama running natively on macOS. It performs well that way and is simpler to manage.

---

## Phase 6 — Backups

I'd separate backups into tiers.

### Daily

Configuration

```text
~/server/config
```

### Weekly

Docker volumes

### Continuous

Time Machine

### Optional

Git repository for your configuration files.

Infrastructure as code makes rebuilding much easier.

---

## Phase 7 — Monitoring

Later I'd add:

* Grafana
* Prometheus
* Uptime Kuma

These let you answer questions like:

* Is Ollama running?
* Is OpenClaw responding?
* Is disk usage growing?
* Is RAM under pressure?

---

## Phase 8 — Obsidian Integration

Eventually:

```text
Obsidian

↓

OpenClaw

↓

Qwen
Gemma
Embeddings

↓

Qdrant
```

The Mac mini becomes your "knowledge engine."

---

## Phase 9 — Model Strategy

I still think this is the right mix:

Primary

* Qwen3 14B

Secondary

* Gemma 3 12B

Embeddings

* A dedicated embedding model

Fallback

* Claude Sonnet

This keeps cloud usage low while giving you a high-quality fallback for exceptional tasks.

---

## Phase 10 — Future Expansion

Because you've chosen the M4 Pro, I would also plan for:

* Voice interaction
* Calendar integration
* Email assistant
* GitHub automation
* Home Assistant integration
* D&D campaign management
* Obsidian semantic search
* Automated meeting summaries

All can fit naturally into the same architecture over time.



---

This is shaping up very well. The decisions you've made are consistent and give us a solid foundation to build on.

A few observations based on what you've shared:

* **Ollama 0.31.2** is a good, current version.
* `which ollama` returning `/usr/local/bin/ollama` tells me it's on your PATH and accessible from the AI account.
* Having **no models downloaded yet** is actually ideal—we can choose the right ones and organize storage before anything gets pulled.
* I really like the `~/server` directory layout. It's clean and separates configuration, data, logs, and scripts.

## One change I would make

I'd add one more top-level directory:

```text
~/server/
│
├── config/
├── data/
├── logs/
├── backups/
├── docker/
├── services/
├── scripts/
└── runbooks/
```

The `runbooks/` directory is for operational procedures that live **on the server** (while the Git repo holds the canonical versions). Things like:

* Recover from backup
* Update Ollama
* Rotate SSH keys
* Restart OpenClaw
* Upgrade Docker services

Having a local copy can be useful if you're SSH'd into the server and need instructions without switching back to your workstation.

---

# One thing we should decide now: where Ollama stores models

By default, Ollama stores models under:

```text
~/.ollama/
```

That's perfectly fine for many users, but for a server like yours, I would rather keep large AI assets under your organized data hierarchy.

For example:

```text
~/server/data/models/ollama/
```

That makes it much clearer what should be backed up (or intentionally excluded from backups) and keeps your home directory tidy.

**However, I would not move anything yet.**

Since you haven't downloaded any models, this is the perfect time to decide whether we want to leave the default location or reconfigure it before the first download.

---

# The architecture I'd like us to build

Here's the target state I have in mind:

```text
                    Windows Workstation
              VS Code / Obsidian / Browser
                         │
                  SSH + Tailscale
                         │
                ┌──────────────────┐
                │  Mac mini M4 Pro │
                ├──────────────────┤
                │ launchd          │
                │   ├── Ollama     │
                │   ├── OpenClaw   │
                │   └── Future Jobs│
                │                  │
                │ Docker           │
                │   ├── Qdrant     │
                │   ├── Grafana    │
                │   └── Uptime Kuma│
                └──────────────────┘
```

Everything should either be managed by **launchd** (native services) or **Docker Compose** (containerized services).

---

# I think we should slow down before downloading models

The next thing I'd like to do isn't download Qwen or Gemma yet.

Instead, I'd like to make Ollama **production ready**.

That means answering a few questions:

### 1. Where will models live?

Default:

```text
~/.ollama/models
```

or

```text
~/server/data/models/ollama
```

### 2. How will Ollama be managed?

Right now it's likely being started manually or by the app.

I'd prefer it to be a managed service that:

* starts on boot,
* restarts if it crashes,
* has predictable logging,
* and is documented in your repository.

### 3. How will we update Ollama?

We'll document a standard process:

1. Check release notes.
2. Update.
3. Verify version.
4. Run a health check.
5. Test model inference.

That becomes a runbook in your Git repository.

---

# After that, we download models

Given your goals (minimal cloud usage, OpenClaw, Obsidian, D&D workflows), I'd recommend starting with:

1. **Qwen3 14B** – Primary reasoning model.
2. **Gemma 3 12B** – Strong secondary model, especially for coding and structured tasks.
3. **A dedicated embedding model** such as `nomic-embed-text` for semantic search and retrieval.

This gives OpenClaw meaningful choices without overwhelming your 24 GB of unified memory.

---

# One recommendation I'd like to make

I think we're at the point where we should formalize the project into **versioned milestones**.

For example, in your Git repository:

```text
docs/
└── milestones/
    ├── M01-Foundation.md
    ├── M02-Ollama.md
    ├── M03-OpenClaw.md
    ├── M04-Qdrant.md
    ├── M05-Obsidian.md
    └── M06-MCP.md
```

Each milestone would include:

* **Objectives** (what we're trying to achieve)
* **Prerequisites**
* **Implementation steps**
* **Verification checklist**
* **Rollback plan**
* **Lessons learned**

This makes the project easier to track and gives you a documented history of how the platform evolved.

## My proposal for the next phase

I'd like our next session to focus entirely on **Milestone M02: Productionizing Ollama**.

We'll:

1. Decide on the model storage location.
2. Configure Ollama as a managed service.
3. Add health checks and logs.
4. Create update and recovery runbooks.
5. Download and benchmark your first models.
6. Commit everything to your infrastructure repository.

Once M02 is complete, installing OpenClaw becomes straightforward because it can rely on a stable, well-documented model runtime rather than an ad hoc installation. I think that's the cleanest path to the long-term, low-maintenance AI platform you're aiming for.



I think we've reached the point where it's worth treating this as a real engineering project rather than a collection of setup tasks. The choices you've made are consistent with your original goals:

* **Local-first AI**
* **Minimal Claude usage**
* **Everything reachable over Tailscale**
* **Reproducible infrastructure**
* **Maintainable for years**

I also agree with all three of your decisions:

1. **Models:** `~/server/data/models/ollama`
2. **Service management:** `launchd` with automatic restart, boot startup, logging, and health verification.
3. **Updates:** Controlled, documented, and repeatable.

I wouldn't change any of those.

---

# One Architectural Recommendation

I would make one small addition before we start building services.

Inside your repository, I'd create a standard document template that every milestone follows.

```text
docs/
├── architecture/
├── milestones/
├── runbooks/
├── decisions/
└── templates/
      milestone-template.md
```

I also like documenting architectural decisions as ADRs (Architecture Decision Records). For example:

```text
docs/decisions/
ADR-0001-Separate-AI-Account.md
ADR-0002-Tailscale-Only.md
ADR-0003-Ollama-Model-Location.md
ADR-0004-launchd-vs-Docker.md
```

Six months from now, you won't remember *why* you made every decision. The ADRs preserve that context.

---

# M01 – Foundation

This milestone is already complete, but it should document exactly what was built and how to verify it.

It should include:

## Objectives

* Secure the Mac mini.
* Separate administrative and AI workloads.
* Establish remote administration.
* Create reproducible infrastructure.
* Prepare the platform for AI services.

---

## Deliverables

### Hardware

* Mac mini M4 Pro
* 24 GB RAM
* Apple Silicon

---

### Operating System

* macOS fully updated
* Automatic updates enabled

---

### Security

* FileVault enabled
* Firewall enabled
* SSH hardened
* Password authentication disabled
* Ed25519 keys
* Root login disabled
* AI account limited through `AllowUsers`
* Tailscale configured

---

### Accounts

Admin account

* System maintenance
* Homebrew ownership
* OS updates

AI account

* Standard user
* Runs all AI services
* SSH login

---

### Development Environment

* Homebrew
* Docker Desktop
* Xcode CLI
* Rosetta 2
* Git

---

### Repository

* Private GitHub repository
* Infrastructure documentation
* Bootstrap scripts
* Inventory
* Runbooks

---

## Verification Checklist

Something like:

```text
□ FileVault enabled

□ Firewall enabled

□ SSH key authentication works

□ Password login disabled

□ Tailscale connected

□ Docker starts

□ Homebrew works

□ Git configured

□ Repository synchronized
```

---

## Lessons Learned

I'd record things like:

* AI account initially wasn't authorized for Remote Login.
* Windows OpenSSH doesn't support `UseKeychain`.
* Homebrew ownership intentionally remains with the admin account.
* Infrastructure should always be documented before changes.

Those little notes become surprisingly valuable.

---

# M02 – Productionizing Ollama

This is where the interesting work begins.

I would break it into six sections.

---

## Objective

Transform Ollama from "installed software" into a managed production service.

---

## Deliverables

### Directory Layout

```
~/server/
    config/
    data/
        models/
            ollama/
    logs/
        ollama/
```

---

### launchd Service

Automatically:

* starts on boot
* restarts after crashes
* logs output
* managed without Terminal

---

### Model Storage

Move to

```
~/server/data/models/ollama
```

instead of the default location.

---

### Logging

Dedicated logs under

```
~/server/logs/ollama/
```

---

### Health Checks

A script that verifies:

* Ollama running
* API reachable
* models available
* sufficient disk
* sufficient memory

---

### Update Procedure

Document:

1. Stop service.
2. Update.
3. Restart.
4. Verify version.
5. Test inference.
6. Record update in Build Log.

---

## Model Strategy

Initial deployment:

Primary

* Qwen3 14B

Secondary

* Gemma 3 12B

Embeddings

* nomic-embed-text

---

## Performance Benchmarks

Record:

* First-token latency
* Tokens/sec
* RAM usage
* CPU usage
* Prompt length

This gives us a baseline before OpenClaw is introduced.

---

## Verification

```
□ Starts after reboot

□ API responds

□ Models load

□ Logs written

□ Health script passes

□ Benchmark recorded
```

---

# Then M03

After M02, the next milestone almost writes itself.

```
M03

Install OpenClaw

↓

Configure Providers

↓

Model Routing

↓

Tool Calling

↓

Persistent Configuration

↓

launchd
```

---

# Here's One Thing I'd Change

This is the only major change I'd make to the overall project.

I think we should stop thinking of Ollama as "the AI."

Instead, think of it as **infrastructure**.

Your actual AI platform becomes:

```
                 OpenClaw
                      │
      ┌───────────────┼───────────────┐
      │               │               │
  Qwen3          Gemma3         Future Models
      │               │
      └────── Ollama Runtime ──────┘
                      │
                   launchd
                      │
                 macOS Services
```

Notice the separation.

OpenClaw is the orchestrator.

Ollama is simply the inference runtime.

That distinction becomes incredibly important later when you start adding:

* embedding models
* vision models
* MCP servers
* Obsidian
* GitHub automation
* future cloud providers

because nothing else needs to know *how* inference happens.

---

# What I'd Like to Do Next

I think the next session should be one of the most valuable in the project.

Rather than simply downloading Qwen, I'd like us to **design and implement the entire Ollama service layer**.

Specifically, we'll:

1. Relocate the model storage to `~/server/data/models/ollama`.
2. Create a `launchd` service with proper logging and restart behavior.
3. Add a health-check script under `~/server/scripts/`.
4. Write the corresponding runbooks and milestone documentation in your Git repository.
5. Download the three production models.
6. Benchmark them on your M4 Pro (24 GB) and record the results.
7. Verify everything survives a reboot.

Once that's complete, we'll have a production-grade inference layer that OpenClaw can rely on, and from there we can move on to Qdrant, Obsidian, and the broader AI platform with confidence. I think that disciplined approach will pay off every time you expand or maintain the system.
