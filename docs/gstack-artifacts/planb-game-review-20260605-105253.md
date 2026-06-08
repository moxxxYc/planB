# Game Review - planB (2026-06-05)

Supersedes: N/A

Mode: B) PC / Console
GDD: `docs/gdd.md`
Branch: `mvp`
Review path: Interactive through Section 2, then fast-forward AUTO-only for Sections 3-6.

## Context Anchors

| Anchor | Status | Found |
|---|---:|---|
| Genre & Platform | established | Ball-machine-driven auto-battle roguelite, PC / desktop first. |
| Target Session Length | established | Formal run 45-60 minutes, MVP 15-20 minutes. |
| Monetization Model | established | Premium buy-to-play, possible DLC, no current F2P / IAP design. |
| Target Audience | established | System-build roguelite players, Castle Fight-style auto-spawn lane push players, machine-feedback players. Not RTS micro, PVP ranking, high-action, pure physics-score, or service-game players. |
| Design Pillars | established | Ball machine as main system, run identity from `Launch / Tuning / Unit`, strengthen / pivot / patch, battle input is `Deploy Lane`, support systems must express machine axes, readability before content volume. |

## Running Decisions Captured

- Section 1 premise: the 30-second micro-loop is partially self-supporting. Raw observation and lane choice have value, but full drive depends on rewards, shop, counters, and endpoint battle.
- Section 1 mastery answer: on the 100th repetition, the player should anticipate machine axis, counter window, next output lane, when to patch, and when to abandon a lane.
- Second-opinion challenge: `Deploy Lane` can steal attention from the ball machine if the best short-term behavior becomes "click the dangerous lane."
- Designer response: `Deploy Lane` is only a light tactical decision. It changes deployment location, not unit strength, unit count, machine speed, or build quality. If ball-machine construction is weak, correct lane choice is not enough, and three lanes can all become dangerous.
- Section 1 retained score: 8/10, with validation condition that danger-following alone must not reliably win the MVP.
- Section 2 D1 hook: primary hook is trying another machine axis next run. Same-axis mastery and future content unlocks are secondary.
- Section 2 top churn point: first or second battle where the player cannot see how a machine axis changed the battlefield.

## Section Scores

### Section 1 - Core Loop: 8/10

Breakdown:

- Clarity: 2/2. The loop can be stated cleanly: observe machine and battlefield signals -> judge machine axis -> strengthen / pivot / patch -> choose `Deploy Lane` -> read battlefield result.
- Session Fit: 2/2. MVP and formal run lengths both have clear closure.
- Depth: 2/2. Repetition can produce mastery through axis reading, counter-window reading, lane commitment, and patch timing.
- Fail State: 1/2. Win/loss rules are clear, but the 5 seconds after failure and the correction lesson are underwritten.
- Uniqueness: 2/2. "Tune a ball machine so machine-axis commitment becomes three-lane frontline advantage" passes the one-sentence test.

Main concern:

- The 30-second micro-loop is not yet proven. The MVP must show that watching danger prompts and clicking lanes is not enough to win.

### Section 2 - Progression & Retention: 6/10

Breakdown:

- FTUE Quality: 1/2. There is a first battle and minimal tutorial scope, but no first meaningful action timing target.
- Retention Hooks: 2/3. D1 is readable: try another machine axis. D7 and D30 are plausible through same-axis mastery and future content, but not yet written as concrete hooks.
- Difficulty Curve: 2/2. The MVP sequence supports expose -> stress -> validate through tutorial, reward, counter, shop, second counter, endpoint.
- Churn Point Analysis: 1/3. The top churn point is named, but mitigation needs battle-by-battle learning checkpoints.

Needed checkpoint structure:

- Battle 1: player can explain `Gate / Prime / Echo / Surge` and Unit progress.
- Battle 2: player can name the current axis read: sustained flow, repeated heavy hit, or batch charge.
- Battle 3: player can say which component the counter attacked: Pool, Echo, or Queue gap.
- Endpoint: player can explain whether loss came from weak build, poor patching, wrong lane commitment, or failed counter handling.

### Section 3 - Economy & Monetization: 8/10

Breakdown:

- Currency Clarity: 2/2. `Gold / 金币` is the visible currency. The GDD rejects battle-time Gold slots and broad currency sprawl.
- Sink/Faucet Balance: 2/3. Faucets and sinks are named: post-battle Gold, shop inventory, same-column price increases, repair. There is no earn-rate, cost curve, or equilibrium map.
- Monetization Ethics: 3/3. Premium buy-to-play, possible DLC, no PVP, no current IAP, no F2P pressure.
- Spending Tier Health: 1/2. The design avoids whale dependency by not using F2P tiers. DLC value boundaries are not specified.

Main concern:

- The economy has the right boundaries but no math. A 15-20 minute MVP still needs rough Gold per battle, shop price bands, repair cost, and the expected number of purchases per run.

### Section 4 - Player Motivation & Emotion: 7/10

Breakdown:

