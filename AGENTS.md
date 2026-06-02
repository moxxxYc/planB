
## Project Intent

This repository is a playable web prototype for a ball-machine-driven auto-battle roguelite.

The core fantasy is:

> The player starts with a random physical spawning machine, then gradually shapes it into a stable war engine through rewards, slot tuning, race mechanics, and small support buildings.

This is a prototype to validate gameplay, not a final production codebase.

## Agent Conduct

要求保持客观公正，不要献媚，不要敷衍。

- Be direct about quality. If a design, implementation, or plan is weak, say why and name the evidence.
- Do not invent missing gameplay, content, or production status. Ground documentation and reviews in files, code, playable behavior, or explicit user input.
- Mark unknowns clearly instead of filling gaps with plausible-sounding assumptions.
- Prefer the best long-term project shape over a superficial quick fix when the task changes workflow, documentation, or game direction.

## Non-negotiable Design Rules

1. Do not build a rectangle-only placeholder. Use generated image assets where available; if not, generate clean SVG fallback assets.
2. Do not implement PVP, networking, accounts, backend services, matchmaking, or Steam integration.
3. Do not make the battle field a free RTS map. Use a constrained fake 2D 3/4 auto-battle field.
4. Do not implement complex RTS pathfinding. Battle logic should be deterministic, simple, and readable.
5. The ball machine must remain the main system. Buildings and rewards must support it, not replace it.
6. The game should be playable with mouse only. Keyboard shortcuts are optional.
7. Keep systems data-driven where practical.
8. Prefer readable implementation over clever architecture.
9. If blocked by asset generation, make SVG fallback assets and continue.
10. Keep the prototype self-contained and runnable locally.

## Tech Stack

- Vite
- TypeScript
- Phaser
- Phaser Matter physics or Matter.js through Phaser for the ball machine
- Custom deterministic logic for the auto-battle field
- Generated PNG assets or SVG fallback assets

## Commands

Use these commands when available:

```bash
npm install
npm run dev
npm run build
npm run typecheck
```

If a command is missing, add it.

## Validation Loop

After each checkpoint:

1. Run the fastest relevant command.
2. Fix errors before moving on.
3. Update `docs/PROGRESS.md`.
4. Keep the project runnable.

## Code Style

- Use TypeScript.
- Keep game data in `src/data/`.
- Keep systems in `src/systems/`.
- Keep rendering helpers in `src/rendering/` or scene files.
- Avoid large monolithic files when practical.
- Do not over-engineer. This is a playable prototype.

## Visual Style

- 2D stylized strategy prototype.
- Strong silhouettes.
- Simple readable shapes.
- Light cartoon / tactical board-game feel.
- No copyrighted or third-party IP.
- No direct copying of Z-Arcade, Warcraft, Castle Fight, or any existing asset set.

## Definition of Done

The prototype is done when:

- It builds.
- It launches.
- It has a visible ball machine.
- It has visible non-placeholder unit art.
- It has a fake 2D 3/4 auto-battle field.
- It has two playable races.
- It has wave rewards.
- It has basic combat stats.
- It has a README and progress log.

## gstack-game Codex Skills

Project-local game-development skills live under `.codex/skills/`. They are
migrated from `/Users/yang/Projects/gstack-game` and adapted only for Codex on
macOS. Do not turn them into PlanB-specific wrapper skills. Preserve the
original gstack-game methods, rubrics, scoring language, and game-domain
judgment.

Use these skill groups:

- Entry and safety: `triage`, `careful`, `guard`, `unfreeze`.
- Creative and direction: `spark-lens`, `game-ideation`, `game-direction`,
  `pitch-review`.
- GDD and design review: `game-import`, `game-review`, `plan-design-review`,
  `game-codex`.
- Player experience and validation: `player-experience`,
  `build-playability-review`, `feel-pass`, `playtest`, `game-ux-review`,
  `game-visual-qa`, `asset-review`.
- Production bridge: `prototype-slice-plan`, `implementation-handoff`,
  `gameplay-implementation-review`, `balance-review`.
- Engineering, QA, ship, docs, retro: `game-eng-review`, `game-debug`,
  `game-qa`, `game-ship`, `game-docs`, `game-retro`.

Recommended flow for this MVP:

1. If docs are missing or stale, run `game-import` from the existing README,
   docs, source, and playable behavior.
2. Review direction and risks with `game-review`, then choose the next
   validation slice with `prototype-slice-plan`.
3. Convert the slice into buildable intent with `implementation-handoff`.
4. Use the normal Codex/Superpowers engineering workflow to implement code.
5. Re-check the built result with `feel-pass`,
   `gameplay-implementation-review`, `build-playability-review`, and `game-qa`.

## Superpowers Boundary

Global Superpowers may be installed at the same time as these project skills.
They should not conflict if their responsibilities stay separate.

- Use gstack-game skills for game intent, GDDs, player experience, playability,
  balance, asset/visual QA, game-specific debugging, ship readiness, and
  retrospectives.
- Use Superpowers for engineering execution discipline: implementation
  planning, TDD, systematic debugging, code review, verification, branch, commit,
  and PR workflow.
- If both apply, establish game-domain intent with the relevant gstack-game
  skill first, implement with Superpowers/Codex engineering flow second, then
  validate the result again with gstack-game review or QA skills.
- Do not let Superpowers override game-design intent without a gstack-game
  review. Do not let gstack-game skills replace required engineering
  verification.

Runtime rules:

- Use repository-local files and macOS shell commands such as `rg`, `find`,
  `sed`, and `ls`.
- Do not use legacy generated automation, external artifact stores, or
  platform-specific paths from the source gstack-game project.
- When a skill asks for a persistent artifact, write it inside this repository,
  usually under `docs/gstack-artifacts/`, unless the skill names a canonical
  path such as `docs/gdd.md`.
- Skill reference files live next to each skill under
  `.codex/skills/<skill>/references/`; read only the references needed for the
  current workflow.
