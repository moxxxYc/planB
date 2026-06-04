# Prototype Slice Plan

Game: planB
GDD Status: Reviewed. Current GDD supports a C validation slice, not direct B launch production.
Branch: mvp
Date: 2026-06-02
Supersedes: N/A

## Key Risk

Primary risk:

> `Unit` may become the only axis players understand or value, making `Launch` and `Tuning` feel like support layers instead of run-defining choices.

Secondary risk:

> Players may not read the link between machine-axis investment and frontline outcome. If they only see balls and units moving, Machine-to-frontline collapses into noise.

Diagnostic risk:

> `Overdrive` may become a generic emergency button. The current decision is to handle this through design constraints, then observe it as a diagnostic signal.

## Recommended Slice

Mechanic Prototype: Three-Axis Readability Battle Lab

This is not a demo, onboarding slice, economy slice, or vertical slice. It tests the smallest playable battle state that can fail the current design.

## Hypothesis To Validate

Target players can distinguish `Launch Flood`, `Tuning Echo`, and `Unit Queue Burst` as three different machine-to-frontline pressure patterns in short battles.

The slice succeeds only if `Unit` does not become the only axis players can explain, trust, or prefer.

## What To Build

- One battle screen:
  - left side: simplified ball machine with `Forge`, `Pool`, `Launcher`, `Prime / Echo / Surge`, and `Unit` slots,
  - right side: constrained auto-battle frontline,
  - no free RTS movement and no unit micro.
- Three hardcoded build presets:
  - `Launch Flood`: `Front Return` behavior, continuous small-flow pressure, `Pool Polluter` counter.
  - `Tuning Echo`: `Echo Hot Slot` behavior, repeated high-value waves, `Echo Breaker` counter.
  - `Unit Queue Burst`: `Squad Merge` behavior, batch surge pressure, `Stagger Punisher` counter.
- Three short battles:
  - each battle lasts 60-90 seconds,
  - each battle uses one preset,
  - order can be randomized for playtests,
  - each battle includes one clear counter window.
- One `Overdrive` activation per battle:
  - `Launch Overdrive` amplifies return and launcher throughput,
  - `Tuning Overdrive` amplifies Echo hot-slot repetition,
  - `Unit Overdrive` releases or extends the squad chain.
- A minimal result and question screen after each battle:
  - "What was the main axis this battle?"
  - "How did the enemy disrupt it?"
  - "What did Overdrive amplify?"
  - "Why did the frontline change?"

## What To Fake

- Art:
  - colored primitives, simple icons, and readable labels are enough.
- Audio:
  - placeholder beeps or no audio.
- Race identity:
  - use one neutral test race. Do not build Hive or Mech yet.
- Shop, event, relic, Gold curve, unlocks, and node map:
  - absent. They add noise to this test.
- Enemy roster:
  - only the three counter behaviors exist.
- AI depth:
  - enemies can follow deterministic scripts.
- Save, meta progression, menus, settings, and build selection:
  - debug controls are acceptable.

## What Not To Fake

- The machine-to-frontline causal chain:
  - balls must visibly create machine effects,
  - machine effects must visibly alter unit timing or pressure,
  - frontline pressure must visibly change because of those effects.
- Distinct axis reads:
  - `Launch Flood` must read as continuous replenishment,
  - `Tuning Echo` must read as repeated high-value waves,
  - `Unit Queue Burst` must read as batch surge.
- Enemy counter effects:
  - `Pool Polluter` must visibly interrupt Launch rhythm,
  - `Echo Breaker` must visibly weaken or swallow Echo windows,
  - `Stagger Punisher` must visibly punish long charge-up gaps.
- `Overdrive` directionality:
  - it must amplify the invested axis,
  - weak-axis or unrelated use should not solve every emergency state.
- Player observation:
  - test players must not receive strategy explanation beyond a one-minute goal briefing.

## Readability Design Requirements

This section is a narrow readability spec for the Three-Axis Readability Battle Lab. It is not a full game UI design system, not a race art direction pass, and not an implementation plan.

### Battle Screen Hierarchy

During battle, the screen must answer the 1-second combat test:

