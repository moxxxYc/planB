# Progress Log

## Current Status

- Build status: `npm run build` passes
- Dev server status: verified on `http://localhost:5176/`
- Last checkpoint completed: three-stage pinball UI and unit spawn progress rework

## Implemented

- Read `CODEX_GOAL_SPEC.md` and `AGENTS.md`.
- Added a manual Vite + TypeScript + Phaser scaffold because `create-vite` cancelled on the non-empty folder.
- Added the required npm scripts: `dev`, `build`, `typecheck`, and `test`.
- `npm install` succeeded.
- Added data-driven core rules for races, units, slots, phases, rewards, slot effects, and deterministic battle simulation.
- Added Vitest coverage for SPAWN, UP, GOLD, MAGIC, battle combat, phase persistence, and rewards.
- `npm test` and `npm run typecheck` pass after the core systems checkpoint.
- Copied the built-in generated image sheet to `public/assets/generated/reference/generated-asset-sheet.png`.
- Added SVG fallback assets for Hive, Mech, enemy units, bases, slot icons, balls, pegs, and bumpers.
- Implemented a Phaser scene with Matter ball machine physics, four slot sensors, visible slot feedback, 2D 3/4 battlefield projection, auto-combat, base damage, phase rewards, and phase summary stats.
- Audited the previous hard-reset wave lifecycle in `docs/CONTINUOUS_PHASE_AUDIT_PLAN.md`.
- Replaced hard-reset wave progression with continuous phases: player standard units, elite units, spawn queue, gold, upgrades, buildings, and relic state persist through phase completion.
- Added persistent SPAWN reserve queue deployment with a standard-unit soft cap.
- Added elite unit lifetime/veterancy growth on phase completion and HUD summary for reserve queue and elite level.
- Added six phase definitions with phase pressure/objectives and reward/build pause continuation.
- Removed the CHARGE slot and charge-based elite burst mechanism pending a future replacement design.
- Browser smoke checked the phase completion reward pause and saved `docs/continuous-phase-smoke.png`.
- Added mouse-only reward selection and debug controls.
- Added `README.md` and `docs/PLAYTEST_CHECKLIST.md`.
- Final validation passed: `npm install`, `npm test`, `npm run typecheck`, `npm run build`, and browser smoke check.
- Reworked the prototype into a top-row three-stage pinball pipeline: 发球区, 抉择区, and 出兵区.
- Added the SPECIAL decision slot and removed direct random unit queueing from SPAWN. SPAWN now feeds the Unit Spawn Zone flow.
- Added five race unit slots for Hive and Mech with progress requirements 1/3/5/7/9, progress overflow, and specific-unit queueing.
- Added a single continuous Unit Spawn Zone gate that starts by covering high-tier slots, shrinks over the first half of the phase, and bounces early high-tier balls back toward open slots.
- Added SVG fallback art for Hive Brood Guard, Hive Behemoth, Mech Siege Crawler, Mech Titan, and the SPECIAL icon.
- Switched Phaser rendering to Canvas mode for more reliable local smoke screenshots.
- Saved the three-stage UI smoke screenshot to `docs/three-stage-pinball-ui-smoke.png`.
- Reworked the battlefield visual pass against the uploaded reference image: added a dark 3/4 siege-board composition, diagonal stone road, left blue fortress, right red fortress, cliff/forest/rock layers, minimap, ambient formations, and larger base health plates while keeping deterministic non-RTS combat logic.
- Adjusted the battlefield after visual review: removed the heavy slanted board outline, kept perspective only in the road/tiles, and moved the player fortress away from the lower-left minimap corner into the left-side battle entrance.
- Replaced the slanted battlefield slab with broken stone/track details embedded in the terrain, and changed both bases to the same low endpoint-district template with matching health-bar placement.
- Fixed the battlefield render depth so timed enemy waves are visible when they leave the enemy base even if the player has not spawned any units.
- Moved battle unit spawn exits outward from the base centers so new units appear at the base front instead of inside the base art.

## Known Issues

- The first-pass gate bounce is intentionally simple: it uses a visible continuous gate plus velocity redirect instead of rebuilding exact Matter collision geometry every frame.

## Deviations from Spec

- Runtime uses SVG fallback sprites for individual game objects while also preserving a generated PNG asset sheet in the project.
- Added light anti-stuck nudging for balls so the physical machine remains readable without letting balls rest forever on pegs.

## Next Steps

- Playtest balance for phase pacing, reward card variety, and elite readability.
