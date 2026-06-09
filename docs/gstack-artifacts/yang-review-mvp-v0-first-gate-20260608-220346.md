# PlanB MVP v0 First Gate Review

Branch: `review/mvp-v0-first-gate`  
Implementation head reviewed: `17a7a60 fix: translate m3 debug telemetry display`  
Base M3: `2de2648 feat: add mvp m3 complete session`  
Review scope: M0-M3 current Godot implementation only. No M4, no new systems, no balance/polish pass.

## Gate Conclusion

`PASS_WITH_FIXES`

M0-M3 reaches a complete debug short-run session with Win and Loss results. The core handoff intent survives at debug-MVP level: machine output creates queue entries, queue entries deploy into live battlefield lanes, counters target machine/battle components, Endpoint resolves, and result page uses current run data.

This is not external playtest-ready yet. The session is still a scripted debug run, not a natural player-run loop.

## Fixes Applied

- `3907faf fix: localize mvp debug ui and scale window`
  - Localized debug UI/resource-facing text.
  - Set project window to `1600x900`, maximized, resizable, and canvas stretch expand.
- `17a7a60 fix: translate m3 debug telemetry display`
  - Translates nested M3 result/telemetry display keys and internal IDs into Chinese in the debug UI.
  - Keeps model schemas and verifier-facing enum values unchanged.

## Verification Evidence

- `./mvp/tools/verify_godot.sh`
  - Passed M0 project skeleton, M1 machine causality, M2 battlefield deploy loop, M3 complete session.
- GoPeak `editor_run`
  - Ran `res://scenes/run/mvp_session_debug.tscn`.
  - No GDScript errors. Runtime output only had macOS IMK input-method messages.
- GoPeak LSP diagnostics
  - No diagnostics for changed/debug scripts.
- Temporary Win/Loss headless session check
  - Win: `巢脉母`, main axis `发射`, counter `池污染者`, endpoint outcome `win`.
  - Loss: `酸冠母`, main axis `调校`, counter `复写破坏者`, endpoint outcome `loss`.
  - Both sessions reached result page with required result fields.

## Implementation Review

### Blocker

None.

### Major

1. The debug session closes, but the player session is still scripted and force-resolved.

Evidence:
- `mvp/scripts/run/mvp_session_model.gd:141` and `mvp/scripts/run/mvp_session_model.gd:157` run the full Win/Loss session through fixed function calls.
- `mvp/scripts/run/mvp_session_model.gd:195` through `mvp/scripts/run/mvp_session_model.gd:202` ticks battle pressure briefly, then forces every non-endpoint battle to `player_win`.
- `mvp/scripts/run/mvp_session_model.gd:349` through `mvp/scripts/run/mvp_session_model.gd:367` resolves Endpoint from a debug boolean rather than a naturally won/lost battlefield state.

Impact:
The short-run structure is proven, but first-time player readability is not proven. A stranger can see the run data, but cannot yet prove they understand the loop through normal play decisions.

2. Machine-to-frontline readability exists as real model data, but not yet as a naturally played machine cadence.

Evidence:
- `mvp/scripts/ball_machine/machine_causality_model.gd:433` through `mvp/scripts/ball_machine/machine_causality_model.gd:440` creates structured queue entries with slot, tuning, delay, and `Launch->Tuning->Unit->Queue` trigger chain.
- `mvp/scripts/battlefield/battlefield_deploy_model.gd:104` through `mvp/scripts/battlefield/battlefield_deploy_model.gd:124` rejects entries without the M1 trigger chain and logs queue preview into the selected lane.
- `mvp/scripts/battlefield/battlefield_deploy_model.gd:137` through `mvp/scripts/battlefield/battlefield_deploy_model.gd:157` deploys the queue head into the currently selected lane.

Impact:
This is not static text. The machine output drives battlefield units. The risk is that the current proof is debug-forced, so it does not yet validate the feel of a player watching repeated physical/visual machine events build frontline pressure.

3. Result page uses real current-run data, but Endpoint payoff/break reason is inferred from axis/counter.

Evidence:
- `mvp/scripts/run/mvp_session_model.gd:448` through `mvp/scripts/run/mvp_session_model.gd:480` builds result fields from selected guardian, axis, rewards, shop/rest, latest counter, deploy lane records, endpoint telemetry, and unit contribution data.
- `mvp/scripts/run/mvp_session_model.gd:867` through `mvp/scripts/run/mvp_session_model.gd:885` generates Endpoint payoff/break reason by axis and counter target.

Impact:
The result page is not static fake copy. The remaining risk is player trust: the page explains the run, but some Endpoint causality is summarized by scripted inference instead of measured battlefield causality.

### Minor

1. Permanent M3 verifier checks Win path and all counter cases, while Loss was verified manually in this gate.

Evidence:
- `mvp/tools/verify_mvp_session.gd:78` through `mvp/tools/verify_mvp_session.gd:102` runs `run_debug_win_session`.
- `mvp/tools/verify_mvp_session.gd:129` through `mvp/tools/verify_mvp_session.gd:146` checks all three counter families for `warning`, `target_component`, `visible_effect`, and `log_record`.

Impact:
This gate ran Loss once successfully, but future automated regressions would not catch Loss-only result-page breaks unless Loss is added to the permanent verifier.

2. Root docs still contain stale "pure document state" language.

Impact:
This did not block Godot validation, but it can misroute future agents if they trust root docs over the current implementation and branch state.

## Design Intent Checks

| Requirement | Gate Result | Evidence |
| --- | --- | --- |
| Guardian select before Battle 1 | Pass | Win/Loss session starts with `start_new_run`, then fixed Guardian persists through result page. |
| Full M3 flow | Pass | `run_debug_win_session` and `run_debug_loss_session` traverse Guardian Select through Result Page. |
| Machine-to-frontline causality | Pass with concern | M1 queue entries are real and M2 deploys them; cadence is debug-forced. |
| Deploy Lane future-only | Pass | `mvp/scripts/run/mvp_session_model.gd:648` through `mvp/scripts/run/mvp_session_model.gd:663` records future-only impact; M2 verifier also checks existing deployed units remain on original lane. |
| Counters | Pass | `mvp/scripts/run/mvp_session_model.gd:402` through `mvp/scripts/run/mvp_session_model.gd:430`; verifier covers all three families. |
| Endpoint | Pass with concern | Endpoint warning and Win/Loss result exist; final outcome is debug-forced. |
| Result page real data | Pass with concern | Result page fields come from run state; payoff/break explanation is inferred. |

## Build Playability Score

Score: `8/12`, verdict `ALMOST`.

- Loop Closure: `2/2`. Action -> reward -> shop/rest -> second reward -> endpoint -> result page closes.
- Session Viability: `1/2`. Session can be completed, but not as 5+ minutes of natural play.
- Onboarding Clarity: `1/2`. Debug controls are readable, but a new player still depends on debug buttons and labels.
- Failure Recovery: `2/2`. Loss result page is immediate, records break reason and next-run watch tag.
- Retention Signal: `1/2`. `next_run_watch_tag` exists, but one-more-try pull is not proven through play.
- Peak Moment: `1/2`. Counter warning and Endpoint Sweep exist, but tension is mostly narrated by debug flow.

Top blocker to `PLAY-READY`: replace forced debug resolution with a short natural run where player choices can actually produce Win/Loss through the battlefield state.

## Next Step

Do not add M4. The next useful step is a tiny external playtest of this exact M3 debug build: one person runs Win and Loss, then explains main axis, key reward, counter target, Deploy Lane impact, and Endpoint success/failure reason. If they cannot explain those without reading docs, improve M3 readability before adding content.