- SDT Coverage: 2/3. Autonomy is served by axis commitment and strengthen / pivot / patch. Competence is served by reading machine causality and counters. Relatedness is weak in the MVP because there is no social layer, world bond, or strong identity object yet.
- Player Type Targeting: 3/3. Target and non-target player types are explicitly named.
- Ludonarrative Consonance: 2/2. The machine-tuning fantasy matches the mechanics. Guardian, race, shop, and enemies are constrained to serve the machine.
- Emotional Arc: 2/2 at concept level, but close to 1/2 in production readiness. The intended arc is readable: understand signal -> commit -> watch battlefield change -> face counter -> patch or double down. It is not yet timed per battle.

Main concern:

- Player identity currently depends on abstract machine axes. Before production, at least the first race, two Guardians, and three build names need enough identity that a player can describe "my run" without reading component names.

### Section 5 - Risk Assessment: 8/10

Breakdown:

- Risk Identification: 2/3. The GDD names major risks: machine unreadability, `Deploy Lane` dominance, `Unit` dominance, Guardian drift, hidden Tuning math, Gold buy-through, scope growth. It does not use probability / impact ratings.
- Mitigation Specificity: 2/3. Most mitigations point the right way, but some are still policy statements rather than validation gates.
- Pillar Coherence: 2/2. The hard boundaries protect the ball-machine pillar.
- Scope Realism: 2/2. MVP scope is Lake-sized: 1 race, 3 build directions, up to 9 effects, 3 counter families, 1 endpoint battle, no meta progression.

Main concern:

- Risk handling is mature at the document-boundary level, but not testable enough. High risks need pass/fail metrics, not only design rules.

### Section 6 - Cross-Consistency: 7/10

Breakdown:

- Internal Consistency: 3/4. The docs are mostly aligned. The biggest tension is that `Deploy Lane` is intentionally simple and readable, which can compete with the harder-to-read machine causality.
- Pillar Traceability: 3/3. Major systems trace back to `Launch / Tuning / Unit` and Machine Contract.
- System Coherence: 2/3. Systems reinforce each other on paper, but first-race units, Guardian skills, and the 9 reward / shop effects are still missing. Those are the first places coherence can break.

Design Consistency:

- Voice: MINOR DRIFT, 1 violation found. `Deploy Lane` danger signaling may sound more actionable than the machine itself.
- Boundaries: 3/5 boundaries tested. Zero-state and overflow-state are partially handled through Pool, Gate, and lane-danger limits. Player defiance is partially tested by "danger-clicking should not be enough." UI overflow and repeated-run edge cases are not defined.
- Storytelling: Sparse, 1/4 channels active. Mechanical identity is clear. Visual, audio, animation, and UI identity are not specified yet.
- Worst violation: `Deploy Lane` danger hints can contradict "ball machine is main system" if following lane danger creates better outcomes than understanding `Launch / Tuning / Unit`.

## GDD Health Score

GDD Health Score (Mode: B, PC / Console)
═══════════════════════════════════════════════

| Section | Score | Weight | Weighted |
|---|---:|---:|---:|
| Section 1 - Core Loop | 8/10 | 30% | 2.40 |
| Section 2 - Progression | 6/10 | 20% | 1.20 |
| Section 3 - Economy | 8/10 | 10% | 0.80 |
| Section 4 - Player Motivation | 7/10 | 15% | 1.05 |
| Section 5 - Risk Assessment | 8/10 | 10% | 0.80 |
| Section 6 - Cross-Consistency | 7/10 | 15% | 1.05 |

WEIGHTED TOTAL: 7.5/10

Interpretation: SOLID. This is a usable design foundation for continued design planning. It is not ready for production handoff until the learning checkpoints, first neutral modifiers, first race identity, and validation metrics are written.

Top 3 Deductions:

1. Section 2, Churn Mitigation: -2 because the MVP does not yet state what the player must learn after each battle.
2. Section 6, Cross-Consistency: -1 because `Deploy Lane` danger feedback can become more readable than machine causality.
3. Section 3, Sink/Faucet Balance: -1 because Gold sources, costs, repair, and expected purchase count are not mapped.

## Playtest Protocol

### Key Moments To Watch

- FTUE first 60 seconds: Does the player identify what the machine is doing before reading explanation text?
- First meaningful action: How long until the player makes a real choice, not just watches?
- Battle 1 result: Can the player explain a normal Gate result and one bonus Tuning result?
- First reward: Does the player choose by machine component or by generic "stronger" language?
- Battle 2 midpoint: Does the player look at machine output or only lane danger?
- First counter warning: Does the player notice where the counter appears, Pool / Echo / Queue gap?
- First counter resolution: Can the player explain what was disrupted?
- First shop: Does the player buy to strengthen, pivot, or patch, or just pick the biggest number?
- Endpoint loss or win: Can the player state the primary cause without being told?
- Session end: Does the player name a next-run axis they want to try?

### Post-Session Questions

