# Battle Lab Playtest Guide

## Target Players

Use 3-5 players from the primary audience:

- systems roguelite players,
- auto-battle optimizer players,
- optional casual physics players only if they already tolerate visual systems.

## One-Minute Briefing

Read this before the first battle:

```text
You will watch three short battles. Each battle is driven by one machine axis: Launch, Tuning, or Unit.
Your job is not to win perfectly. Your job is to observe what the machine changed, how the enemy disrupted it, what Overdrive amplified, and why the frontline changed.
After each battle, answer four questions before we discuss the answer key.
```

Do not explain the preset strategy, the correct counter, or the expected frontline signature before answers are recorded.

## Session Flow

1. Assign a `player_id`.
2. Choose internal fixed order for developer dry-runs or seeded randomized order for target-player sessions.
3. Run all three battles.
4. After each battle, let the result freeze and show the event strip.
5. Ask the four questions and record confidence from 1 to 5.
6. Record observer notes immediately.
7. Score `correct_count_0_to_4` after the answer is captured.
8. Mark `unit_only_bias_flag` when the player reduces the cause to generic unit output.
9. Mark `overdrive_panic_flag` when the player treats Overdrive mainly as rescue or panic.
10. Reveal or discuss answer keys only after all three battles are complete.

## Four Questions

1. What was the main axis this battle?
2. How did the enemy disrupt it?
3. What did Overdrive amplify?
4. Why did the frontline change?

## Required Record

Use `playtest/answer_sheet_template.csv` or the local result-screen export. Every battle record must include:

- `player_id`
- `battle_order`
- `hidden_preset`
- `answer_axis`
- `answer_counter`
- `answer_overdrive`
- `answer_frontline_cause`
- four confidence values from 1 to 5
- `observer_notes`
- `correct_count_0_to_4`
- `unit_only_bias_flag`
- `overdrive_panic_flag`

