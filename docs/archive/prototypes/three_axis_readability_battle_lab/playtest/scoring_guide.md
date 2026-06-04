# Battle Lab Scoring Guide

Score after responses are recorded. Do not reveal the answer key before capture.

## Axis Question

Correct if:

- selected axis matches the hidden preset,
- the player text does not reduce the answer to generic unit output.

Expected axis by preset:

| Hidden preset | Correct axis |
|---|---|
| `launch_flood` | `Launch` |
| `tuning_echo` | `Tuning` |
| `unit_queue_burst` | `Unit` |

## Counter Question

Correct if the player names the targeted component and visible disruption.

| Counter | Required read |
|---|---|
| `pool_polluter` | Pool, Junk, capacity occupancy, or launch rhythm stutter. |
| `echo_breaker` | Echo slot/window, copy collapse, swallowed copy, or shrunken afterimage. |
| `stagger_punisher` | No-deployment gap, charge gap timer, gap hit, or pressure during squad charge. |

## Overdrive Question

Correct if the player ties Overdrive to the axis component:

- Launch: return arrows, Pool pressure, or launcher cadence.
- Tuning: Echo hot state, Echo window, copy afterimages.
- Unit: squad bracket, squad chain, or same-unit queue buildup.

Mark `overdrive_panic_flag` if the answer mainly describes rescue, shield, heal, freeze, clear-screen, or panic use.

## Frontline Cause Question

Correct if the player links machine event to the frontline signature.

| Hidden preset | Correct frontline cause |
|---|---|
| `launch_flood` | Pool rhythm or Front Return created sustained flow. |
| `tuning_echo` | Echo copy or hot-slot repetition created repeated heavy hits. |
| `unit_queue_burst` | Queue stack or squad bracket charged and released as a grouped push. |

Mark `unit_only_bias_flag` if the answer is only "more units", "more bodies", or equivalent generic output without the machine cause.

## Hard Success

- At least 3/5 target players answer at least 3 of 4 questions correctly after each battle.
- At least 3/5 target players can name a non-`Unit` axis as meaningful after seeing all three battles.
- At least 3/5 target players can explain why `Launch` or `Tuning` changed the frontline without reducing the answer to "more units."
- At least 3/5 target players can describe how one enemy counter disrupted a specific machine component.
- At least 3/5 target players describe Overdrive as amplification of the current axis.
- No more than 2/5 target players describe Overdrive mainly as rescue or panic.

