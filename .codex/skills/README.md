# gstack-game Skills for Codex

These are project-local Codex skills that preserve the gstack-game game-development methods and rubrics, with runtime adaptation for Codex Desktop, Codex CLI, and remote agent environments. They are design/review skills, not a replacement for GodotPrompter, GoPeak MCP, Superpowers, or the current project docs.

## Entry and Safety

- `triage`
- `careful`
- `guard`
- `unfreeze`

## Creative and Direction

- `spark-lens`
- `game-ideation`
- `game-direction`
- `pitch-review`

## GDD and Design Review

- `game-import`
- `game-review`
- `plan-design-review`
- `game-codex`

## Player Experience and Validation

- `player-experience`
- `build-playability-review`
- `feel-pass`
- `playtest`
- `game-ux-review`
- `game-visual-qa`
- `asset-review`

## Production Bridge

- `prototype-slice-plan`
- `implementation-handoff`
- `gameplay-implementation-review`
- `balance-review`

## Engineering, QA, Ship, Docs, Retro

- `game-eng-review`
- `game-debug`
- `game-qa`
- `game-ship`
- `game-docs`
- `game-retro`

## Runtime Notes

- Use repository-local files and Codex tools.
- Prefer portable shell commands such as `rg`, `find`, `sed`, and `ls`; avoid personal absolute paths and macOS-only assumptions in reusable guidance.
- Use each skill's local `references/` directory when the workflow names a rubric.
- Write generated artifacts under `docs/gstack-artifacts/`, unless a skill names a canonical project path such as `docs/gdd.md`.
- Keep Superpowers for engineering execution discipline, GodotPrompter for Godot 4.x implementation guidance, and GoPeak MCP for runtime/editor verification when available.
- Use gstack-game skills for game-domain intent, design review, playability rubrics, QA judgment, release judgment, and handoff structure.
