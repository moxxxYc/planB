# Balance Health Report

Game: planB
Mode: B, Premium
Data Source: GDD / design doc only
Development Stage: docs-only MVP, pre-implementation
Branch: mvp
Generated: 2026-06-06 22:02:58 Asia/Shanghai

## Section Scores

Weights are normalized across active Mode B sections. Monetization is skipped. Character / unit balance is included because the MVP has Guardian choice and a fixed unit roster that still needs theoretical dominance checks.

| Section | Score | Weight | Notes |
|---|---:|---:|---|
| Difficulty Curve | 9/10 | 31.25% | Flow 3/3, spike frequency 2/2, recovery 2/3, variety 2/2. Section improved after adding per-battle difficulty targets and information-only failure recovery. |
| Economy Model | 5/10 | 31.25% | Gold has one clear currency, but no faucet/sink projection. Repair recovery amount is still unset. |
| Progression Pacing | 6/10 | 25% | MVP checkpoints and reward schedule are documented. Grind ratio and exact decision density are not modeled. |
| Monetization Pressure | N/A | N/A | Skipped for Premium mode. |
| Character / Unit Balance | 4/10 | 12.5% | Unit and Guardian frameworks are defined, but no pick-rate, win-rate, or expected-output model exists. |
| Weighted Total | 6.4/10 | 100% | Good structure for MVP docs, weak proof. Needs simulation or playtest before final balance claims. |

## Score Delta

The review changed Section 1 during the session.

| Section | Baseline | Final | Change |
|---|---:|---:|---:|
| Difficulty Curve | 8/10 | 9/10 | +1 |
| Economy Model | 5/10 | 5/10 | 0 |
| Progression Pacing | 6/10 | 6/10 | 0 |
| Character / Unit Balance | 4/10 | 4/10 | 0 |
| Weighted Total | 6.1/10 | 6.4/10 | +0.3 |

## Section Findings

### 1. Difficulty Curve, 9/10

Current difficulty targets:

| Battle | Target Length | Counter Triggers | Lane Pressure | First-play Failure Target |
|---|---:|---:|---|---:|
| Battle 1 | 90-110s | 0 | Single-lane light pressure | 0-5% |
| Battle 2 | 100-125s | 0 | Two-lane base pressure | 5-10% |
| Battle 3 | 115-140s | 1 | Main pressure lane + counter warning | 10-15% |
| Battle 4 | 105-130s | 0 | Shop patch validation | 8-12% |
| Battle 5 | 125-150s | 1-2 | Main pressure + side pressure | 15-20% |
| Endpoint | 165-195s | 1 | Endpoint Guardian + base-circle output | 20-25% |

This creates a clear sawtooth:

- Battle 3 is the first pressure peak.
- Battle 4 is the release and patch validation.
- Battle 5 raises pressure again.
- Endpoint tests whether the machine axis turns into base-circle output.

Recovery improved after documenting information-only failure recovery:

- Failure ends the run.
- No Gold is returned.
- No continue.
- No next-run resource compensation.
- Result page must show `main_break_reason`.
- Failed runs also show `next_run_watch_tag`.

Remaining data gap: no simulation or playtest proves the failure-rate targets.

### 2. Economy Model, 5/10

Known faucet:

| Source | Gold |
|---|---:|
| Start | 0 |
| Normal victory | 6 |
| Elite / strong counter victory | 8 |
| Endpoint | 0 |
| Failure | Undefined, no Gold |

Known price bands:

| Sink | Gold |
|---|---:|
| Repair | 3 |
| Patch item | 4 |
| Pivot item | 5 |
| Deepen item | 6 |

The Battle 1 economy works structurally: 6 Gold allows exactly one meaningful purchase, or repair plus leftover Gold. That matches the MVP learning goal.

The later-run economy is not proven. A plausible five-battle route before Endpoint can pay:

`6 + 6 + 8 + 6 + 8 = 30 Gold`

Documented sinks do not yet define enough purchase timing to prove the stockpile stays meaningful. If the player only sees two shops and buys two 6-Gold items, they can enter Endpoint with about 18 Gold unless repairs or more shop windows consume it. That may be fine for MVP, but right now it is unmodeled.

Repair is the sharpest gap. Price is 3 Gold, recovery amount is TBD. At 3 Gold:

- If repair restores too little, it is a fake option.
- If repair restores too much, it becomes the best sink and weakens lane-leak pressure.
- It also competes directly with the first machine purchase after Battle 1.

### 3. Progression Pacing, 6/10

The MVP has a readable checkpoint sequence:

