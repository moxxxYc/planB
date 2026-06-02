---
name: careful
description: "Safety mode. Warns before destructive commands (rm -rf, DROP TABLE, git push -f, force delete). Does NOT restrict file editing scope — use /guard for that."
---

## Codex/macOS Adaptation

This skill is migrated from `/Users/yang/Projects/gstack-game/skills/careful`. Preserve the original gstack-game method, rubrics, and game-domain judgment, but run it as a Codex project skill on macOS:

- Use repository-local files and Codex tools. Prefer `rg`, `find`, `sed`, `ls`, and direct file reads.
- Resolve this skill's bundled material relative to `.codex/skills/careful/`.
- Ask the user directly when the original workflow reaches an interactive decision point.
- Treat `docs/gstack-artifacts/` as the local artifact directory when the original workflow refers to shared gstack storage.
- Do not use legacy generated automation, external artifact stores, usage logging, or platform-specific paths.

## User Sovereignty

AI models recommend. You decide. When this skill finds issues, proposes changes, or
a cross-model second opinion challenges a premise — the finding is presented to you,
not auto-applied. Cross-model agreement is a strong signal, not a mandate. Your
direction is the default unless you explicitly change it.

## Completion Status Protocol

DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT.
Escalation after 3 failed attempts.


# /careful: Destructive Command Safety

Activates heightened awareness for destructive operations. When active, flag and confirm before executing any potentially destructive command.

## What triggers a warning

| Pattern | Risk | Action |
|---------|------|--------|
| `rm -rf` (except node_modules, .next, dist, build, __pycache__) | File deletion | Confirm before executing |
| `git push -f` / `git push --force` | History rewrite | Confirm + warn about remote impact |
| `git reset --hard` | Uncommitted work loss | Confirm + suggest stash first |
| `git clean -f` | Untracked file deletion | Confirm + list what will be deleted |
| `git branch -D` | Branch deletion | Confirm + check if merged |
| `DROP TABLE` / `DROP DATABASE` | Data destruction | Confirm + verify environment |
| `TRUNCATE` | Data deletion | Confirm |
| `docker system prune` | Container cleanup | Confirm |
| Kill/stop commands on game servers | Service disruption | Confirm + check player count |

## Safe exceptions (no warning needed)

```
rm -rf node_modules/
rm -rf .next/
rm -rf dist/
rm -rf build/
rm -rf __pycache__/
rm -rf .cache/
rm -rf tmp/
git push (without -f)
```

## Activation

This skill is activated by invoking `/careful`. It stays active for the remainder of the session.

When active, before any Bash command that matches a warning pattern:

> ⚠️ **CAREFUL MODE**: This command will [describe impact].
> Affected: [list files/data/branches]
> Reversible: [yes/no/partially]
>
> Proceed? (confirm to execute)

## Deactivation

Say "turn off careful mode" or start a new session.

## Review Log
