# PlanB MVP v0 Implementation vs Design Gap Audit

Date: 2026-06-11

Scope: current Godot MVP v0 implementation in `mvp/` compared against the current formal design docs under `docs/`.

This file records known implementation gaps only. It does not add new canon, does not replace the design docs, and does not imply that every listed item must be implemented in the next slice.

## Current Alignment

- Player-facing flow exists: Main Menu -> Guardian Contract -> Battle Screen -> Battle Result / Reward / Shop / Rest -> Final Result.
- Guardian Contract is separated from Battle Screen.
- Debug UI is out of player-facing scope.
- Guardian is represented as an in-world base / combat entity, not as a HUD panel.
- Deploy Lane uses direct lane selection with the selected lane highlighted.
- Battlefield has three lanes, player / enemy Lane Gates, base buffer, Guardian HP, unit deployment, and simplified lane combat.
- Ball machine has Launch / Tuning / Unit boards, Queue, selected Deploy Lane bridge, visible ball motion, slot feedback, and global speed control.
- Launch and Tuning slot widths now follow first-pass targets:
  - Launch: Tuning / Split / Recycle / Waste = 65 / 15 / 15 / 5.
  - Tuning: Gate / Prime / Echo / Surge = 55 / 15 / 15 / 15.
- Forge / Pool / Launcher baseline cadence is implemented:
  - Forge creates one clean ball every 2.2s when Pool is not full.
  - Launcher attempts to fire every 1.3s.
  - Pool empty causes Launcher dry-fire, not instant ball creation.
  - Pool full causes Recycle return failure.

## Major Gaps

### 1. Ball Machine Physicality

Design source: `docs/ball-machine-physical.md`, `docs/machine-warehouses.md`

Current implementation:

- Ball paths are scripted polylines.
- Route outcomes are selected by deterministic runtime sequences.
- Pegs and launcher sway are visual; they do not physically determine the result.

Design expectation:

- MVP v0 physical model A expects the visible ball to bounce through machine boards and land into result slots.
- Physical landing should be the player-facing cause of Tuning / Split / Recycle / Waste and Gate / Prime / Echo / Surge.

Gap:

- The current system is readable, but not yet the intended physical machine.

Priority: P0 for formal machine feel.

### 2. Ball Payload, FIFO Pool, and Junk

Design source: `docs/machine-warehouses.md`, `docs/enemy-rules.md`, `docs/rewards-economy.md`

Current implementation:

- Pool is represented as an integer `pool_count`.
- Balls do not carry `kind`, `value`, `tags`, `tuning_mark`, or `source_pass`.
- There is no real Junk Ball in Pool.

Design expectation:

- Pool is a visible FIFO buffer.
- Ball payload includes clean / Junk identity and tuning metadata.
- Junk occupies Pool capacity, fires and routes normally, but does not produce valid settlement.

Gap:

- Pool and ball identity are not rich enough to support Pool Polluter, Junk Sieve, Front Recycle, or future named ball rules.

Priority: P0 for counter / shop causality.

### 3. Blocked Bounce Behavior

Design source: `docs/ball-machine-physical.md`, `docs/machine-warehouses.md`

Current implementation:

- Unit board can record `Blocked Bounce` when a slot is not exposed.
- The flight ends after the blocked result.

Design expectation:

- Unit `Exposure Gate` should read as a physical blocker.
- A blocked ball should visibly bounce / continue according to the physical board behavior.

Gap:

- The state label exists, but the actual bounce continuation is not implemented.

Priority: P1.

### 4. Guardian Contracts and Skills

Design source: `docs/mvp-hive-loadout.md`, `docs/guardian-system.md`

Current implementation:

- Guardian choice sets identity, main axis, HP, and player-facing text.
- Guardian base presence exists on battlefield.
- Strategic and tactical skills are not fully connected to runtime machine / battlefield logic.

Design expectation:

- Hive Vein Mother:
  - Strategic: Recycle hidden pity, 15% baseline, guaranteed on 6th legal Recycle, extra clean ball, still respects Pool full failure.
  - Tactical: low-frequency bind against base intruders.
- Hive Acid Crown Mother:
  - Strategic: Gate miss counter converts a future Gate into Prime after threshold.
  - Tactical: acid counterspit after real Guardian HP damage.

Gap:

- Guardian Contract is presented, but its named machine and combat contracts are mostly not executed.

Priority: P0 for Guardian choice meaning.

### 5. Enemy Counter Rules

