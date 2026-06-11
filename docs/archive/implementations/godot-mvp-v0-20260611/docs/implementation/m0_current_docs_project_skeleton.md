# M0 Current-Docs Project Skeleton

## Scope

Build target: a fresh Godot 4.6 project rooted at `mvp/` that opens to a
placeholder MVP shell and provides current-doc data definition placeholders.

This M0 pass does not implement M1-M3 gameplay: no physical ball machine, no
three-lane combat simulation, no reward/shop economy flow, no counter effects,
and no Endpoint battle logic.

## Source Docs Named For This Implementation Surface

- `AGENTS.md`
- `README.md`
- `mvp/AGENTS.md`
- `mvp/docs/agent/README.md`
- `docs/gstack-artifacts/yang-mvp-handoff-20260608-164833.md`
- `docs/gdd.md`
- `docs/mvp-scope.md`
- `docs/machine-warehouses.md`
- `docs/battlefield-rules.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/neutral-modifiers.md`
- `docs/mvp-learning-checkpoints.md`
- `docs/ball-machine-physical.md`

Only the current docs listed above were used as implementation inputs.

## M0 Deliverables

- Godot project root: `mvp/project.godot`
- Main shell scene: `res://scenes/run/mvp_shell.tscn`
- Data Resource types under `res://scripts/data/`
- Placeholder Resource instances under `res://resources/`
- Debug session stepper in `MvpShell`
- Custom verification script: `res://tools/verify_project.gd`

## Verification

Run from the repository root:

```bash
./mvp/tools/verify_godot.sh
```
