# Machine System Self-Check

**Date:** 2026-06-03
**Project:** planB
**Scope:** `Launch / Tuning / Unit` machine system, `Machine Contract 1.0`
**Excluded:** Hive roster, building system, full enemy roster, boss design, implementation code
**Status:** DONE_WITH_CONCERNS

## Verdict

The ball machine is structurally viable. It now has a real three-axis shape, enough named components for build design, and a contract that can stop race, relic, shop, and enemy effects from becoming hidden global output.

It is not ready for implementation handoff yet. The missing part is not "more race design." The missing part is machine-level stress testing: flow math, Overdrive binding, and a first modifier inventory written in the ownership format.

## Score

| Area | Score | Reason |
|---|---:|---|
| Axis separation | 8/10 | `Launch`, `Tuning`, and `Unit` have distinct responsibilities and different frontline reads. |
| Build lever coverage | 8/10 | Each warehouse has enough components to support multiple build families. |
| Extension safety | 8.5/10 | Ball payload, modifier ownership, resolution order, and loop guards create a usable safety frame. |
| Baseline flow readiness | 5.5/10 | Current Forge / Launcher / return numbers are likely to saturate Pool too often before tuning. |
| Player readability contract | 6.5/10 | The doc says marks and reads are needed, but not yet enough to prevent Tuning from becoming hidden math. |
| Counter and Overdrive clarity | 7/10 | Counter bounds are sane. Overdrive cadence is locked, but Overdrive axis binding is still open. |

**Machine System Health:** 7.3/10

This is a design that can move forward after fixing three machine-level concerns. It should not enter full race design first.

## What Is Locked Enough

### Launch

Launch is not just a firing queue. It owns:

- Forge cadence,
- Pool capacity and FIFO pressure,
- Launcher cadence,
- Route Board tendency,
- Split,
- Recycle,
- Waste,
- Junk pressure,
- ball tags.

This is enough for Launch builds to be more than "attack speed." The strongest Launch identity should come from return position, route bias, waste control, pollution handling, and ball supply pressure.

### Tuning

Tuning has a workable baseline:

- `Gate`: ordinary Unit entry,
- `Prime`: current Unit hit becomes `value + 1`,
- `Echo`: one extra Unit progress settlement,
- `Surge`: triggered queue entry deploys after 0.25s.

The Gate decision fixes the old problem where every Tuning hit felt like a reward. Ordinary entry now exists, so Prime / Echo / Surge can be rare and legible.

### Unit

Unit is in the right shape:

- 4 neutral active slots,
- equal baseline width,
- race-defined unit templates,
- different progress thresholds allowed,
- queue layer separated from progress filling,
- 0.5s baseline deploy beat,
- one queue entry per physical ball in the baseline.

The important lock is neutrality. Slot position does not mean role. That keeps future races from being forced into one preset structure.

### Machine Contract 1.0

The contract is doing real work. It blocks the most likely future failure:

> "This relic makes everything better by 20%."

That kind of effect would flatten the game. The ownership format forces every modifier to say which warehouse and component it changes.

## Top Concerns

### P1: Baseline Pool Flow May Saturate Too Often

Current first-pass values:

- Forge creates 1 ball about every 1.0s.
- Launcher fires 1 ball about every 1.3s.
- Route Board returns balls through Split and Recycle.
- Pool capacity is 5.

Rough flow check:

- Launcher fires about 0.77 balls/s.
- Split + Recycle return average is about 0.45 balls per fired ball.
- Returned balls add about 0.35 balls/s.
- Forge adds about 1.0 balls/s.
- Total input before overflow is about 1.35 balls/s into a Pool that outputs about 0.77 balls/s.

That means baseline Pool pressure will likely be constant, not occasional. If overflow is always happening, three things break:

1. Split / Recycle feel wasted because returned balls often fail on full Pool.
2. Pool Polluter feels punitive because the Pool is already full before the enemy acts.
3. Launch builds become about "stop overflow" instead of "shape throughput."

Recommended fix before implementation:

- Define a baseline flow target: Pool should usually sit around 3-4 / 5 during normal baseline play.
- Treat overflow as occasional pressure, not permanent background noise.
- Revisit at least one of these values before implementation: Forge cadence, Launcher cadence, return amount, or Pool capacity.

### P1: Overdrive Axis Binding Is Not Yet Defined

The doc says:

- one Overdrive per battle,
- it resolves as Launch / Tuning / Unit,
- weak-axis Overdrive should look weaker.

Still missing:

- Does the player choose the axis at press time?
- Is the axis determined by the current build investment?
- Does a reward/shop item define the Overdrive variant?
- Can the player hold Overdrive as a panic response and still get a useful effect?

If this remains open, Overdrive can drift back into a general emergency button.

Recommended lock:

> Overdrive variant should come from the current committed machine axis or a named Overdrive modifier, not free axis selection at press time.

This keeps the button tied to build identity.

### P1: The First Modifier Inventory Must Use The Contract

The machine has enough theoretical levers. It has not yet proven that real rewards, shop items, relics, and events can be written cleanly against those levers.

Before Hive, write a small neutral modifier inventory:

- 4 Launch modifiers,
- 4 Tuning modifiers,
- 4 Unit modifiers,
- 3 enemy debuffs,
- 3 Overdrive variants.

Each entry should use:

`warehouse -> component -> operation -> scope -> player read -> failure risk`

If that inventory cannot produce three readable build shapes without raw stat effects, the machine is not actually ready.

### P2: Tuning Is Still At Risk Of Becoming Hidden Math

Tuning results happen before Unit, but their impact is read after Unit settlement. That is dangerous.

`Prime` and `Echo` especially need player-facing feedback:

- Prime must mark the ball or Unit hit as bigger before settlement.
- Echo must visibly re-apply progress to the same slot.
- Surge must visibly accelerate the triggered queue entry, not the whole queue.

This is not debug observation. This is player comprehension.

### P2: Unit One-Entry Cap Is Safe But May Feel Too Restrictive Later

The one-entry-per-physical-ball rule protects the baseline. Keep it.

But one future Unit build family should explicitly break it in a controlled way. Otherwise high-value Unit play may feel artificially capped.

Good future exceptions:

- named multi-entry unlock,
- overflow transfer,
- squad merge,
- queued duplicate with reduced value.

Bad exception:

- any overflow automatically creates repeated entries without a named rule.

### P2: Route Board Tendency Needs A Production Interpretation

The doc says Route Board outcomes are tendencies, not exact promises. That works for design.

Before implementation, decide whether tendencies are:

- mostly physical outcomes from geometry,
- weighted outcomes presented through physical animation,
- or hybrid.

Do not let "real physics purity" become a production trap. The player needs a readable machine, not a physics thesis.

## Buildability Check

### Launch Build Families Available

- High intake: Forge / Launcher cadence.
- Return flood: Split / Recycle / front insertion.
- Capacity control: Pool capacity / overflow buffer.
- Pollution play: Junk filter / purify / convert.
- Route control: Route Board bias / lane preference.
- Tag play: clean ball tags, inheritance exceptions, tag cleanup.

Pass.

### Tuning Build Families Available

- Wider reward slots.
- Prime value scaling.
- Echo persistence / hot slot.
- Surge deployment acceleration.
- Cross-slot progress.
- Tuning mark conversion.
- Tuning counterplay against Echo Breaker.

Pass with readability concern.

### Unit Build Families Available

- Low-threshold flow.
- High-threshold heavy release.
- Queue burst.
- Squad merge.
- Slot adjacency.
- Overflow handling.
- Loadout / roster selection later.
- Deployment timing variants.

Pass with one-entry cap watchpoint.

## Extensibility Check

The design can support future races if these boundaries hold:

- race templates define unit identity and frontline expression,
- machine modifiers define warehouse behavior,
- buildings improve stats / formation / support without replacing the machine,
- relics and events must declare machine ownership,
- enemy debuffs attack named components with warnings.

The neutral Unit slot model is the main reason this works. Do not replace it with fixed roles like "tank slot / damage slot / elite slot" in the baseline.

## Contradiction Check

No fatal contradiction found between `docs/gdd.md` and `docs/machine-warehouses.md`.

Non-fatal tension:

- GDD names early build rewards like `Echo Hot Slot` and `Squad Merge`, but these are not yet rewritten in `Machine Contract 1.0` modifier format.
- GDD says the first formal race direction is moving toward Hive MVP, but the machine self-check correctly delays Hive until neutral modifier proof.

## Recommended Next Step

Do not enter Hive yet.

Next work should be:

1. Lock a baseline Pool flow target.
2. Lock Overdrive axis binding.
3. Draft the first neutral modifier inventory using Machine Contract 1.0.

After those three are accepted, enter Hive unit template design.

```text
STATUS: DONE_WITH_CONCERNS

Next Step:
  PRIMARY: /game-ideation — resolve the three P1 machine-level decisions
  AFTER ACCEPTED: /game-review — quick contradiction check after docs update
  THEN: /game-ideation — first Hive unit templates
```