1. What machine axis is producing the current pressure?
2. What counter is warning or active?
3. What changed on the frontline because of the machine?
4. What did `Overdrive` amplify?

Information priority:

| Priority | Player must read | Screen treatment |
|---|---|---|
| P0 | Current axis effect | The active `Launch / Tuning / Unit` lane gets the strongest motion and contrast for that moment. Do not use a preset-name banner as the primary answer. |
| P1 | Counter warning and active effect | Warning appears on the targeted machine component before the effect, then leaves a visible after-effect for 1-2 seconds. |
| P2 | Frontline result | The frontline shows one of three pressure signatures: smooth flow, stepped repeated impact, or grouped charge. |
| P3 | `Overdrive` direction | The `Overdrive` control is visually attached to the axis it will amplify, not to player HP or general survival. |
| P4 | Debug labels | Labels can help testers orient, but they must not replace motion, shape, timing, and result feedback. |

The battle screen should keep the causal chain visible left to right:

```text
Launch lane -> Tuning lane -> Unit lane -> Frontline result
```

Do not collapse axes into tabs. All three axes need to stay visible enough that a player can see which one is active without opening a panel.

### Axis Visual Language

Use color only as support. Every axis must also have a shape, motion, and event-trace distinction so grayscale or colorblind players can still read the battle.

| Axis | Main region | Shape and motion | Player read | Must not do |
|---|---|---|---|---|
| `Launch` | `Forge / Pool / Launcher / Split / Recycle` | Round balls, FIFO Pool slots, forward arrows, return arrows, repeated small pulses. The Pool head has a thick outline and launch arrow. | "The machine is feeding pressure continuously." | Do not make Launch read only as "more units." The Pool rhythm and return rhythm must be visible before the frontline changes. |
| `Tuning` | `Prime / Echo / Surge` slots | Slot plates with copy afterimages. `Prime` shows a value plaque before the Unit hit. `Echo` shows a second ghost hit after the Unit hit. `Surge` shows chevrons on the deployment queue caused by that hit. | "The same hit is being amplified or repeated." | Do not hide Tuning as math text. The copy window must be visible at the slot before the frontline impact. |
| `Unit` | Unit slots, queue, deployment batch | Square slot tiles, fill chunks, queue stack, squad bracket around grouped units. | "A batch is charging, then releasing together." | Do not let Unit own all readable feedback. Queue and batch feedback must be different from Launch flow and Echo repetition. |

### Three Frontline Result Signatures

Each preset must create a different frontline trace. If testers can only say "more units appeared," the slice failed.

| Preset | Frontline signature | Machine trace before it | Result trace |
|---|---|---|---|
| `Launch Flood` | Sustained flow | Pool refills and launches at a visibly faster rhythm. Return arrows repeatedly feed near the Pool front. | Many small arrivals, smooth pressure-line movement, no single dominant impact. |
| `Tuning Echo` | Repeated heavy hit | Echo hot slot shows a copy afterimage and repeated hit ticks. | Fewer arrivals or waves, larger stepped frontline jumps, double-impact afterimage on the hit point. |
| `Unit Queue Burst` | Batch charge and release | Queue stack fills with same-unit entries, then a squad bracket forms. | A quiet charge gap followed by one grouped push. The group must read as a batch, not a faster stream. |

### Counter Warning And Effect States

Each counter needs a warning, active effect, and recovery read. Generic red alerts are not enough. The warning must appear on the component the counter will hit.

| Counter | Warning state | Active state | Effect state |
|---|---|---|---|
| `Pool Polluter` | 2-3 second warning on Pool slots: ghost Junk balls occupy future slots, with striped capacity markers. | 2-3 Junk Balls enter Pool and occupy capacity. Junk has a different shape or pattern from normal balls. | Launcher rhythm visibly stutters or wastes shots. The Pool shows "polluted slots" until Junk fires and disappears. |
| `Echo Breaker` | Break mark appears on an Echo hot slot or Echo window before the next copy. | Echo copy is weakened or swallowed. The expected ghost hit collapses or gets crossed out. | A short slot afterimage shows that the repeated hit failed or shrank, then the slot returns to normal. |
| `Stagger Punisher` | Frontline gap timer appears while squad charge-up is long. Warning is tied to no-deployment time, not HP panic. | Punisher pressure lands during the charge gap. | The frontline or base shows a "gap hit" marker, then the squad release can still answer if it arrives. |

