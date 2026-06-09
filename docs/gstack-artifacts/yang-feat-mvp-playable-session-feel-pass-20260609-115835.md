# PlanB MVP v0 Playable Session Feel Pass

- Reviewer: yang / Codex
- Branch: `feat/mvp-playable-session`
- Date: 2026-06-09 11:58:35 Asia/Shanghai
- Build target: `mvp/scenes/run/mvp_playable_session.tscn`
- Verdict: `DONE_WITH_CONCERNS`
- Score: 8 / 14, `FLAT`

## Scope

This pass evaluates the first player-facing playable MVP session, not the M1/M2/M3 debug harnesses.

Observed path:

1. Opened the playable session scene.
2. Observed Guardian selection, machine panel, battlefield panel, flow list, event log, and result placeholder.
3. Triggered Guardian selection through the running Godot window.
4. Observed Battle 1 resolve into the first reward choice state.
5. Ran automated session verification to result page.

Verification command:

```bash
./mvp/tools/verify_godot.sh
```

Result: passed. M0/M1/M2/M3 and playable session verification all passed.

Godot / GoPeak checks:

- `mvp/scenes/run/mvp_playable_session.tscn` launched successfully.
- `mvp/scripts/run/mvp_playable_session.gd` and `mvp/tools/verify_playable_session.gd` had no LSP diagnostics.
- Runtime produced no GDScript errors during the observed playable session launch.

Limit: this is not a full human playtest. It is a first feel pass based on one live interaction path, screenshots, code timing, and automated full-session verification.

## Target Feel

Source intent from implementation handoff and first gate:

- Core promise: machine-to-frontline readability.
- Player should see the causal chain from ball machine output to deployed battlefield unit.
- Deploy Lane should feel direct: click lane, highlighted lane changes, next deploy goes there.
- Short run should feel like one continuous playable session, not a disconnected debug menu.

Target vocabulary:

- `Readable`
- `Responsive`
- `Flowing`
- `Chunky` only at reward/result beats

## Score

| Channel | Score | Reason |
| --- | ---: | --- |
| Responsiveness | 2 / 2 | Guardian and lane callbacks update state directly. No intentional input delay was found. |
| Clarity | 1 / 2 | Main systems are visible, but debug title/text, dense panels, scrollbars, and a phase label mismatch weaken first-glance understanding. |
| Impact | 1 / 2 | Visual feedback exists, but there is no audio, shake, transition hit, or strong reward arrival. |
| Rhythm | 1 / 2 | The loop reaches choice beats, but combat is compressed and fixed-cadence. It risks becoming monotonous across five battles. |
| Payoff | 1 / 2 | Gold/reward/result facts appear, but the delivery is flat and text-led. |
| Dead Time | 1 / 2 | The player is rarely staring at a blank screen, but battle agency is thin after lane selection. |
| Overload | 1 / 2 | Not VFX-overloaded, but the UI is text-heavy and partially obscured by scroll/clipping at desktop window size. |

Total: 8 / 14.

## Observations

### 1. Responsiveness

Guardian selection is code-path responsive. `_on_guardian_choice()` immediately applies Guardian state and calls `_start_battle(1)`. Lane selection is also direct through `_on_lane_clicked()`, which immediately updates `_deploy_lane`, battlefield view state, and status copy.

Measured channel:

- Input: mouse click on Guardian button.
- Visual: screen entered the first battle flow and later first reward state.
- Timing: callback path is same frame / next draw. The observed screenshot was not frame-instrumented, so exact ms should be treated as unmeasured.

Feel: `Responsive`.

Concern: macOS Accessibility coordinate clicks were unreliable during this pass. That appears external to the game window, not a Godot input bug.

### 2. Machine-To-Frontline Readability

The player-facing screen now shows machine and battlefield together from the first real session screen. This is directionally correct for the MVP promise.

Positive signals:

- The ball machine is visible beside the battlefield during battle.
- Active ball and trail are visible.
- Lane highlight is visible.
- Event log records Guardian selection, battle start, and battle result.
- Queue and machine state exist in the same scene, not in a separate debug-only view.

Weak signals:

- The machine area is cramped at current desktop window size.
- Scrollbars appear in the main layout.
- Unit slots and lower machine content can be clipped.
- The bottom result placeholder competes with active play information.

Feel: `Readable` but `Obscured`.

### 3. Battle Rhythm

The script defines `BATTLE_DURATION_SECONDS := 9.0` and `SIMULATION_SPEED := 2.6`. That means a displayed 9.0-second battle resolves in roughly 3.5 seconds of wall-clock time.

Effect:

- The session moves quickly enough to prove the loop.
- The combat beat feels compressed rather than played.
- Repeating five battles with the same fixed cadence will likely feel `Monotonous` unless player decisions or pressure variation become more legible.

Feel: `Staccato`.

### 4. Reward And Result Payoff

After Battle 1, the reward choice appears and Gold updates. This closes the loop mechanically.

Weakness:

- Reward arrival is mostly a text/state change.
- There is no audio sting, transition beat, animation, or obvious "you earned this" moment.
- The status line can still say the previous step while the choice panel shows the new step, which creates a small clarity break.

Feel: `Light`, close to `Flat`.

### 5. Audio / Feedback Chain

No meaningful audio channel was observed in the playable session.

This is the largest feel gap because the whole game depends on repeated causal beats:

1. ball launched
2. tuning result
3. unit formed
4. lane deploy
5. unit clash
6. battle result
7. reward pickup

Right now those beats are mostly visual/text. The feedback chain is present, but not alive enough.

Feel: `Hollow`.

## Top Fixes Before Next Feel Pass

1. Add minimal audio for the core chain.
   Required beats: launch, tuning hit, unit created, deploy, lane danger, victory, reward picked, endpoint/result.

2. Fix battle-to-choice clarity.
   The displayed phase/status should not disagree after battle completion. Add a short transition beat when reward/shop/counter states appear.

3. Remove player-facing debug framing.
   The playable session window and first screen should not say `(DEBUG)` or feel like a harness. Keep debug scenes separate.

4. Make machine-to-frontline readable at one glance.
   Avoid clipped Unit slots and visible scrollbars in the default desktop window. The active ball, queue head, deploy lane, and active battlefield lane need to be visible without scrolling.

5. Vary the five-battle rhythm.
   The current fixed accelerated combat is enough for verification, but not enough for feel. Add pressure changes or visible enemy intent between battles before calling this playtest-ready.

## Verdict

The MVP session is now mechanically complete enough to evaluate. It is not yet feel-complete.

The current build answers "can a full MVP v0 session run?" with yes. It does not yet answer "does the machine-to-frontline loop feel good?" with yes.

Next recommended task: a small `playable-session-feel-fixes` branch focused only on audio cues, phase clarity, layout clipping, and one-glance machine-to-frontline readability. Do not expand scope into balance, new Guardians, new units, new enemies, or final art.
