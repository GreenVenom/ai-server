---
title: Obsidian Operations Runbook
document: Runbook
status: Active
created: 2026-07-18
updated: 2026-07-18
platform_version: v0.5.0
owner: GreenVenom
---

# Obsidian Operations Runbook

## Purpose

Operate, validate, and troubleshoot the scheduled Obsidian synchronization, indexing, and retrieval service.

## Prerequisites

- The configured vault marker, read-only Git checkout, mirror, and Python environment are present.
- Ollama, Qdrant, and the OpenClaw plugin are available when validating retrieval.

## Routine status

```bash
~/server/scripts/check-obsidian.sh
~/server/scripts/status.sh
~/server/scripts/health.sh
openclaw plugins doctor
```

Expected production values:

```text
vault_id                  personal-knowledge
collection                obsidian_chunks_v1
manifest documents        7 at M05 closeout
production chunks         176 at M05 closeout
scheduled job             success
OpenClaw tool              obsidian_search
```

Document and chunk counts may increase as the vault grows. A count change is not inherently a failure; reconciliation must remain exact.

## Manual synchronization

```bash
~/server/scripts/obsidian-sync-index-runner.sh
```

This performs Git synchronization, Markdown mirroring, incremental indexing, durable state recording, and logging.

## Logs

```text
~/server/logs/obsidian/personal-knowledge-<timestamp>.log
~/server/logs/obsidian/personal-knowledge-latest.log
~/server/logs/obsidian/launchagent.stdout.log
~/server/logs/obsidian/launchagent.stderr.log
```

## Durable state

```text
~/server/data/obsidian/state/personal-knowledge-job-state.json
~/server/data/obsidian/state/personal-knowledge-source.commit
```

## LaunchAgent management

```bash
launchctl print "gui/$(id -u)/ai.openclaw.obsidian-sync-index"
launchctl kickstart -k "gui/$(id -u)/ai.openclaw.obsidian-sync-index"
launchctl bootout "gui/$(id -u)/ai.openclaw.obsidian-sync-index"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/ai.openclaw.obsidian-sync-index.plist"
```

`state = spawn scheduled` is normal between interval runs.

## Retrieval test

```bash
~/server/scripts/obsidian-search.sh \
  "What tasks are currently on my to-do list?" \
  --vault-id personal-knowledge \
  --limit 5
```

## OpenClaw test

Start `openclaw tui` and ask:

```text
Use the Obsidian search tool to summarize my current to-do list and include the source note path.
```

## Repository synchronization failure

Check:

```bash
git -C ~/server/data/obsidian/repos/personal-knowledge-source status --short --branch
git -C ~/server/data/obsidian/repos/personal-knowledge-source remote -v
ssh -T github-obsidian-vault
```

The checkout must remain fast-forward-only and have a disabled push URL.

## Lock recovery

A lock should disappear automatically after normal or trapped termination. Remove a stale lock only after confirming no job is running:

```bash
pgrep -af 'obsidian-sync-index|obsidian_ingest.incremental'
rmdir ~/server/data/obsidian/state/personal-knowledge-job.lock
```

## Excessive deletion failure

Do not bypass the deletion threshold until the mirror and source repository have been reviewed. Confirm:

- the expected Git commit;
- the mirror note count;
- exclusion rules;
- whether a large source reorganization occurred.

Then run the incremental command using the implementation's explicit deletion-approval option.

## Log retention

```bash
~/server/scripts/cleanup-obsidian-logs.sh
```

Timestamped job logs older than 30 days are deleted. Current LaunchAgent logs and the latest-log symlink are preserved.

## Related documentation

- [Obsidian backup and restore runbook](Obsidian-Backup-and-Restore.md)
- [Obsidian integration architecture](../../architecture/Obsidian-Integration.md)
- [M05 milestone record](../milestones/M05-Obsidian-Integration.md)
