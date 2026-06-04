# Prototype Slice Plan: Closed-Loop MVP

Game: planB
GDD Status: Reviewed. Current GDD supports a gameplay validation slice with 1 race, 3 machine axes, 1 shop, 3 counters, and 1 endpoint.
Branch: codex/three-axis-readability-battle-lab
Date: 2026-06-03
Supersedes: `docs/gstack-artifacts/yang-mvp-slice-plan-20260602-215006.md`
Status: DONE_WITH_CONCERNS

## Key Risk

The previous Battle Lab direction tested whether players can read the three axes in isolation. That is now too narrow for the current production goal.

New #1 risk:

> Can a 15-20 minute run close the full session loop, while still making machine-axis commitment read as the reason the frontline changes?

The MVP fails if it becomes a generic auto-battler where the best answer is "buy more Unit output" or "buy generic stats."

## Recommended Slice

Vertical Skeleton: Hive Closed-Loop MVP

This is not a polished vertical slice, not an Itch demo, and not a launch-scope build. It is a low-polish complete run skeleton with enough real content to answer whether planB is a game loop, not only a readability lab.

## Hypothesis To Validate

> A player can finish one 15-20 minute Hive run, make at least two machine-axis commitment decisions, face a counter that pressures that commitment, use `Overdrive` as axis amplification, and finish an endpoint while understanding whether the run was `Brood Flow`, `Infection Echo`, or `Nest Surge`.

If the player only describes the run as "more units" or "stronger units," the slice fails.

## What To Build

- One formal first race: `Hive`.
- One short run:
  - 6 battles by default,
  - 8 battles maximum,
  - 15-20 minute target duration.
- One simple run flow:
  - FTUE battle,
  - first reward choice,
  - battle 2 validates the chosen axis,
  - shop,
  - counter battle,
  - second reward or shop reinforcement,
  - endpoint battle,
  - win / lose result.
- Three Hive build paths:
  - `Brood Flow`: Hive rewrite of `Launch Flood`.
  - `Infection Echo`: Hive rewrite of `Tuning Echo`.
  - `Nest Surge`: Hive rewrite of `Unit Queue Burst`.
- Three minimal Hive unit or pressure expressions:
  - small replenishing bodies for `Brood Flow`,
  - infection marks or spread pulses for `Infection Echo`,
  - grouped nest release for `Nest Surge`.
- Up to 9 total reward / shop effects:
  - 2-3 effects per build path,
  - every effect must name its machine axis and component.
- One shop template:
  - `Launch / Tuning / Unit` columns,
  - limited stock,
  - no generic raw stat purchases.
- Three counter families:
  - `Pool Polluter`,
  - `Echo Breaker`,
  - `Stagger Punisher`.
- One endpoint:
  - endpoint pressure must test the current machine axis,
  - endpoint cannot be only a high-HP enemy.
- One basic result screen:
  - shows chosen Hive path,
  - strongest machine pressure window,
  - counter that pressured it,
  - endpoint outcome.

## What To Fake

- Art:
  - use primitives, simple silhouettes, and clear motion traces.
  - Hive needs identity, but not production art.
- Audio:
  - placeholder beeps or silence are acceptable for this slice.
- Map:
  - no full node map required. A fixed sequence or simple linear route is enough.
- Enemy roster:
  - enemies can be named pressure scripts. Do not build a full enemy table.
- Economy:
  - use fixed Gold rewards and hand-tuned prices.
  - no long-run economy simulation.
- Events:
  - no event pool. If needed, use one scripted mutation as part of a build path.
- Meta progression:
  - no unlocks, no challenge tiers, no save progression.
- UI polish:
  - readable prototype UI only.

## What Not To Fake

- The complete session loop:
  - battle -> reward -> shop -> battle -> counter -> endpoint -> result must work end to end.
- Hive identity:
  - the run must look like a Hive run, not neutral test units with a label.
- Machine-axis commitment:
  - rewards and shop items must change `Launch / Tuning / Unit` machine behavior, not generic output.
- Three Hive path reads:
  - `Brood Flow` must read as replenishment flow,
  - `Infection Echo` must read as repeat / spread from an Echo behavior,
  - `Nest Surge` must read as charge and grouped release.
- Counter pressure:
  - counters must attack Pool, Echo window, or charge gap.
- `Overdrive`:
  - must amplify the current path and must not read as shield, heal, clear-screen, or panic button.
- Endpoint test:
  - the endpoint must expose whether the chosen machine axis converts into frontline pressure.

## Success Criteria

- One full run reaches win or loss in 15-20 minutes.
- By battle 2, the player can identify which Hive path they are pursuing.
- After the first shop, the player can name which machine component they invested in.
- During the counter battle, the player can identify what component was attacked:
  - Pool,
  - Echo window,
  - or charge gap.
- During `Overdrive`, the player can identify which path was amplified.
- After endpoint, the player can answer:
  - "My run was mainly `Brood Flow / Infection Echo / Nest Surge`."
  - "The endpoint tested it by doing X."
  - "I won or lost because the machine axis did or did not convert into frontline pressure."
