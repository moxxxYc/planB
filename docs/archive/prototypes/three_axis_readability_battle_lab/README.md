# Three-Axis Readability Battle Lab

Archived status: this prototype is fully expired. Do not use it as current build evidence, validation source, routing signal, or implementation input.

Fresh scoped Godot prototype for validating whether target players can read `Launch / Tuning / Unit` machine events as distinct frontline pressure patterns.

## Scope

Build only:

- one Battle Lab screen,
- three hardcoded presets: `Launch Flood`, `Tuning Echo`, `Unit Queue Burst`,
- three deterministic 75-second battles,
- three counter windows: `Pool Polluter`, `Echo Breaker`, `Stagger Punisher`,
- one axis-bound `Overdrive` opportunity per battle,
- blind post-battle answer recording.

Do not build:

- shop,
- race expansion,
- relics,
- Gold or economy,
- node map,
- events,
- elite or Boss roster,
- save or meta progression,
- backend, networking, matchmaking, accounts, telemetry service, or Steam integration,
- restored Web MVP source, npm/Vite/Phaser scripts, or generated Web assets.

## Commands

Run scope guard:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_scope_guard
```

Run all prototype tests:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd
```

Run the prototype after a scene exists:

```bash
godot --path prototype/three_axis_readability_battle_lab
```

## Playtest Flow

Use `playtest/guide.md` for the observer script and `playtest/scoring_guide.md` for correctness rules. Use `playtest/answer_sheet_template.csv` or the local result-screen export for records.

Hard success criteria:

- at least 3/5 players answer at least 3 of 4 questions correctly,
- at least 3/5 players can name a non-`Unit` axis as meaningful,
- at least 3/5 players can explain why `Launch` or `Tuning` changed the frontline without reducing it to "more units",
- at least 3/5 players can describe one enemy counter disrupting a specific machine component,
- at least 3/5 players describe `Overdrive` as amplification,
- no more than 2/5 players describe `Overdrive` mainly as rescue or panic.
