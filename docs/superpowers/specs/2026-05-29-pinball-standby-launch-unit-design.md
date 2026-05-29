# Pinball Standby Launch Unit Layout Design

## Context

The prototype currently has a left-to-right top pinball pipeline:

- Launch Zone: split / fire / miss
- Decision Zone: gold / magic / spawn / upgrade
- Unit Spawn Zone: five race unit slots and the high-tier gate

The requested change keeps the ball machine as the core system but changes the meaning and order of the top chambers. The launch chamber moves to the middle. The former Decision Zone becomes the left-side Standby Zone. The right-side Unit Spawn Zone remains the unit realization chamber.

This is a gameplay logic and layout pass, not an art pass.

## Goals

- Reorder the top machine to left Standby Zone, middle Launch Zone, right Unit Spawn Zone.
- Rename the player-facing Decision Zone concept to Standby Zone.
- Change the middle Launch Zone result slots to `standby`, `split`, and `spawn`.
- Route a launch ball that lands on `standby` into the left Standby Zone.
- Route a launch ball that lands on `spawn` directly into the right Unit Spawn Zone.
- Keep split behavior consistent with the current relaunch logic, but cap one original launch ball at two split outcomes.
- Remove the spawn slot from the Standby Zone for now.
- Keep the Unit Spawn Zone behavior unchanged.

## Non-Goals

- No new Standby Zone slot types in this pass.
- No redesign of gold, magic, upgrade, research, non-spawn fallback, relic, building, or doctrine effects.
- No change to the five unit slots, unit slot progress requirements, high-tier gate, overflow, queue conveyor, or deployment queue.
- No networking, backend, PvP, or RTS pathfinding.
- No generated image work unless the existing visuals break.

## Chosen Approach

Use a minimal semantic rewire of the existing systems.

The current decision-slot system already handles the three effects that remain in the Standby Zone: gold, magic, and upgrade. The implementation should keep that logic path and remove only the visible and physical `spawn` decision slot from the left chamber. The middle Launch Zone becomes the explicit router into either Standby or Unit Spawn.

This gives the desired player-facing flow without forcing a broad rewrite of statistics, reward effects, telemetry, and probes that still depend on the current slot trigger semantics.

## Alternatives Considered

### Add A New Ball Stage Named `standby`

This would make the type model clean: launch balls route to standby balls or unit balls. It is the best long-term naming model if Standby later becomes a larger subsystem.

It is not the recommended first pass because the existing decision-slot effects, telemetry, probes, and tests already encode the current decision stage. Renaming everything now increases blast radius without adding immediate gameplay value.

### Keep Internals Fully Named `decision`

This would be the smallest code change: only visible labels would say Standby, while internal states would remain `decision` and launch outcomes would remain `fire`.

It is too likely to create confusion during the next iteration. The new launch slots should at least expose player-facing and test-facing names that match the requested flow: `standby`, `split`, and `spawn`.

### Recommended Hybrid

Use player-facing Standby naming in layout, labels, launch outcomes, tests, and documentation, while reusing the existing slot-trigger implementation for the three remaining Standby effects. If deeper Standby mechanics are added later, a full `BallStage = 'standby'` rename can be done as a follow-up.

## Top Machine Layout

The top row becomes:

| Position | Chamber | Purpose |
|---|---|---|
| Left | Standby Zone | Resolve gold, magic, or upgrade outcomes |
| Middle | Launch Zone | Fire balls and route them to Standby, split, or Unit Spawn |
| Right | Unit Spawn Zone | Convert unit balls into race-specific unit-slot progress |

The existing panel proportions can be adjusted conservatively so the middle launcher has enough readable width and the right Unit Spawn Zone still fits five slots. The exact width constants should be tuned in scene layout after the behavior is correct.

## Launch Zone

The Launch Zone contains three physical result slots:

| Slot | Effect |
|---|---|
| `standby` | Destroy the launch ball, draw a transfer trail to the Standby Zone, and spawn a Standby/decision ball with the same value and tags |
| `split` | Destroy the launch ball and relaunch child launch balls in the Launch Zone |
| `spawn` | Destroy the launch ball, apply spawn-routing tag/value rules, draw a transfer trail to the Unit Spawn Zone, and spawn a unit ball |

Default slot order should be `standby / split / spawn`.

The current 1:3:1 width weighting can remain for the first pass, with `split` in the center as the broad outcome. This keeps the current physical feel while changing where non-split balls go.

