# M03 Tagging Checklist

## Review

```bash
git status
git diff --stat
git diff
```

## Final Validation

```bash
./scripts/status.sh
./scripts/doctor.sh
./scripts/health.sh
./scripts/verify.sh
```

## Commit

```bash
git add docs scripts
git commit -m "feat(m03): complete OpenClaw platform integration"
```

## Tag

Use the convention already established by M01 and M02.

Recommended milestone tag:

```bash
git tag -a m03-openclaw -m "M03: OpenClaw platform complete"
```

Alternative versioned tag:

```bash
git tag -a v0.3.0-m03 -m "M03: OpenClaw platform complete"
```

## Push

```bash
git push origin HEAD
git push origin --tags
```

## Verify

```bash
git log -1 --oneline
git tag --list --sort=-creatordate | head
git ls-remote --tags origin
```
