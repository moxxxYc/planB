---
name: guard
description: "Full safety mode. Combines /careful (destructive command warnings) with file scope restriction. Prevents editing files outside a specified directory."
---

## Codex/macOS Adaptation

This skill is migrated from `/Users/yang/Projects/gstack-game/skills/guard`. Preserve the original gstack-game method, rubrics, and game-domain judgment, but run it as a Codex project skill on macOS:

- Use repository-local files and Codex tools. Prefer `rg`, `find`, `sed`, `ls`, and direct file reads.
- Resolve this skill's bundled material relative to `.codex/skills/guard/`.
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


# /guard: Full Safety Mode

Activates BOTH destructive command safety (/careful) AND file edit scope restriction.

## Activation

direct user question: What directory should I restrict edits to?
- A) Current feature directory (auto-detect from recent git changes)
- B) Specific path: [user provides path]
- C) Only files in current PR/branch diff

## Scope Restriction

When active, before any Edit/Write tool call:

1. Check if target file is within the allowed scope
2. If outside scope:

> 🛡️ **GUARD MODE**: This file is outside the allowed scope.
> Scope: [allowed directory]
> Target: [file being edited]
>
> This edit is BLOCKED. To proceed, either:
> A) Expand scope to include this file
> B) Temporarily bypass for this one edit
> C) Deactivate guard mode

## Careful Mode (included)

All /careful protections are also active. See `/careful` for destructive command warnings.

## Use Cases

- **During a focused bug fix:** Guard to only the affected module
- **During asset work:** Guard to only asset directories (don't accidentally change code)
- **During balance tuning:** Guard to only data/config files (don't change game logic)

## Deactivation

Say "turn off guard mode" or start a new session.

## Review Log
