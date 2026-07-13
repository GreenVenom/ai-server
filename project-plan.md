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