### `Overdrive` Directionality

`Overdrive` must read as amplification of the current axis.

Rules:

- The control label and icon are axis-specific: `Launch Overdrive`, `Tuning Overdrive`, or `Unit Overdrive`.
- The control is visually attached to the axis lane it affects, not to base HP, player damage, or a universal panic area.
- The control should pulse only when the matching axis has something to amplify:
  - Launch: return balls, Pool pressure, or launcher throughput window.
  - Tuning: Echo hot state or Echo window.
  - Unit: active squad chain or same-unit queue buildup.
- Activation overlays only the affected axis components:
  - Launch: return arrows and Launcher cadence intensify.
  - Tuning: Echo afterimages persist or repeat without consuming hot state.
  - Unit: squad bracket releases or extends the chain.
- Unrelated emergency use should be visibly low-yield. It may still fire, but it should not look like a shield, heal, freeze, or generic rescue.
- The post-battle event strip must mark the `Overdrive` moment and the specific axis component it amplified.

### Post-Battle Questions And Recording

The result screen is part of the test, not a reward screen. It should not reveal the answer key before responses are recorded.

Result screen flow:

1. Freeze the battle result.
2. Show a short event strip with four lanes:
   - Axis events,
   - Counter warning and active effect,
   - `Overdrive`,
   - frontline pressure changes.
3. Ask the four questions.
4. Record answers, confidence, and observer notes.
5. Reveal or discuss answers only after all three battles are complete.

Question recording:

| Question | UI input | Correct-answer rule | Extra data |
|---|---|---|---|
| What was the main axis this battle? | `Launch / Tuning / Unit / Unsure` plus optional text. | Correct if selected axis matches preset and text does not reduce the answer to generic unit output. | Confidence 1-5. |
| How did the enemy disrupt it? | Counter selection plus short text. | Correct if the player names the targeted component and the visible disruption. | Did they mention Pool, Echo slot/window, or charge gap? |
| What did `Overdrive` amplify? | Axis selection plus observed component. | Correct if the player ties `Overdrive` to the axis component, not danger or rescue. | Flag panic/rescue wording. |
| Why did the frontline change? | Short text, optionally assisted by choosing flow / repeated hit / batch surge. | Correct if the player links machine event to frontline signature. | Mark if answer is only "more units." |

Minimum record for each battle:

```text
player_id
battle_order
hidden_preset
answer_axis
answer_counter
answer_overdrive
answer_frontline_cause
confidence_axis_1_to_5
confidence_counter_1_to_5
confidence_overdrive_1_to_5
confidence_frontline_1_to_5
observer_notes
correct_count_0_to_4
unit_only_bias_flag
overdrive_panic_flag
```

Manual recording in a spreadsheet or local markdown sheet is acceptable. No backend, account system, or telemetry requirement belongs in this slice.

## Success Criteria

Use 3-5 target players from the primary audience:

- systems roguelite players,
- auto-battle optimizer players,
- optional casual physics players only if they can already tolerate visual systems.

After each battle, ask the four post-battle questions.

Hard success:

- At least 3/5 players answer at least 3 of the 4 questions correctly.
- At least 3/5 players can name a non-Unit axis as meaningful after seeing all three battles.
- At least 3/5 players can explain why `Launch` or `Tuning` changed the frontline without reducing the answer to "it made more units."
- At least 3/5 players can describe how one enemy counter disrupted a machine axis.

Diagnostic success:

- At least 3/5 players describe `Overdrive` as amplification of the current build direction.
- No more than 2/5 players describe `Overdrive` mainly as a panic or rescue button.

## Failure Looks Like

Hard failure:

- Fewer than 3/5 players answer at least 3 of the 4 post-battle questions correctly.
- Most players describe `Unit` as the only clear or valuable axis.
- Most players cannot tell `Launch Flood` and `Tuning Echo` apart from generic unit output.
- Players describe the battlefield as random activity rather than a result of machine choices.

Diagnostic failure:

- Most players save `Overdrive` for danger and cannot say what axis it amplified.
- Players notice the machine but cannot connect it to frontline pressure.
- Players can name UI labels but cannot explain the consequence.

