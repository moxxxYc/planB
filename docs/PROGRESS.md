# Progress

## Current Documentation Set

As of 2026-06-02, this repository is docs-only.

Active files:

- `README.md`
- `AGENTS.md`
- `docs/gdd.md`
- `docs/PROGRESS.md`

The old Web MVP implementation, generated assets, dependencies, scripts, validation probes, and project-local skills were removed. Future implementation should start from the current GDD, not from deleted Web MVP assumptions.

## 2026-06-02

- Removed the obsolete Web MVP codebase:
  - `src/`
  - `scripts/`
  - `public/`
  - `dist/`
  - `node_modules/`
  - package and TypeScript/Vite configuration files
  - old project-local `.codex` and `.superpowers` tooling folders
- Kept only formal documentation files.
- Rewrote `docs/gdd.md` as a formal accepted-design document, without current Web MVP source truth, source index, build commands, or legacy validation claims.
- Rewrote `README.md` as a docs-only repository index.
- Rewrote `AGENTS.md` for the docs-only state.
- Removed obsolete validation commands and modules before the full code deletion:
  - `probe`
  - `audit:mvp`
  - `audit:v1.2`
  - `smoke:build-visuals`
- Recorded accepted design decisions:
  - Formal machine warehouses are `Launch / Tuning / Unit`.
  - Ball Pool belongs to Launch and uses a 5-slot FIFO baseline.
  - Forge generates slightly faster than Launcher fires.
  - Split and Recycle return value-1 clean balls to Pool.
  - Junk pollution is enemy-specific, not a default Boss mechanic.
  - Tuning baseline slots are `Prime / Echo / Surge`.
  - `Guide` is rejected as a baseline slot.
  - The old combat Gold slot is abandoned legacy.
  - Gold remains the visible resource name.
  - Primary Gold source is post-battle settlement.
  - Machine shop is split into `Launch / Tuning / Unit` columns.
  - Shop does not sell generic raw stats.
  - Repair is a once-per-shop survival slot.
- Updated the core fantasy from "diagnose where the machine is failing" to Machine-to-frontline:
  - the player identifies which machine axis a run can amplify,
  - commits through rewards, shop items, events, and low-frequency Overdrive,
  - and validates the axis through visible frontline pressure.
- Updated run structure direction toward node-room progression:
  - normal battles expose amplification signals,
  - rewards and shops support polarizing, pivoting, or patching,
  - events offer high-risk machine changes,
  - elites and Bosses test whether the current machine axis converts into frontline pressure.
- Added three early build shapes for Section 1 review:
  - `Launch Flood`: front-return throughput into continuous frontline pressure,
  - `Tuning Echo`: Echo Hot Slot into few high-value repeated waves,
  - `Unit Queue Burst`: Squad Merge into visible batch surge.
- Added Hive and Mech race rewrites for those build shapes:
  - Hive rewrites them as `Brood Flow`, `Infection Echo`, and `Nest Surge`,
  - Mech rewrites them as `Ammo Chain`, `Calibration Echo`, and `Formation Release`.
- Added early node chains for those build shapes:
  - `Launch Flood`: `Front Return` reward, `Overflow Buffer` shop item, `Uncapped Intake` event,
  - `Tuning Echo`: `Echo Hot Slot` reward, `Echo Lock` shop item, `Overtone` event,
  - `Unit Queue Burst`: `Squad Merge` reward, `Queue Brace` shop item, `Delayed Muster` event.
- Added Section 2 FTUE and D1 retention direction:
  - first battle demonstrates `Front Return`, `Echo Hot Slot`, and `Squad Merge` before the player commits,
  - first real reward choice asks the player to pick one axis,
  - D1 hook mainly comes from untried machine axes and Hive/Mech race rewrites,
  - unlocks and challenge tiers can support retention but should not replace machine-axis learning.
- Added Section 2 difficulty and churn direction:
  - early difficulty follows `Expose / Stress / Validate`,
  - early churn points are unreadable first battle, first counter feeling punitive, and mid-run shop flattening.
- Added D7/D30 retention direction:
  - use an `Axis Mastery Ladder` focused on counter handling, race rewrites, and higher challenge tiers,
  - use run achievements as concrete goals,
  - keep unlocks tied to machine-axis mastery instead of external collection.
- Added Section 3 economic overload direction:
  - default Gold curve should prevent accidental buyout across all machine columns,
  - named high-Gold builds may buy through parts of a node sequence if they have identity, cost, counterplay, and boundaries,
  - Gold build is not an early build shape until the core three machine axes are proven.
- Added Section 4 motivation and emotional arc direction:
  - the main motivation is machine mastery through autonomy, competence, and run identity,
  - the main emotional cadence is `Overdrive` power, followed by `Stress` vulnerability, then polarize / pivot / patch,
  - reward, shop, event, and race-rewrite moments can support that cadence but should not replace it.
- Added Section 5 scope and risk direction:
  - use a gameplay validation slice first,
  - use the bounded A-scope as Itch sale validation,
  - use A or A+ as the Steam demo candidate without adding Steam integration to this repo state,
  - treat Brotato-like B-scope as the launch target only after earlier gates prove readability, conversion, and content demand,
  - mark launch scope growth, unreadable frontline causality, and machine-axis override as high or critical risks.
- Added Section 5 scope compression direction:
  - no fixed release-date target is currently assumed,
  - quality gates matter more than calendar pressure,
  - if scope must compress, reduce high challenge tiers and event breadth before cutting the core machine,
  - do not let "make a better game" become an unbounded scope rule.
- Added Section 5 pillar tension direction:
  - the formal tensions are `Unit` becoming the only meaningful axis and `Overdrive` becoming a generic emergency button,
  - race, relic, shop, and event systems are accepted as support systems for the ball machine, with drift risk during implementation/content design,
  - high-Gold builds are accepted when they remain named builds with cost, counterplay, and machine-axis identity.
- Tightened Section 5 launch scope:
  - B launch target is now a finite content list: 4 race identities, 12 core build families, 36-42 shop items, 36-42 relics, 18-24 normal enemies, 6 elite counters, 4-5 Bosses or endpoints, 18-24 events, and 5-8 challenge tiers,
  - launch scope risk drops from critical to high because the list is finite but still ambitious.
- Added Section 6 consistency cleanup:
  - formalized platform, session, and premium plus DLC monetization anchors inside `docs/gdd.md`,
  - added explicit design pillars for machine primacy, axis commitment, polarize / pivot / patch decisions, `Overdrive`, support-system boundaries, and readability before content breadth,
  - normalized launch scope wording from race or character identities to race identities.
- Added prototype slice plan artifact:
  - saved `docs/gstack-artifacts/yang-mvp-slice-plan-20260602-215006.md`,
  - selected `Mechanic Prototype: Three-Axis Readability Battle Lab`,
  - primary risk is `Unit` becoming the only axis players understand or value,
  - secondary risk is unreadable machine-to-frontline causality,
  - success gate is at least 3/5 target players answering at least 3 of 4 post-battle causality questions correctly.

## Earlier History

- The previous repository state was a playable Vite / TypeScript / Phaser Web MVP.
- That MVP used legacy `Standby / decision / Gold / Magic / Upgrade` concepts.
- Those implementation details are no longer formal design truth.
- Historical discussion and useful design direction have been consolidated into `docs/gdd.md`.

## Next Work

The next useful step is design, not implementation:

1. Review the current `docs/gdd.md` for contradictions.
2. Decide the first formal race roster.
3. Decide the first enemy set, including the first Junk polluter.
4. Draft the first machine shop inventory and Gold curve.
5. Only after that, create a fresh implementation slice plan.
