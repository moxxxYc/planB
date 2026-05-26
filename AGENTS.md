
## Project Intent

This repository is a playable web prototype for a ball-machine-driven auto-battle roguelite.

The core fantasy is:

> The player starts with a random physical spawning machine, then gradually shapes it into a stable war engine through rewards, slot tuning, race mechanics, and small support buildings.

This is a prototype to validate gameplay, not a final production codebase.

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