1. Which machine axis did you mainly build around: `Launch`, `Tuning`, or `Unit`?
2. Name one reward or shop choice. What machine component did it change?
3. Which lane choice mattered most, and why was lane choice not enough by itself?
4. What did the enemy counter attack?
5. Did you win or lose because of build quality, patching, lane commitment, or counter handling?
6. If you played again tomorrow, what would you try differently?

### Metrics To Track

- Time to first meaningful action.
- Time spent looking at machine UI vs battlefield lanes.
- Number of route changes per battle.
- Percentage of route changes that follow danger prompts only.
- Percentage of players who name the correct main machine axis after Battle 2.
- Percentage of players who identify the counter target after Battle 3.
- Gold earned per battle.
- Shop purchases per run.
- Repair purchases per run.
- Endpoint win/loss reason accuracy.
- Session length.
- Quit point and last visible event before quit.
- D1 return intent: same axis mastery, different axis test, content unlock, or no stated reason.

### Red Flag Behaviors

- Confusion pause longer than 5 seconds after a Tuning result.
- Player repeatedly clicks lanes expecting immediate spawning.
- Player describes all outputs as "more units."
- Player follows danger hints and ignores machine output.
- Player cannot tell Pool pollution from generic enemy pressure.
- Player buys a shop effect without knowing its target component.
- Player loses endpoint and says "I don't know why."
- Player wins while unable to name a machine axis.
- Player says the best plan is always Unit.
- Player says the best plan is always click the most dangerous lane.

## Not In Scope

- Archived prototype: deferred because it is fully expired and not current design evidence. Revisit only for explicit historical archaeology.
- Code review or implementation plan: deferred because the repo is docs-only. Revisit after a new scoped implementation plan exists.
- Detailed balance math: deferred because first neutral modifiers, exact shop inventory, and first race units are missing. Revisit with `/balance-review` after those are written.
- Specific Hive content: deferred because current docs intentionally stop before first-race design. Revisit after foundation checkpoints are added.
- Visual UI style and audio language: deferred because current GDD focuses on rules and causality. Revisit in `/plan-design-review` or `/game-ux-review`.

## Failure Modes

- Machine unreadability: Fails when players see movement but cannot map it to `Launch / Tuning / Unit`. Player reaction: "stuff happened." Mitigation: battle-by-battle learning checkpoints and result-page causal recap.
- Danger-click dominance: Fails when players win by clicking the most dangerous lane without understanding the machine. Player reaction: treats the game as lane whack-a-mole. Mitigation: make weak builds fail even with correct lane choice, and track danger-following-only wins.
- Random-feeling counters: Fails when `Pool Polluter`, `Echo Breaker`, or `Stagger Punisher` lacks clear prewarning and aftermath. Player reaction: "the game randomly broke my build." Mitigation: component-local warning, visible disruption, and post-battle counter explanation.
- Pure-number shop: Fails when rewards and shop effects read as generic output upgrades. Player reaction: optimizes largest number, ignores axis identity. Mitigation: every effect uses `warehouse -> component -> operation -> player read -> failure risk`.
- Unit dominance: Fails when batching always beats sustained flow and repeated hit. Player reaction: always pick Unit. Mitigation: enemy counters and rewards must test Launch and Tuning as independent solutions.
- Guardian drift: Fails when Guardian clears leaks or defines the build better than the machine. Player reaction: chooses Guardian, ignores machine commitments. Mitigation: Guardian tactical skill cannot solve sustained lane pressure, strategic skill must be soft axis lean.
- Gold buy-through: Fails when a player can buy through every axis and erase commitment. Player reaction: shop becomes the run. Mitigation: limited inventory, same-column price increase, repair as HP recovery only, not max-HP growth.
- Endpoint opacity: Fails when endpoint loss cannot be traced. Player reaction: no next-run hypothesis. Mitigation: endpoint recap tags build weakness, patch failure, lane error, or counter failure.

## Completion Summary

```text
/game-review Completion Summary
═══════════════════════════════════
Mode: B | GDD: docs/gdd.md | Branch: mvp
Status: DONE_WITH_CONCERNS

  S0 Context:        established
  S1 Core Loop:      8/10  (Deploy Lane premise challenged, retained with validation condition)
  S2 Progression:    6/10  (D1 hook found, battle learning checkpoints deferred)
  S3 Economy:        8/10  (boundaries strong, Gold math deferred)
  S4 Motivation:     7/10  (target player clear, run identity needs first race / Guardian names)
  S5 Risk:           8/10  (risks identified, validation metrics incomplete)
  S6 Consistency:    7/10  (one high-impact tension: Deploy Lane readability vs machine primacy)
  WEIGHTED TOTAL:    7.5/10

Next Step:
  PRIMARY: /plan-design-review - define MVP learning checkpoints and UI/feedback proof before build planning
  (if first neutral modifiers are written): /balance-review - test Gold, shop, and modifier economy
  (if moving toward implementation): /prototype-slice-plan - scope the first build only after checkpoints and modifier list exist
```