- The best observed strategy is not "buy every strong-looking thing."
- The best observed strategy is not "always buy Unit."

Solo-developer gate for this iteration:

- Run the full MVP yourself twice:
  - one intended `Brood Flow` run,
  - one intended non-Launch run.
- Write the four post-run answers before reading debug logs:
  - Which Hive path was this?
  - Which machine component did I invest in?
  - Which counter pressured it?
  - Why did the endpoint move or stall the frontline?
- If either answer set depends on labels or memory of implementation instead of visible play, the slice is not ready to expand.

## Failure Looks Like

- Battle 2 failure:
  - You took the first Hive reward, but the next battle does not show what changed in the machine. The only visible read is "more units."
- First shop failure:
  - The obvious best choice is generic strength or cross-axis buying, not continuing `Brood Flow / Infection Echo / Nest Surge`.
- First counter failure:
  - `Pool Polluter / Echo Breaker / Stagger Punisher` feels like random punishment or generic enemy pressure, not a test of the current build's weak point.
- Endpoint failure:
  - After the endpoint, you cannot say which machine axis was amplified or suppressed.
- Path identity failure:
  - All three Hive paths feel like different speeds of spawning small units.
- MVP shape failure:
  - The run requires adding a second race, meta unlocks, a full event pool, or a large enemy roster to feel understandable.

## Build Time

Target build time:

- Human solo estimate: 2-4 weeks.
- Coding-agent split estimate: 3-5 focused implementation packages, assuming tight scope and no production art.

This estimate only holds if the content limits are enforced:

- 1 race,
- 6 battles default,
- 8 battles maximum,
- 9 reward / shop effects maximum,
- 3 counters,
- 1 endpoint,
- no meta,
- no second race,
- no full relic or event pool.

## Dependencies

- Existing Godot prototype can be reused only as raw implementation material, not as direction truth.
- Current formal design source remains `docs/gdd.md`.
- Prior Battle Lab artifacts are superseded for build target, but their readability warnings remain useful:
  - avoid four-panel dashboard layout,
  - avoid label-only causality,
  - avoid global panic `Overdrive`,
  - avoid Unit-dominant feedback.

## Score

```text
Score:
  Validation Value:             2/2
    Tests whether the full 15-20 minute run loop works and whether machine-axis commitment survives the loop.

  Implementation Feasibility:   1/2
    Buildable, but 6 battles, shop, rewards, counters, endpoint, and race identity are a 2-4 week solo scope.

  Player Signal Clarity:        2/2
    The signal is clear: finish a run and explain path, counter, Overdrive, and endpoint causality.

  Dependency Risk:              1/2
    Requires several systems, but all can be hardcoded or heavily faked except the session loop and machine-axis read.

  Scope Discipline:             1/2
    Valid for the user's new goal, but near the upper limit for a prototype. Content caps are mandatory.

  TOTAL:                        7/10
```

Verdict:

> Buildable with concerns. This is the right slice only if the goal is now "quick complete MVP." It is not the cheapest readability test.

## Rejected Alternatives

- Mechanic Prototype: Three-Axis Battle Lab
  - Rejected because it no longer answers the user's current question. It tests axis readability, not whether the game closes as a run.
- Three-Battle Progression Slice
  - Rejected because it is faster but still too close to a partial test. It cannot reveal whether shop, counter, `Overdrive`, and endpoint form a real session loop.
- Itch Micro Demo
  - Rejected because it needs too much content too early: 2 races, broader shop / relic / enemy pools, events, and more UI polish. That is a sale-validation step, not the next MVP step.

## Decisions From Forcing Questions

If this slice succeeds:

- Stop treating Battle Lab as the main next build.
- Continue expanding the first-race closed loop.
- Add second race or broader content only after Hive's loop proves machine-axis commitment, counter pressure, `Overdrive`, and endpoint validation.

If this slice fails:

- Do not add content.
- Return to machine expression, reward structure, shop commitment, or endpoint pressure depending on the observed failure point.

Shortcut bans:

- No generic `+damage` / `+HP` rewards as core build identity.
- No Hive path where all three builds read as "more small units."
- No shop that lets the player buy across all axes freely.
- No counter that only pressures HP or enemy count.
- No endpoint that is only a high-HP boss.

## Completion Summary

```text
/prototype-slice-plan complete

Game: planB
Target risk: whether a 15-20 minute closed-loop run works while preserving machine-to-frontline identity
Recommended slice: Vertical Skeleton - Hive Closed-Loop MVP
Score: 7/10
Build time: 2-4 weeks solo, or 3-5 focused implementation packages

Status: DONE_WITH_CONCERNS

Next Step:
  PRIMARY: /implementation-handoff - slice defined, create a build package for the Hive Closed-Loop MVP
  AFTER BUILD EXISTS: /build-playability-review - check whether the complete run is worth replaying
  IF FEEL IS MUDDY: /feel-pass - isolate machine, Overdrive, and counter feedback failures
```
