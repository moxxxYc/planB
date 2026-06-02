# Ball Machine Auto Battle Prototype

Playable web MVP for a ball-machine-driven auto-battle roguelite.

The current prototype validates whether a player can shape an unstable physical spawning machine into a readable war engine through launch routing, tuning outcomes, unit-slot progress, race mechanics, relics, tech, buildings, and small support tools.

## Run

```bash
npm install
npm run dev
```

Open the local Vite URL, usually `http://localhost:5173/`. If that port is busy, Vite will print the next available URL.

## Validate

```bash
npm run typecheck
npm test
npm run build
npm run probe
npm run audit:mvp
```

Optional visual smoke:

```bash
npm run smoke:build-visuals
```

`npm run probe` runs the build identity probes, the natural three-chamber blueprint reward probe, and the Arcane secondary Rune probe.

`npm run audit:mvp` checks the current MVP readiness evidence and fails if required completion evidence is missing. `npm run audit:v1.2` remains as a compatibility alias.

## Current Prototype

- Setup panel: choose Hive or Mech as main race, optionally enable Arcane secondary support.
- Default local state in source: Hive main race plus Arcane secondary.
- Ball machine: left Tuning Zone, middle Launch Zone, right Unit Spawn Zone. The Web MVP still uses legacy `Standby` / `decision` labels in some code and UI until the rewrite lands.
- Rewards: phase-end offers are fixed to one Launch blueprint, one Tuning blueprint, and one Unit blueprint. Current data may still store the Tuning chamber as legacy `decision`.
- Battle: constrained fake 2D / 3/4 auto-battle field with soft lanes, camera, and battle-line strip.
- Run shell: six phases, victory/failure summary, machine diagnosis tags, chain history, restart, and change setup.
- Controls: mouse-only play is supported. Debug controls are available for local validation.

## Canonical Docs

Only these docs are current:

- `README.md`: run and validation entry.
- `docs/gdd.md`: canonical design, current implementation summary, future direction, source index.
- `docs/PROGRESS.md`: recent changes and validation status.

Older research notes, goal files, implementation plans, and skill artifacts were consolidated into `docs/gdd.md` on 2026-06-01 and removed to avoid stale duplicate truth.

## Hard Boundaries

- No PVP, networking, accounts, backend, matchmaking, or Steam integration.
- No free RTS map.
- No complex RTS pathfinding.
- The ball machine remains the main system.
- Buildings and rewards support the machine, not replace it.
- The prototype must stay self-contained and runnable locally.
