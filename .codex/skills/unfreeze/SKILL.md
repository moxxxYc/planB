---
name: unfreeze
description: "Deactivate /guard scope restriction. Returns to normal editing mode."
---

## Codex/macOS Adaptation

This skill is migrated from `/Users/yang/Projects/gstack-game/skills/unfreeze`. Preserve the original gstack-game method, rubrics, and game-domain judgment, but run it as a Codex project skill on macOS:

- Use repository-local files and Codex tools. Prefer `rg`, `find`, `sed`, `ls`, and direct file reads.
- Resolve this skill's bundled material relative to `.codex/skills/unfreeze/`.
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


# /unfreeze: Deactivate Guard Mode

Removes the file edit scope restriction set by `/guard`.

## What it does

1. Clears the active scope restriction
2. Confirms deactivation
3. `/careful` protections remain active if they were enabled separately

## Usage

Just invoke `/unfreeze`. No arguments needed.

> Guard mode deactivated. All files are now editable.
> Note: If /careful was active, destructive command warnings are still on.

## Review Log
