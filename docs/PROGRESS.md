# Progress Log

## Current Status

- Build status: `npm run build` passes
- Dev server status: verified on `http://localhost:5175/`
- Last checkpoint completed: long battlefield camera, soft three-lane spawning, and battle-line minimap pass

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
- Replaced the old per-unit progress map with `UnitSlotState` arrays per race so each slot owns `unitId`, `requirement`, `progress`, and `index`.
- Added `UnitGateState` calculation for the single high-tier blocker, including open boundary ratio, open slot count, and current highest open unit index.
- Updated the Unit Spawn Zone to read slot progress from `UnitSlotState`, show the current open range, and keep overflow progress when specific units queue.
- Added a Matter static collision body for the continuous high-tier blocker while keeping the existing safety redirect so balls cannot bounce forever.
- Added top-row pipeline arrows and transfer trails for Launch -> Decision and Decision -> Unit handoffs.
- Added/updated Vitest coverage for gate opening by elapsed time, blocked high-tier slots not gaining progress, open slot progress, spawn threshold behavior, overflow preservation, and data-driven slot state.
- Adjusted the unit gate semantics so a partially exposed slot counts as a valid landing if the ball actually reaches its slot; the blocker raises entry difficulty but does not invalidate successful landings.
- Rebuilt the battlefield into a clearer strategy-board composition: wide diagonal main lane, low-noise dark terrain, reduced rocks/trees, unified endpoint bases, visible spawn gates, and a dynamic frontline marker.
- Enlarged and outlined battle units, added side-colored rings, hit flash, attack pulse, spawn portal, hit spark, death burst, base hit flash, and blue/red ranged projectile rendering.
- Added deterministic combat feedback state (`projectiles`, `transientEffects`, unit/base hit timestamps) and Vitest coverage for frontline calculation plus attack/death feedback events.
- Updated the minimap to match the main lane direction and render live frontline/unit density overlays.
- Saved the battlefield rebuild smoke screenshot to `docs/rebuild-ui-smoke.png`.
- Added a top-edge launcher turret in the Launch Zone with deterministic 180-degree sweep aiming, replacing random launch angles.
- Increased peg density in all three pinball zones, randomized cross-zone drops within the next zone's top fifth, and compressed the Unit Spawn Zone high-tier blocker to one-tenth of its previous height.
- Moved the Unit Spawn Zone high-tier blocker down so its lower edge sits flush against the unit card row's upper edge.
- Rebalanced the screen proportions so the top three-stage pinball row stays compact while the battlefield occupies the main visual weight.
- Adjusted the top row widths to keep 发球区 small, 抉择区 medium, and 出兵区 largest.
- Rebuilt the battlefield layout from a narrow diagonal route into a broad central 3/4 combat plane with the player base at lower-left, enemy base at upper-right, and a wider frontline marker.
- Updated battle unit lane offsets and battlefield projection so units spread across the central area instead of stacking on a single thin line.
- Updated base bars, spawn trails, magic effects, and the minimap to match the wider battlefield structure.
- Saved the layout smoke screenshot to `docs/layout-space-structure-smoke.png`.
- Removed SPECIAL from the visible Decision Zone slot row and reordered the decision slots to 金币 / 法术 / 出兵 / 升级 so 出兵 sits in the middle of the row.
- Added a long battlefield camera pass: the battle world is much deeper than the screen viewport, units spawn into deterministic soft top/middle/bottom lanes, aggro/attack targeting accounts for lane distance, and the minimap is now a horizontal battle-line strip with blue/red unit heat, yellow conflict hotspots, and a draggable white viewport frame.
- Saved the long battlefield browser smoke screenshot to `docs/long-battlefield-smoke.jpg`.
- Added a minimap "frontline" button: dragging the battle-line strip disables auto-follow, and pressing the button snaps back to the current frontline hotspot and resumes auto-follow.

## Known Issues

- The high-tier blocker now has a Matter collision body, but still keeps a deliberate safety redirect while balls are in the blocker lane so the prototype cannot trap a ball indefinitely.

## Deviations from Spec

- Runtime uses SVG fallback sprites for individual game objects while also preserving a generated PNG asset sheet in the project.
- Added light anti-stuck nudging for balls so the physical machine remains readable without letting balls rest forever on pegs.

## Next Steps

- Playtest balance for phase pacing, reward card variety, and elite readability.
