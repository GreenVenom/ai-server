---
title: ADR-0010 - Start Docker Desktop at OpenClaw User Login
document: ADR
status: Accepted
created: 2026-07-16
updated: 2026-07-16
platform_version: v0.3.0
owner: GreenVenom
decision_id: ADR-0010
supersedes:
superseded_by:
milestone: M03 - OpenClaw Platform
---

# ADR-0010 - Start Docker Desktop at OpenClaw User Login

## Context

The Personal AI Platform uses Docker Desktop as the container runtime for OpenClaw sandbox execution on a Mac mini running macOS.

OpenClaw is configured to sandbox all agent sessions using Docker. The OpenClaw Gateway runs as a LaunchAgent under the dedicated standard user account:

```text
openclaw
```

The platform also uses:

- FileVault
- hardened SSH
- Tailscale
- a separate administrative account
- automatic login disabled
- a loopback-only OpenClaw Gateway
- Docker-based agent sandboxes

Docker Desktop on macOS is associated with a logged-in user session. It is not operated as a conventional system-wide Linux daemon that starts independently before user login.

During M03 validation, Docker Desktop worked correctly when started under the `openclaw` account. Its Docker socket was exposed at:

```text
/Users/openclaw/.docker/run/docker.sock
```

and the compatibility socket resolved as:

```text
/var/run/docker.sock
    -> /Users/openclaw/.docker/run/docker.sock
```

OpenClaw was configured to use the user-owned Docker socket:

```text
OPENCLAW_DOCKER_SOCKET=/Users/openclaw/.docker/run/docker.sock
```

The remaining operational question was whether Docker should be forced to start before login, started with a custom LaunchDaemon, or started automatically when the `openclaw` user logs in.

## Decision

Docker Desktop will be configured to start automatically when the `openclaw` user logs into macOS.

The platform will use Docker Desktop's supported login-start behavior rather than attempting to run Docker Desktop through a root LaunchDaemon or other pre-login mechanism.

The resulting startup sequence is:

```text
macOS boots
    ↓
FileVault is unlocked
    ↓
openclaw user logs in
    ↓
Docker Desktop starts automatically
    ↓
Docker API and user-owned socket become available
    ↓
OpenClaw can create Docker sandboxes
```

Automatic login will remain disabled.

FileVault will remain enabled.

The OpenClaw Gateway will continue to run as a LaunchAgent under the `openclaw` account.

Operational scripts will verify Docker and OpenClaw independently because the Gateway may become available before Docker Desktop has completed initialization.

## Rationale

This decision was selected because it:

- uses Docker Desktop's supported macOS lifecycle
- preserves the dedicated `openclaw` user boundary
- avoids running Docker Desktop as root
- avoids changing ownership or permissions on the Docker socket
- preserves FileVault and disables automatic login
- reliably restores Docker after user login
- supports OpenClaw sandbox creation without manual application startup
- matches the platform's existing LaunchAgent-based service model

The platform does not require unattended OpenClaw sandbox execution before any user has logged in.

## Alternatives Considered

### 1. Start Docker Desktop manually after every reboot

Rejected because it introduces unnecessary operational work and makes OpenClaw sandbox availability dependent on a manual application launch.

### 2. Enable automatic macOS login

Rejected because it would weaken the platform's physical and account security posture and would conflict with the decision to retain FileVault and explicit user authentication.

### 3. Create a root LaunchDaemon to start Docker Desktop before login

Rejected because Docker Desktop is designed around a macOS user session.

A root-managed process could create ownership, socket, GUI-session, and lifecycle inconsistencies. It would also increase privilege and maintenance complexity without a demonstrated platform requirement.

### 4. Change Docker socket ownership or make it broadly writable

Rejected because access to the Docker API is effectively privileged access to the container runtime.

Manually changing socket ownership or using permissive modes such as `0666` would weaken isolation and could be overwritten when Docker Desktop restarts.

### 5. Replace Docker Desktop with a headless container runtime

Deferred.

Alternatives such as a different macOS virtual-machine-backed container runtime could potentially support a different startup model. Replacing Docker Desktop would introduce a separate architectural decision, migration work, compatibility testing, and operational changes.

The current Docker Desktop deployment satisfies M03 requirements.

## Consequences

### Positive

- Docker starts without manual intervention after `openclaw` login.
- OpenClaw sandbox creation remains bound to the dedicated service account.
- FileVault and explicit login remain enabled.
- The supported Docker Desktop lifecycle is preserved.
- The Docker socket remains owned by the intended user.
- Existing OpenClaw sandbox and workspace configuration remains unchanged.

### Negative

- Docker is not available before the `openclaw` user logs in.
- A reboot requires an authenticated user login before OpenClaw sandbox execution becomes available.
- Docker startup may lag behind the OpenClaw Gateway during login.
- Health checks may temporarily report Docker or sandbox failures while Docker Desktop initializes.

### Operational

After reboot:

1. Unlock FileVault if required.
2. Log into the `openclaw` account.
3. Allow Docker Desktop to initialize.
4. Run:

```bash
~/server/scripts/status.sh
~/server/scripts/doctor.sh
~/server/scripts/health.sh
~/server/scripts/verify.sh
```

The expected final state is:

```text
status.sh  PASS
doctor.sh  PASS
health.sh  PASS
verify.sh  PASS
```

## Validation

The decision was validated by rebooting the Mac mini and logging into the `openclaw` account.

After login:

- Docker Desktop started automatically.
- `docker info` succeeded.
- the Docker socket was available
- the OpenClaw Gateway was running
- the OpenClaw sandbox runtime was available
- the productive workspace remained mounted read-write
- agent file creation succeeded
- `status.sh`, `doctor.sh`, `health.sh`, and `verify.sh` all passed

## Revisit Conditions

Revisit this decision if any of the following become requirements:

- OpenClaw must execute sandboxed tasks before user login.
- The Mac mini must recover fully from reboot without any interactive login.
- Docker Desktop no longer supports the required OpenClaw sandbox workflow.
- The platform migrates to another container runtime.
- The platform moves from macOS to a server operating system with a native boot-time container daemon.

## Related documentation

- [OpenClaw architecture](../architecture/OpenClaw-Architecture.md)
- [OpenClaw security baseline](../architecture/OpenClaw-Security-Baseline.md)
- [M03 milestone record](../milestones/M03-OpenClaw-Platform.md)
- [OpenClaw current state](../operations/OpenClaw-Current-State.md)
- [OpenClaw installation and hardening runbook](../runbooks/OpenClaw-Installation-and-Hardening.md)