## Split Limit

The current split lineage counter should remain, but the cap changes:

- One original launch ball may resolve `split` at most two times.
- If the same original launch ball would resolve a third split, convert that outcome to `spawn`.
- The forced outcome should be visible in floating text, similar to the current split-limit message.

Existing split modifiers still apply when a split is allowed:

- `split+` adds one child ball and is consumed by the split plan.
- `launch_splitter_rack` adds extra child balls.
- Child balls keep the same original ball lineage id for the split cap.

## Standby Zone

The left Standby Zone has three visible and physical slots:

1. Gold
2. Magic
3. Upgrade

The current spawn decision slot is removed from this chamber.

The three remaining effects keep their current behavior:

- Gold grants currency and feeds gold-hit building logic.
- Magic applies magic damage when enabled and feeds magic copy/research logic.
- Upgrade increases later spawn level value and keeps race-specific upgrade behavior.

Non-spawn fallback remains valid. Since the Standby Zone has no direct spawn slot, its gold/magic/upgrade hits should still count as non-spawn decisions and can still create pending spawn marks or research return value. Those marks are consumed the next time the Launch Zone sends a ball to Unit Spawn.

## Unit Spawn Zone

The right Unit Spawn Zone stays functionally unchanged:

- Five current-race unit slots remain visible.
- Requirements remain 1, 3, 5, 7, and 9.
- Progress, overflow, queueing, pending copies, pending level bonus, elite promotion, high-tier gate, and gate bounce behavior remain unchanged.

The only upstream change is that unit balls now come directly from the Launch Zone `spawn` outcome rather than from a spawn slot inside the former Decision Zone.

## Data And Code Boundaries

Expected code areas:

- `src/types/game.ts`: update launch outcome identifiers if needed.
- `src/systems/PinballMachineSystem.ts`: define the new launch slot ids, labels, default weights, and split cap.
- `src/data/slots.ts`: remove the visible spawn slot from the Standby/decision slot list while keeping slot state for systems that still record spawn events.
- `src/systems/SlotTriggerSystem.ts`: keep gold, magic, upgrade behavior; keep spawn trigger available for statistics or direct helper calls if still needed.
- `src/scenes/PrototypeScene.ts`: reorder top zones, rename labels, route Launch `standby` to the left chamber, route Launch `spawn` to the Unit Spawn Zone, and remove the old decision-to-unit spawn transfer.
- `src/systems/prototypeRules.test.ts`: cover the changed launch outcomes, split cap, Standby slot list, and direct Launch-to-Unit route.
- `README.md`, `docs/CURRENT_GAMEPLAY_DESIGN.md`, and `docs/PROGRESS.md`: update player-facing descriptions after implementation.

Keep the first pass readable and scoped. Do not introduce a large routing framework for future Standby slots until those slots exist.

## Testing Plan

Unit tests:

- Launch outcome definitions are ordered as `standby`, `split`, `spawn`.
- Launch outcome slots keep expected default width weights.
- The third split for the same original launch ball resolves as `spawn`.
- Standby slot definitions expose only gold, magic, and upgrade.
- Gold, magic, and upgrade still trigger their existing state changes.
- A direct spawn route can apply pending spawn marks and resolve a unit ball into a unit slot.

Build validation:

- `npm run typecheck`
- `npm run build`
- `npm test` if the focused changes touch shared rule coverage.

Browser smoke:

- Launch the local Vite app.
- Confirm the top row reads Standby Zone, Launch Zone, Unit Spawn Zone.
- Confirm the middle launch slots read Standby, Split, Spawn.
- Confirm Standby hits move balls left and trigger only gold, magic, or upgrade.
- Confirm Spawn hits move balls right and can queue/deploy units.
- Confirm repeated split lineage stops after two split outcomes.

## Acceptance Criteria

- The launch chamber is visually and physically in the middle.
- The left chamber is named Standby Zone and has no spawn slot.
- The middle launch chamber has `standby / split / spawn` result slots.
- A launch ball can enter the Standby Zone or Unit Spawn Zone directly based on its Launch Zone outcome.
- Split behavior is still recognizable but capped at two split outcomes per original launch ball.
- The Unit Spawn Zone behavior remains unchanged.
- The prototype remains self-contained and locally runnable.
- The fastest relevant validation commands pass before implementation is called complete.
