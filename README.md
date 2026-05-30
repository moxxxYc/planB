# Ball Machine Auto Battle Prototype

## Run

```bash
npm install
npm run dev
```

Open the local Vite URL, usually `http://localhost:5173/`. If that port is busy, Vite will print the next available local URL.

## Build

```bash
npm run build
npm run typecheck
npm run probe
npm run audit:v1.2
npm run smoke:build-visuals
```

`npm run probe` runs the v1.2 build-preset validation report for the five target identities plus the natural three-chamber blueprint reward probe, and exits nonzero if a chain, combat-impact, recovery, or dead-effect guardrail fails.

`npm run audit:v1.2` prints a requirement-by-requirement v1.2 readiness report with `proved`, `partial`, and `missing` evidence states, and exits nonzero if completion evidence is missing.

`npm run smoke:build-visuals` captures a headless Chrome screenshot for each debug build identity under `docs/build-identity-*-smoke.png`.

## Controls

- Click one of the three phase-end blueprint cards after each phase: Launch Zone, Standby Zone, or Unit Spawn Zone.
- Use the bottom debug buttons to drop balls, send test balls to Standby or Unit Spawn, continue a paused phase, toggle race, or skip a phase.
- Click the battlefield speed button to cycle 1x, 2x, and 4x global simulation speed.
- Use the top-right phase-tool buttons during the once-per-phase mid-phase recovery window to spend gold on one tool such as spawn marks, hot-slot progress, queue burst, repair, or a tagged next shot.
- Use the research-tech buttons to spend research on doctrine techs during a run.
- Use the structure buttons to spend gold on up to three Unit Spawn Zone support buildings such as overflow spill, earlier high-tier access, or queue burst.
- Use the preset buttons to load reproducible build identities, and `探针` to run the build probe overlay through queue, deployment, and deterministic combat impact.
- The prototype can be played with mouse only. No unit micro is required.
- The bottom HUD shows current relics, researched tech nodes, and installed Unit Spawn structures so the three build surfaces stay visible during play.

## Design

This prototype tests a three-stage horizontal pinball pipeline above the battlefield:

1. Standby Zone turns routed balls into gold, magic, or upgrade outcomes.
2. Launch Zone sits in the middle and routes balls into standby, split, or direct spawn outcomes.
3. Unit Spawn Zone receives spawn balls, lets them fall through pegs, and lands them in one of five race unit slots.

Each unit slot stores its own progress before queueing a specific unit: 1, 3, 5, 7, or 9 progress. A single physical gate covers the high-tier right side early in each phase, shows the current open range, bounces balls back toward open lower-tier slots, and shrinks until the whole unit zone is open halfway through the phase.

The battlefield is a constrained fake 2D 3/4 auto-battle board. Units spawn near the player base, advance diagonally, acquire nearby targets, attack, die, and damage bases. There is no PVP, networking, accounts, backend, matchmaking, or Steam integration.

## Current Content

- Races: Hive and Mech.
- Hive units: Grub, Spitter, Carapace, Brood Guard, Behemoth.
- Mech units: Drone, Gunner, Walker, Siege Crawler, Titan.
- Enemy units: Raider, Shooter, Brute.
- Visible standby slots: GOLD, MAGIC, UP.
- Unit slots: five visible race-specific `UnitSlotState` slots with icon art, progress bars, requirements, and overflow progress.
- Phases: 6 continuous battlefield phases.
- Rewards: every phase-end offer is fixed to three blueprint cards: one Launch Zone blueprint, one Standby Zone blueprint, and one Unit Spawn Zone blueprint. Early natural offers prioritize installable or upgradable chamber buildings, then chamber relics or doctrine techs, with same-chamber legacy stat rewards as repeatable fallback.
- Build layers: chamber buildings modify Launch / Standby / Unit Spawn zones and can now be obtained through the normal phase-end blueprint flow; up to three Unit Spawn structures can also be bought directly with gold; launch and event relics modify ball tags or translate misses, blocked gates, magic, and upgrades into future value; doctrine techs can be unlocked through blueprint rewards or bought with research. The top machine row now also renders a build identity badge, compact chamber summaries, per-chamber icon signatures, and small SVG structure silhouettes for the current build.
- Research and fallback: MAGIC and UP hits create baseline research, every four baseline research pips returns into a stored spawn mark, research can be spent on doctrine techs, and any three consecutive non-spawn standby results create a stored spawn mark.
- Phase tools: once-per-phase mid-phase purchases support immediate回流 through spawn marks, hot slots, queue surge, repair, and tagged launch balls.
- Persistent systems: SPAWN adds to a reserve queue, standard and elite player units survive phase transitions, elites gain veterancy when they live through a phase, and phase completion records persistent chain history with build archetype, concrete queues, deployments, high-tier queue ratio, gate-block bounces, chamber contributions, resource return efficiency, longest non-SPAWN streak, first recovery timing, recovery sources, and visual build identity. Build probes also expose v1.2 scenario metrics such as low-tier deploy share, deploys per spawn hit, average unit level, tier-3 deploy timing, queue release rate, burst deploys, chain depth, and dead-effect count. The run state also exposes the v1.2 build-surface fields `launchRelics`, `decisionTechs`, `unitStructures`, and `ballTags`.
- Command-line validation: `npm run probe` prints the deterministic build-probe table for all five debug identities and a `natural_blueprint_reward_probe` row proving that non-debug phase rewards can create a chamber build, recover non-SPAWN value within 15 seconds, queue units, deploy them, and deal combat damage.
- Readiness audit: `npm run audit:v1.2` maps the v1.2 requirements to current evidence and explicitly reports remaining partial evidence before completion is claimed.
- Visual validation: `npm run smoke:build-visuals` launches a temporary local Vite server and captures all five build identities in headless Chrome.
- Assets: built-in generated image sheet saved under `public/assets/generated/reference/`, plus self-contained SVG fallback sprites used by the prototype.
