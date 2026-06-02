# Progress

## Current Documentation Set

As of 2026-06-01, the project keeps one active documentation set:

- `README.md` for run and validation.
- `docs/gdd.md` for canonical design and source index.
- `docs/PROGRESS.md` for recent progress and verification notes.

Historical research files, goal files, execution plans, and gstack artifacts were consolidated into `docs/gdd.md` and removed from the active repo docs.

## 2026-06-02

- Updated active docs so formal design language uses Tuning / Calibration / Forge Zone, not Standby, for the left non-spawn machine chamber.
- Marked remaining Standby / `decision` / Gold / Magic / Upgrade wording as legacy Web MVP implementation detail rather than future design truth.
- Reframed the next design discussion around Prime / Echo / Guide consequence readability and the FTUE tuning slice.

## 2026-06-01

- Consolidated the documentation set to `README.md`, `docs/gdd.md`, and `docs/PROGRESS.md`.
- Rewrote `docs/gdd.md` as the single canonical design document, separating current prototype facts from accepted future direction.
- Folded the useful content from the former current gameplay snapshot, v1.1/v1.2 research notes, three-chamber blueprint goal, long battlefield spec, legacy Standby/Launch/Unit spec, Arcane secondary plan, and import source map into `docs/gdd.md`.
- Removed stale duplicate docs after consolidation so future agents do not confuse old research, goal contracts, and execution plans with current truth.
- Ran `/game-import` earlier as a document consolidation pass and established the rule that progress-log claims are leads for verification, not proof by themselves.
- Recorded the accepted Tuning redesign direction: long-term Tuning / Calibration / Forge Zone uses Prime, Echo, and Guide as the base slots; Gold moves to post-battle Salvage/planning value, Magic becomes presentation/support behavior instead of a base direct-damage slot, and Overflow/Gate stay in Unit topology, buildings, rewards, or pacing.
- Added and documented the Arcane secondary Rune validation slice: optional `secondaryRaceId: 'arcane'`, run-local `arcaneRune` state, legacy Magic/Upgrade-to-Rune conversion, Gold exclusion, automatic Unit Spawn Rune spending, HUD feedback, phase telemetry, and deterministic probe coverage.
- Added the full-run prototype shell: setup panel, Hive/Mech main-race selection, optional Arcane secondary, victory/failure run summaries, machine-diagnosis tags, recent chain history, restart, and change-setup actions.

## 2026-05-31

- Created the first canonical `docs/gdd.md` from repository docs and source-facing behavior.
- Ran `/game-review` sections that set the main design direction:
  - Current MVP is a web gameplay validation slice.
  - Formal production target is Godot / Steam.
  - Commercial model is premium purchase plus DLC.
  - Target players are roguelite, auto-battle, and Castle Fight-style players.
  - Full runs target a Slay the Spire-like 45-60 minute three-act structure.
  - Fail state should teach through machine-diagnosis summaries.
  - Gold should be combat-inert in the formal design.
  - Research should become doctrine progress, not a long-term in-combat shop currency.
  - Main-plus-secondary race pairing is allowed, but main race owns Guardian Hero and building identity.
- Defined future directions for War Engine Buildings, Bastion Buildings, Guardian Hero, and Arcane Council / Rune.

## 2026-05-29

- Reworked the top pinball row into the legacy Web MVP shape: Standby Zone, Launch Zone, and Unit Spawn Zone. Formal design now calls the left chamber Tuning Zone.
- Changed Launch outcomes to legacy ids `standby / split / spawn`; formal design reads these as `tuning / split / spawn`.
- Removed visible Spawn from legacy Standby, leaving Gold, Magic, and Upgrade as temporary Web MVP slots before the Prime / Echo / Guide rewrite.
- Reworked phase-end rewards into fixed three-chamber blueprint offers: Launch, legacy Standby/Tuning, Unit.
- Added blueprint metadata and mapped legacy rewards into same-chamber fallback pools.
- Added natural blueprint reward probe to prove non-debug phase rewards can create chamber builds, recover non-Spawn value, queue and deploy units, and produce combat impact.
- Added global 1x / 2x / 4x simulation speed.
- Slowed Unit Spawn high-tier gate opening so high-tier access remains a real phase pressure point.
- Added or updated build telemetry, reward text wrapping, camera focus, debug/build drawer behavior, and Launch Zone weights.

## Validation Commands

Use the fastest relevant command first, then broaden:

```bash
npm run typecheck
npm test
npm run build
npm run probe
npm run audit:mvp
```

For local visual smoke:

```bash
npm run smoke:build-visuals
```

## Next Work

Recommended next skill: `/game-review` on `docs/gdd.md`, focused on Tuning / Prime-Echo-Guide consequence readability and FTUE.

If the next question is implementation truth rather than design quality, use `/gameplay-implementation-review` or a focused source audit.