If this slice fails, do not build the node-room slice yet. Fix feedback timing, visual hierarchy, axis identity, or the `Launch / Tuning / Unit` split first.

## Go / No-Go Decision

If this slice succeeds:

- move to a C+ mini node segment:
  - 3-5 battles,
  - 1 shop,
  - 1 event,
  - 1 elite,
  - 3 axes with real polarize / pivot / patch choices.

If this slice fails:

- do not add more content,
- do not start Itch sale validation,
- rework the battle read before building shops, events, relics, or race content.

## Build Time

3-7 development days after choosing a simple implementation stack.

Because this repo is currently docs-only, add 1-3 days if a fresh project scaffold is needed.

## Dependencies

- A new scoped implementation plan.
- A simple 2D runtime or prototype framework.
- Basic deterministic simulation.
- Basic mouse input.
- Playtest script and answer sheet.

No dependency on:

- old deleted Web MVP code,
- package scripts,
- generated assets,
- Steam integration,
- backend services,
- full race roster,
- full economy.

## Score

```text
Validation Value:            2/2
Tests the current highest-risk assumption: players must understand the axis-to-frontline chain, and Unit must not become the only meaningful axis.

Implementation Feasibility:  2/2
Small battle lab, three hardcoded presets, no shop, no event, no economy, no meta.

Player Signal Clarity:       2/2
The test produces direct answers: can players name the axis, counter, Overdrive target, and frontline cause?

Dependency Risk:             2/2
Only one prototype runtime and one battle screen are needed. All long-run systems are fakeable or absent.

Scope Discipline:            2/2
Removing any axis breaks the main test. Adding shop, event, relics, or races would make the signal less clean.

TOTAL:                      10/10
```

## Rejected Alternatives

- Onboarding Slice:
  - rejected because it mixes tutorial clarity with battle causality. If players fail, the team cannot tell whether the problem is teaching or the machine-to-frontline chain.
- Mini Node Segment:
  - rejected for now because it adds shop, event, elite, and route decisions before the battle read is proven.
- Vertical Slice:
  - rejected because it is production bait. It would test too many systems and hide the current risk under content volume.

## Completion Summary

```text
/prototype-slice-plan complete

Game: planB
Target risk: Unit dominance plus machine-to-frontline readability
Recommended slice: Mechanic Prototype - Three-Axis Readability Battle Lab
Score: 10/10
Build time: 3-7 development days, plus 1-3 days if fresh scaffold is needed

Status: DONE_WITH_CONCERNS

Next Step:
  PRIMARY: /implementation-handoff - slice defined, create build package
  IF VISUAL READABILITY REMAINS UNCLEAR: /plan-design-review - specify battle HUD and feedback rules before implementation
```

---

## Design Review Status

| Review | Date | Score | Status |
|--------|------|-------|--------|
| /plan-design-review | 2026-06-02 | 4.2/10 -> 7.4/10 | DONE_WITH_CONCERNS |

### Design Decisions Made

1. Added narrow battle-screen hierarchy for reading `Launch / Tuning / Unit`, counters, frontline result, and `Overdrive`.
2. Added axis-specific visual language using shape, motion, timing, and traces instead of color-only labels.
3. Added three frontline result signatures: smooth flow, stepped repeated impact, and grouped charge.
4. Added warning, active, and effect states for `Pool Polluter`, `Echo Breaker`, and `Stagger Punisher`.
5. Added `Overdrive` directionality rules so it reads as axis amplification, not a generic rescue.
6. Added post-battle question presentation and recording rules.

### Deferred to TODOS.md

None. This review did not create `TODOS.md` because the unresolved items are outside the requested narrow battle-lab readability scope.

### Unresolved

1. Full `docs/DESIGN.md` remains absent. This is acceptable for this narrow prototype, but not for production UI.
2. Exact visual art direction, palette, typography, and animation timing remain open until a full design-system pass.

### Outside Voices

Not available in this run. No separate read-only reviewer was launched.

### Next Review

Run `/implementation-handoff` only after accepting this readability spec as part of the slice. Run `/game-ux-review` after any prototype implementation exists.