Design source: `docs/enemy-rules.md`

Current implementation:

- Counter selection and result text exist.
- Pool Polluter, Echo Breaker, and Stagger Punisher are simplified into immediate or scripted effects.

Design expectation:

- Pool Polluter warns, then inserts Junk Ball into Pool, with active follow-up inserts.
- Echo Breaker warns, then downgrades the next Echo copy into ordinary Gate settlement.
- Stagger Punisher monitors empty Queue / deployment gap and spawns pressure after warning.

Gap:

- Counters do not yet attack the named machine component with the designed cause-effect chain.

Priority: P0 after ball payload exists.

### 6. Rewards, Shop, and Persistent Machine Modifiers

Design source: `docs/rewards-economy.md`

Current implementation:

- Reward / shop / rest screens exist.
- Choices are visible and can affect telemetry / flow.
- Some base slot effects exist, such as Prime progress, Echo extra settlement, and Surge deploy delay.

Design expectation:

- `Pool Pocket`, `Front Recycle`, `Junk Sieve`, `Prime Charge`, `Echo Latch`, `Surge Buffer`, `Queue Brace`, `Muster Pair`, and `Slot Primer` should persistently modify named machine components.

Gap:

- Most reward / shop choices are not yet durable runtime machine contracts.

Priority: P0 for run progression.

### 7. Unit-Specific Combat Roles

Design source: `docs/mvp-hive-loadout.md`

Current implementation:

- Four Hive units can be generated and deployed.
- Battlefield combat is mostly generic single-target lane combat.

Design expectation:

- Slot 3 Acid Sac should create a visible small-area splash / breakpoint role.
- Slot 4 Crush Shell Beast should have a limited sweep / multi-target role.

Gap:

- Unit identity exists in naming and stats, but role-defining combat behavior is incomplete.

Priority: P1.

### 8. Guardian Combat Behavior

Design source: `docs/battlefield-rules.md`, `docs/mvp-hive-loadout.md`

Current implementation:

- Units can attack enemy / player Guardian after Gate break.
- Guardian HP and base zone are visible.

Design expectation:

- Player Guardian has limited base defense behavior against intruders.
- Endpoint Guardian has telegraphed sweep behavior.

Gap:

- Guardian is present, but combat behavior is still much thinner than the design.

Priority: P1.

### 9. Battle Duration, Wave Pressure, and Endpoint Pacing

Design source: `docs/enemy-rules.md`, `docs/battlefield-rules.md`

Current implementation:

- Playable flow uses compressed battle durations for UI-flow verification.
- Enemy pressure is simplified and scripted.

Design expectation:

- Ordinary battles target roughly 90-150s.
- Endpoint battle targets roughly 165-195s.
- Pressure phases and counters should create readable escalation.

Gap:

- Current timing is useful for testing flow, but not representative of formal battle pacing.

Priority: P2 until core machine / counter contracts are real.

### 10. Visual and Audio Feedback Completeness

Design source: `docs/DESIGN.md`, `docs/ball-machine-physical.md`

Current implementation:

- Shape / color / label feedback exists for major board results.
- PNG loading warnings have been addressed through resource loading.
- Known headless cleanup noise is filtered in project verifier entrypoints.

Design expectation:

- Each physical state should have clear visual language and small audio families:
  - Natural Hit
  - Forced Redirect
  - Blocked Bounce
  - Split / Recycle return
  - Waste
  - Counter Disruption

Gap:

- Visual feedback is partial, and audio feedback is not implemented as a full state language.

Priority: P2.

## Suggested Implementation Order

1. Replace integer Pool with FIFO ball payload objects.
2. Implement Junk Ball and Pool Polluter / Junk Sieve around the same payload model.
3. Add persistent machine modifier state for Guardian strategic contracts and reward / shop choices.
4. Convert Echo Breaker, Prime Charge, Echo Latch, Surge Buffer, Queue Brace, and Slot Primer into real component modifiers.
5. Upgrade Unit board blocked bounce and physical routing model.
6. Add Guardian tactical skills and endpoint sweep.
7. Add unit-specific splash / sweep behaviors.
8. Revisit battle duration, enemy waves, and pacing only after the core causality chain is real.

## Verification Notes

Current verification command:

```bash
bash mvp/tools/verify_all.sh
```

As of this audit, the verifier confirms the current playable UI flow and several machine contracts. It does not yet prove physical routing, ball payload identity, Guardian skills, counter rules, reward modifiers, or full battle pacing.
