# Game Review: Machine Spec Split And GDD Structure Check

Game: planB
Branch: codex/three-axis-readability-battle-lab
Date: 2026-06-03
Mode: scoped `/game-review`
Status: DONE_WITH_CONCERNS

## Scope

This is not a full six-section GDD review. The requested check is narrower:

> After splitting out the machine spec, does `docs/gdd.md` still read as the top-level game design instead of a machine-rule encyclopedia?

Files reviewed:

- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `README.md`
- `AGENTS.md`
- `docs/PROGRESS.md`

## Structural Verdict

The split works.

`docs/gdd.md` now owns:

- game intent,
- design pillars,
- core loop summary,
- machine contract summary,
- economy and shop direction,
- reward/build direction,
- enemy direction,
- race direction,
- run structure,
- risk and next decisions.

`docs/machine-warehouses.md` now owns:

- `Launch / Tuning / Unit` concrete responsibilities,
- baseline machine flow,
- `Launch Route Board`,
- `Split / Recycle / Junk`,
- `Gate / Prime / Echo / Surge`,
- 4 active Unit slots,
- frontline read types,
- counter and Overdrive component rules,
- unresolved machine questions.

That is the right separation. A future implementation handoff can now read `docs/gdd.md` for why the game exists, then `docs/machine-warehouses.md` for what the machine actually does.

## Scoped Score

```text
GDD Structure Score
═══════════════════════════════════════════════
  Top-level intent clarity:        9/10
  Machine-rule separation:         8/10
  Canonical source clarity:        8/10
  Residual duplication risk:       6/10
  Implementation handoff readiness:7/10
  ─────────────────────────────────────────────
  SCOPED TOTAL:                    7.6/10
```

## Findings

### 1. GDD no longer reads like a machine rulebook

Before the split, `Launch`, `Tuning`, and `Unit` carried full rules inside the GDD. After the split, the GDD keeps a 20-line machine contract and points to `docs/machine-warehouses.md`.

This is the correct direction. The GDD now has a chance to stay readable for direction review, pitch work, and future scope decisions.

### 2. The machine spec is now the implementation-facing source

The new spec gives implementation enough concrete material:

- `Forge -> Pool -> Launcher -> Launch Route Board`
- `Gate / Prime / Echo / Surge`
- 4 active Unit slots
- queue deployment as separate timing
- component-based counters
- axis-bound Overdrive

The next implementation handoff should cite both files. It should not ask the GDD to carry low-level machine behavior again.

### 3. Residual duplication remains in build examples

The GDD still contains early build shapes and node chains with specific effects like `Front Return`, `Echo Hot Slot`, and `Squad Merge`.

This is acceptable for now because those tables explain run identity and build direction, not baseline machine rules. But if those tables keep growing, they should become a later `docs/build-shapes.md` or move into a Hive MVP handoff artifact.

### 4. Canonical source boundary is fixed

`README.md` and `AGENTS.md` now identify `docs/machine-warehouses.md` as canonical for machine rules. `AGENTS.md` also now includes `Gate` as a formal Tuning base slot.

That prevents the next session from using the stale `Prime / Echo / Surge only` baseline.

## Design Consistency

```text
Design Consistency:
  Voice:        CONSISTENT - 0 major violations found
  Boundaries:   4/5 boundaries checked, 0 broke design identity
  Storytelling:  Not evaluated - no visual/audio/narrative implementation in docs-only state

  Worst remaining issue:
    Build-shape tables in the GDD could become the next rule-encyclopedia sink if more effects are added there.
```

Boundary checks:

- Machine rules have a canonical file: pass.
- GDD still states design pillars and run promise: pass.
- README and AGENTS route future work to the right files: pass.
- Open machine questions are visible instead of hidden: pass.
- Future content tables may grow too large: watch.

## Playtest Protocol

No new playtest protocol is needed for this document split. The relevant future observation guide remains machine readability:

- Can the player identify whether the run is `Launch / Tuning / Unit` driven?
- Can the player identify which component a counter attacked?
- Can the player identify what `Overdrive` amplified?
- Can the player explain why the frontline moved or stalled?

## Not In Scope

- Full GDD six-section score: deferred because the requested task is document structure after the machine spec split.
- Balance math for Route Board ratios, Gate width, Gold, or shop pricing: defer to `/balance-review`.
- Hive unit roster: defer to `/game-ideation`.
- Implementation package: defer to `/implementation-handoff` after Route Board ratios and Hive 4 active slots are locked.

## Completion Summary

```text
/game-review Completion Summary
═══════════════════════════════════
Mode: scoped document-structure review
GDD: docs/gdd.md
Machine Spec: docs/machine-warehouses.md
Branch: codex/three-axis-readability-battle-lab
Status: DONE_WITH_CONCERNS

  Structure:         7.6/10
  GDD role:          top-level design restored
  Machine spec role: canonical machine rules established
  Main concern:      build-shape tables may become the next overgrown rules section

Next Step:
  PRIMARY: /game-ideation - define Route Board baseline outcome ratios and Hive 4 active Unit slots
  IF GDD grows again: /game-review - check whether build-shape content needs a separate spec
```