1. Battle 1 first 30s, machine chain and Deploy Lane boundary.
2. First reward, three-axis anchor.
3. First shop, Gold opportunity cost.
4. First counter, machine weakness.
5. Second reward / shop, deepen vs patch.
6. Endpoint, machine payoff or break.

Reward schedule is documented well enough for MVP. The gap is decision density. There is no grind-ratio model:

- How many meaningful decisions per minute?
- How much time is spent watching auto-battle after the decision is already solved?
- Does Battle 4 feel like validation, or just waiting after buying a patch?

For a 15-20 minute run, the current design likely has enough checkpoints, but this needs timing telemetry.

### 4. Monetization Pressure, N/A

Skipped. The current business model is Premium / buyout, with possible DLC later. No F2P / IAP review applies.

### 5. Character / Unit Balance, 4/10

Framework status:

- Hive units use a mostly transitive structure: higher slot means higher commitment and stronger battlefield role.
- Slot Exposure Gate creates time and access cost for high-commitment units.
- Guardians are asymmetric soft anchors: Launch-leaning `巢脉母`, Tuning-leaning `酸冠母`.

This is coherent, but not proven.

Main missing numbers:

- Guardian pick-rate target.
- Guardian run success delta.
- Unit-slot output per battle.
- Expected queue entries by slot.
- Whether `Slot Primer` on Slot 3 or Slot 4 creates a dominant Unit line.
- Whether `Prime Charge` and `Slot Primer` are comparable as first reward choices.

No win-rate or pick-rate plan exists yet. For a docs-only MVP, that is expected, but it caps the score.

## Cross-Section Conflicts

1. Difficulty x Economy

Repair costs 3 Gold, but recovery amount is not set. Difficulty targets allow Endpoint failure at 20-25%. If repair is too strong, difficulty falls below target. If too weak, repair is dead stock and Gold has less sink demand.

2. Economy x Progression

Battle 1 has clean purchase pressure: 6 Gold vs 4/5/6 prices. Across Battle 1-5, expected Gold can reach about 30 before Endpoint. Shop timing and sink count are not yet enough to prove there is no late-run stockpile.

3. Balance x Economy

Price tiers are assigned before expected output is known. `Prime Charge`, `Echo Latch`, and `Slot Primer` all sit in the 6-Gold deepen tier, but their expected progress or queue impact is not modeled. Same price may not mean same power.

4. Difficulty x Progression

Slot 4 fully exposes at 96s. Battle 1 target is 90-110s. That means the highest-commitment slot barely participates in Battle 1, which is probably correct for teaching, but it must be tested. If players expect Slot 4 payoff in Battle 1, it will feel broken.

## Unresolved Issues

1. Repair recovery amount is TBD.
2. No faucet/sink projection exists for a full 6-battle run.
3. No expected-value model exists for the 9 neutral modifiers.
4. No Guardian pick-rate or success-rate target exists.
5. No grind-ratio or decision-density model exists.
6. No enemy wave HP / DPS table exists, so failure-rate targets are not validated.

Escalated Issues: 0

No hard escalation triggered. The economy has sinks, no core paywall, no F2P real-money random reward, and no documented faucet/sink ratio above 2.0 or below 0.5. The main issue is missing quantitative proof.

## Top 3 Priorities

1. Set repair recovery amount, or at least define tested candidates.
   Current price is 3 Gold. This sink competes with the first machine purchase, so it must be real but not dominant.

2. Build a 6-battle Gold projection.
   Use the documented faucet: normal = 6, Elite = 8, Endpoint = 0. Track stockpile after each reward/shop node.

3. Model expected output for first reward choices.
   Compare `Pool Pocket`, `Prime Charge`, and `Slot Primer` in expected Unit progress, queue entries, or battle outcome tags. Without that, the first reward is readable but not numerically comparable.

## Data Gaps

- Battle-by-battle Gold earned, spent, and stockpiled.
- Repair recovery amount.
- Shop timing count per run.
- Expected purchase count per run.
- Unit slot progress and queue entry counts per battle.
- Neutral modifier expected output.
- Guardian pick rate and win/success delta.
- Failure-rate target validation by battle.
- Grind ratio: meaningful decisions per minute vs solved waiting time.

## AI Confidence

70%

Benchmarks are industry heuristics. Calibrate with actual simulation and playtest data.

## Next Steps

- Keep the new per-battle difficulty table.
- Keep information-only failure recovery. Do not add failure Gold for MVP.
- Decide repair recovery amount next.
- Then build a small balance sandbox for Gold and neutral modifier expected output.

## Next Step

PRIMARY: /prototype-slice-plan, plan a small MVP balance sandbox before implementation.

If the next task is still design-only: /balance-review, decide repair recovery amount and neutral modifier final values.
