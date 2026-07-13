---
title: M01 - Foundation
status: Complete
version: 1.0
last_updated: 2026-07-12
---

## Objective

Build a secure, reproducible foundation for the personal AI server.

---

## Success Criteria

- Secure operating system
- Remote administration
- Infrastructure repository
- AI runtime prerequisites installed

---

## Deliverables

### Hardware

- Mac mini M4 Pro
- 24 GB RAM

### Security

- FileVault
- Firewall
- Automatic Updates
- Tailscale
- SSH Hardening
- Ed25519 Authentication

### Accounts

Admin

- Administrative tasks

AI

- Standard user
- AI workloads

### Development

- Homebrew
- Docker Desktop
- Git
- Xcode CLI
- Rosetta

### Repository

- Git
- GitHub
- Documentation
- Runbooks
- ADRs

---

## Verification Checklist

- [x] FileVault enabled
- [x] Firewall enabled
- [x] SSH key authentication
- [x] Password login disabled
- [x] Tailscale configured
- [x] Homebrew installed
- [x] Docker installed
- [x] Git configured
- [x] Repository synchronized

---

## Lessons Learned

- Separate service accounts improve security.
- Infrastructure should be documented before expansion.
- Homebrew remains owned by the administrator.
- SSH keys should be configured before disabling passwords.

---

## Future Improvements

- Monitoring
- Automated backups
- Infrastructure verification script
- AI runtime verification script
- AI runtime upgrade script
- AI runtime recovery script
- AI runtime benchmarking script
- AI runtime deployment script
- AI runtime installation script
- AI runtime configuration script
