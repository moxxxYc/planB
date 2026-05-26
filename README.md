# Ball Machine Auto Battle Prototype

## Run

```bash
npm install
npm run dev
```

Open the local Vite URL, usually `http://localhost:5173/`.

## Build

```bash
npm run build
npm run typecheck
```

## Controls

- Click reward cards after each phase.
- Click `Toggle Race` or the `Race` debug button to switch Hive / Mech.
- Use debug buttons to drop balls, trigger SPAWN, continue a paused phase, buy an extra ball, or skip a phase.
- The prototype can be played with mouse only. No unit micro is required.

## Design

This prototype tests a three-stage horizontal pinball pipeline above the battlefield:

1. Launch Zone preprocesses balls into split, fire, or miss outcomes.
2. Decision Zone turns balls into gold, magic, spawn, or upgrade outcomes, with spawn kept near the middle of the row.
3. Unit Spawn Zone receives only spawn balls, lets them fall through pegs, and lands them in one of five race unit slots.

Each unit slot stores its own progress before queueing a specific unit: 1, 3, 5, 7, or 9 progress. A single physical gate covers the high-tier right side early in each phase, shows the current open range, bounces balls back toward open lower-tier slots, and shrinks until the whole unit zone is open halfway through the phase.

The battlefield is a constrained fake 2D 3/4 auto-battle board. Units spawn near the player base, advance diagonally, acquire nearby targets, attack, die, and damage bases. There is no PVP, networking, accounts, backend, matchmaking, or Steam integration.

## Current Content

- Races: Hive and Mech.
- Hive units: Grub, Spitter, Carapace, Brood Guard, Behemoth.
- Mech units: Drone, Gunner, Walker, Siege Crawler, Titan.
- Enemy units: Raider, Shooter, Brute.
- Decision slots: SPAWN, GOLD, MAGIC, UP, SPECIAL.
- Unit slots: five visible race-specific `UnitSlotState` slots with icon art, progress bars, requirements, and overflow progress.
- Phases: 6 continuous battlefield phases.
- Rewards: machine slot changes, reserve queue speed, ball count, gold scaling, spell copy, Hive swarm, and Mech upgrade support.
- Persistent systems: SPAWN adds to a reserve queue, standard and elite player units survive phase transitions, and elites gain veterancy when they live through a phase.
- Assets: built-in generated image sheet saved under `public/assets/generated/reference/`, plus self-contained SVG fallback sprites used by the prototype.
