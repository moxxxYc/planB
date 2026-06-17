# PlanB Ball Machine Shared Component and Layout Single Source Plan

**Status:** revised after plan review.

**Goal:** Make the ball machine a reusable Godot component shared by the standalone debug scene and the real battle scene, and make visible drawing, slot layout, physics stage rects, and verifier contracts read from one layout source.

**Non-goal:** Do not change `display/window/stretch/aspect=keep` in this plan. With the current `canvas_items + keep` project setting, runtime window resizing keeps the same logical canvas and letterboxes/pillarboxes. So this plan does not promise true runtime responsive behavior. Multi-size tests are regression tests for explicit component host sizes, not evidence that the current project stretch mode resizes gameplay layout at runtime.

**Architecture:** Introduce `BallMachineView` as the host-neutral shared component. Keep `MachineStripView` as the battle wrapper/readout API. Add `MachineBoardLayoutMetrics` as the single source of geometry, and make both `MachineBoardView` drawing and `MachinePhysicsBoardView` stage placement consume it.

**Tech Stack:** Godot 4.6, GDScript, Control/Container UI, Node2D physics visuals, existing headless verifier scripts.

---

## Skill Routing

- `godot-prompter:scene-organization`: shared `BallMachineView` scene/component boundary.
- `godot-prompter:godot-ui`: Control/Container ownership and host scene layout.
- `godot-prompter:responsive-ui`: explicit host-size metrics tests and layout guardrails.
- `godot-prompter:physics-system`: physics stage rect contract and protected scale behavior.
- `godot-prompter:2d-essentials`: Node2D draw order, clipping, and canvas coordinate checks.
- `godot-prompter:godot-testing`: headless verifier additions.
- `superpowers:writing-plans`: this implementation plan. Do not replace GodotPrompter for Godot-specific details.

## Review Corrections Incorporated

- Keep `project.godot` stretch mode unchanged and rename the goal away from broad "responsive runtime UI".
- Metrics must exactly reproduce the current visible board geometry first, then both drawing and physics consume it.
- Add a verifier that checks visible board rects and physics stage rects are identical, not just slot ratios.
- Instantiate `BallMachineView` from its `.tscn` in verifiers. Do not use `BallMachineViewScript.new()` because the wrapper depends on scene children.
- Test explicit host sizes by placing the shared scene inside a fixed-size host `Control`, so full-rect anchors do not collapse every case to the viewport size.
- Do not hand-write a fake `.tscn` `uid`; omit it and let Godot assign one.
- Add `verify_ball_machine_layout_stability.gd` to the modified file list and update its node paths after the shared component rename.
- Keep the full `MachineStripView` public API and `landing_resolved` forwarding. Hidden readout cleanup is allowed only after the wrapper still passes every battle-facing method and signal verifier.
- Add `docs/PROGRESS.md` as a required decision-log update.
- Runtime normative physics scale must remain `1.0` under the current `keep` setup until a landing-distribution regression exists.

## File Structure

- Create: `godot/scripts/ui/ball_machine_view.gd`
  - Shared host-neutral API for the ball machine component.
  - Owns one `MachineBoardView` child and forwards `landing_resolved`.
- Create: `godot/scenes/machine/ball_machine_view.tscn`
  - Reusable component scene.
  - Do not include debug buttons, battle state, logs, or host readouts.
  - Do not hand-write `uid=...`.
- Create: `godot/scripts/ui/machine_board_layout_metrics.gd`
  - `RefCounted` layout data builder from an explicit component size.
  - Owns supply rect, board rects, physics clip rect, queue rect, slot rects, and scale metadata.
- Create: `godot/tools/verify_ball_machine_shared_view_contract.gd`
  - Proves debug and battle scenes use the shared `BallMachineView`.
- Create: `godot/tools/verify_ball_machine_layout_rect_alignment.gd`
  - Proves visible board rects and physics stage rects are the same source.
- Create: `godot/tools/verify_ball_machine_host_size_layout.gd`
  - Proves the shared component remains readable under explicit host sizes.
- Create: `godot/tools/verify_ball_machine_landing_distribution.gd`
  - Proves protected physical scaling does not silently change seeded landing behavior.
- Modify: `godot/scripts/ui/machine_board_view.gd`
  - Replace scattered board geometry calculations with `MachineBoardLayoutMetrics`.
  - Expose visible layout rects in the visual contract.
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
  - Consume stage rects from metrics.
  - Keep normative physical size scale at `1.0` unless a non-normative host-size test explicitly exercises scaling.
- Modify: `godot/scripts/ui/machine_strip_view.gd`
  - Replace direct `MachineBoardView` dependency with `BallMachineView`.
  - Preserve all battle-facing methods, `get_readable_log_text()`, `landing_resolved`, and log behavior.
- Modify: `godot/scripts/debug/ball_machine_debug_scene.gd`
  - Replace direct `MachineBoardView` dependency with `BallMachineView`.
- Modify: `godot/scenes/machine/ball_machine_debug.tscn`
  - Instantiate `BallMachineView`.
- Modify: `godot/scenes/run/battle_one_vertical.tscn`
  - Put `BallMachineView` inside `MachineStripView`.
- Modify: `godot/tools/verify_ball_machine_debug_scene.gd`
  - Assert debug scene hosts the shared component.
- Modify: `godot/tools/verify_ball_machine_design_alignment.gd`
  - Assert visible and physical slot order/ratios still match design after refactor.
- Modify: `godot/tools/verify_ball_machine_layout_stability.gd`
  - Update node paths and sampling so the new shared component is still covered.
- Modify: `godot/tools/verify_machine_physics_contract.gd`
  - Assert physical contract exposes protected scale and still meets readability thresholds.
- Modify: `tools/verify_godot.sh`
  - Add new verifiers only after their targeted runs are GREEN.
- Modify: `docs/PROGRESS.md`
  - Record the shared component / layout single-source decision and the stretch-mode caveat.

---

## Task 0: Confirm Scope Gate

**Files:** none.

- [ ] Confirm this is still within the active Godot M0-M4 gap repair scope.
- [ ] Confirm `project.godot` keeps:

```ini
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

- [ ] Confirm no gameplay canon, slot order, slot width ratio, or warehouse rule changes are part of this refactor.

## Task 1: Shared Component Contract Verifier

**Files:**
- Create: `godot/tools/verify_ball_machine_shared_view_contract.gd`

- [ ] Write the targeted verifier before implementation.
- [ ] The verifier must load host scenes from `.tscn`, not rely on script-only construction.
- [ ] It must assert:
  - `res://scenes/machine/ball_machine_view.tscn` exists.
  - Debug scene contains exactly one `BallMachineView`.
  - Battle scene contains exactly one `BallMachineView`.
  - No host scene owns a private `MachineBoardView` outside `BallMachineView`.
  - `BallMachineView` exposes:

```gdscript
[
	"render",
	"launch_ball",
	"set_exposure_state",
	"set_battle_elapsed",
	"set_redirect_resolver",
	"emit_seeded_landing_for_verifier",
	"run_seeded_chain_for_verifier",
	"get_visual_contract_summary",
	"get_runtime_contract",
]
```

- [ ] It must assert `BallMachineView` has the `landing_resolved` signal.
- [ ] Run targeted verifier and confirm RED:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_shared_view_contract.gd
```

Do not add this verifier to `tools/verify_godot.sh` until the targeted run is GREEN.

## Task 2: Create Shared `BallMachineView`

**Files:**
- Create: `godot/scripts/ui/ball_machine_view.gd`
- Create: `godot/scenes/machine/ball_machine_view.tscn`

- [ ] Create `ball_machine_view.gd` as a thin wrapper around `%MachineBoardView`.
- [ ] Forward every public method listed in Task 1.
- [ ] Forward `landing_resolved` from the child board.
- [ ] Add `shared_component = "BallMachineView"` to `get_visual_contract_summary()`.
- [ ] Create `ball_machine_view.tscn` with this shape:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/ui/ball_machine_view.gd" id="1_ball_machine_view"]
[ext_resource type="Script" path="res://scripts/ui/machine_board_view.gd" id="2_machine_board"]

[node name="BallMachineView" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_ball_machine_view")

[node name="MachineBoardView" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
custom_minimum_size = Vector2(720, 760)
script = ExtResource("2_machine_board")
```

- [ ] Targeted verifier should still be RED until host scenes switch.

## Task 3: Switch Debug Scene to Shared Component

**Files:**
- Modify: `godot/scenes/machine/ball_machine_debug.tscn`
- Modify: `godot/scripts/debug/ball_machine_debug_scene.gd`
- Modify: `godot/tools/verify_ball_machine_debug_scene.gd`

- [ ] Replace the direct debug-scene `MachineBoardView` node with an instanced `BallMachineView`.
- [ ] Update debug script typing and fallback lookup from `%MachineBoardView` to `%BallMachineView`.
- [ ] Keep debug controls, debug log, and contract text outside `BallMachineView`.
- [ ] Update debug verifier to assert `shared_component == "BallMachineView"`.
- [ ] Run:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_debug_scene.gd
godot --headless --path godot --script res://tools/verify_ball_machine_shared_view_contract.gd
```

Expected: debug verifier GREEN; shared verifier remains RED until battle switches.

## Task 4: Switch Battle Scene Through `MachineStripView`

**Files:**
- Modify: `godot/scenes/run/battle_one_vertical.tscn`
- Modify: `godot/scripts/ui/machine_strip_view.gd`

- [ ] Replace `MachineStripView`'s direct `MachineBoardView` child with an instanced `BallMachineView`.
- [ ] Update `MachineStripView` preload, onready reference, and fallback lookup to `BallMachineView`.
- [ ] Preserve this `MachineStripView` surface exactly:

```gdscript
signal landing_resolved(result: MachinePhysicsResult)

func render(machine, counter_target_component: String = "") -> void
func get_visual_contract_summary() -> Dictionary
func launch_ball(ball: Dictionary, battle_elapsed: float) -> void
func set_exposure_state(exposure_state) -> void
func set_redirect_resolver(resolver: Callable) -> void
func emit_seeded_landing_for_verifier(result: MachinePhysicsResult) -> MachinePhysicsResult
func run_seeded_chain_for_verifier(results: Array[MachinePhysicsResult]) -> void
func get_runtime_contract() -> Dictionary
func get_readable_log_text() -> String
```

- [ ] Keep `MachineLogLabel` behavior intact because `battle_one_vertical.gd` reads it through `get_readable_log_text()`.
- [ ] Run:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_shared_view_contract.gd
godot --headless --path godot --script res://tools/verify_m2_run_flow.gd
```

Expected: both GREEN.

## Task 5: Add Metrics as the Exact Geometry Source

**Files:**
- Create: `godot/scripts/ui/machine_board_layout_metrics.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`

- [ ] Create `MachineBoardLayoutMetrics`.
- [ ] First version must reproduce current `MachineBoardView` geometry exactly:

```gdscript
const MIN_VIEW_SIZE: Vector2 = Vector2(380.0, 600.0)
const SUPPLY_STRIP_HEIGHT: float = 164.0
const BOARD_LEFT_RIGHT_MARGIN: float = 14.0
const BOARD_TOP_AFTER_SUPPLY: float = 32.0
const BOARD_GAP: float = 12.0
const QUEUE_HEIGHT: float = 64.0
const BOARD_BOTTOM_MARGIN: float = 18.0
const MIN_BOARD_HEIGHT: float = 96.0
```

- [ ] `build(size)` must calculate:

```gdscript
var current_size := Vector2(maxf(size.x, MIN_VIEW_SIZE.x), maxf(size.y, MIN_VIEW_SIZE.y))
var board_top := SUPPLY_STRIP_HEIGHT + BOARD_TOP_AFTER_SUPPLY
var available_height := current_size.y - board_top - QUEUE_HEIGHT - BOARD_GAP * 2.0 - BOARD_BOTTOM_MARGIN
var board_height := maxf(MIN_BOARD_HEIGHT, available_height / 3.0)
var launch_rect := Rect2(BOARD_LEFT_RIGHT_MARGIN, board_top, current_size.x - BOARD_LEFT_RIGHT_MARGIN * 2.0, board_height)
var tuning_rect := Rect2(launch_rect.position + Vector2(0.0, board_height + BOARD_GAP), launch_rect.size)
var unit_rect := Rect2(launch_rect.position + Vector2(0.0, (board_height + BOARD_GAP) * 2.0), launch_rect.size)
```

- [ ] Add `_layout_metrics()` cache in `MachineBoardView`.
- [ ] Replace `_draw_machine_boards(rect)` so it draws `Launch`, `Tuning`, and `Unit` from `metrics.stage_rects`.
- [ ] Replace `_stage_rects_for_size()` and `_physics_clip_rect_for_size()` so they return the same metrics values.
- [ ] Add `visible_stage_rects` and `layout_metrics_source = "MachineBoardLayoutMetrics"` to `get_visual_contract_summary()`.
- [ ] Do not introduce proportional `margin_x`, proportional `supply_height`, or changed board gaps in this task. Those are design changes, not a safe refactor.

## Task 6: Visible/Physics Rect Alignment Verifier

**Files:**
- Create: `godot/tools/verify_ball_machine_layout_rect_alignment.gd`
- Modify: `godot/tools/verify_ball_machine_design_alignment.gd`
- Modify: `godot/tools/verify_machine_physics_contract.gd`

- [ ] Create a verifier that instantiates `MachineBoardView` directly and calls `get_visual_contract_summary()`.
- [ ] Assert:
  - `layout_metrics_source == "MachineBoardLayoutMetrics"`.
  - Every `visible_stage_rects[stage]` equals `stage_rects[stage]` position and size within epsilon.
  - `physics_clip_rect` equals the merge of the same three stage rects.
  - Slot order and slot width ratios are unchanged.
- [ ] Update existing design/physics verifiers to use the same checks where relevant.
- [ ] Run:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_layout_rect_alignment.gd
godot --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
godot --headless --path godot --script res://tools/verify_machine_physics_contract.gd
```

Expected: all GREEN before any physical-size scaling work begins.

## Task 7: Protected Physics Scale and Landing Regression

**Files:**
- Modify: `godot/scripts/ui/machine_board_layout_metrics.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
- Create: `godot/tools/verify_ball_machine_landing_distribution.gd`

- [ ] Add `physics_scale` to metrics but lock the normative runtime size to `1.0`.
- [ ] If explicit host-size tests apply a non-1 scale, clamp minimum physical readability:
  - ball radius remains positive and visible.
  - peg radius remains visible.
  - moving mechanism body thickness must not drop below `10.0`.
  - unit gate plate must remain large enough for ball bounce.
- [ ] Add `set_layout_physics_scale(value)` to `MachinePhysicsBoardView`.
- [ ] Replace physical size reads only through a guarded `_scaled(value, min_value := 0.0)` helper.
- [ ] Add contract fields:

```gdscript
"layout_physics_scale": _layout_physics_scale,
"scaled_ball_radius": _scaled(BALL_RADIUS),
"scaled_peg_radius": _scaled(PEG_RADIUS),
"scaled_mechanism_thickness": _scaled(MECHANISM_THICKNESS, 10.0),
```

- [ ] Add seeded landing distribution verifier before accepting non-1 physical scaling:
  - run deterministic chains through Launch/Tuning/Unit.
  - assert every required route can still be reached.
  - assert unit blocked bounce still rebounds instead of sticking.
  - assert no lower warehouse ball enters an upper warehouse.
- [ ] Run:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_landing_distribution.gd
godot --headless --path godot --script res://tools/verify_machine_physics_contract.gd
```

Expected: GREEN. If landing distribution changes unexpectedly, stop and keep physical sizes unscaled for this refactor.

## Task 8: Explicit Host-Size Layout Verifier

**Files:**
- Create: `godot/tools/verify_ball_machine_host_size_layout.gd`

- [ ] Instantiate `BallMachineView` from `res://scenes/machine/ball_machine_view.tscn`.
- [ ] Do not use `BallMachineViewScript.new()`.
- [ ] Put each instance inside a fixed-size host `Control`:

```gdscript
var packed: PackedScene = load("res://scenes/machine/ball_machine_view.tscn") as PackedScene
var host := Control.new()
host.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
host.size = size
root.add_child(host)
var view := packed.instantiate() as Control
host.add_child(view)
view.set_anchors_preset(Control.PRESET_FULL_RECT, false)
view.position = Vector2.ZERO
view.size = size
await process_frame
```

- [ ] Test at least:

```gdscript
[
	Vector2(720, 760),
	Vector2(960, 760),
	Vector2(1280, 720),
	Vector2(1024, 768),
	Vector2(844, 600),
]
```

Do not include `844x390` unless a separate compact-mode design is confirmed. The current board minimum height is `600`.

- [ ] Assert:
  - `shared_component == "BallMachineView"`.
  - `layout_metrics_source == "MachineBoardLayoutMetrics"`.
  - every stage rect is readable.
  - moving mechanism overlay is drawable and inside the owning stage rect.
  - visible rects and physics rects align.

## Task 9: Update Layout Stability Verifier

**Files:**
- Modify: `godot/tools/verify_ball_machine_layout_stability.gd`

- [ ] Replace stale `MachineBoardView` node paths with `BallMachineView` paths.
- [ ] Keep sampling the nested `MachineBoardView` through `find_child()` so the underlying board remains covered.
- [ ] Add explicit samples for:
  - `BallMachineView.find`
  - nested `MachineBoardView.find`
  - `visible_stage_rect.Launch/Tuning/Unit`
  - `stage_rect.Launch/Tuning/Unit`
- [ ] Assert sampled visible and physics stage heights remain stable during runtime.
- [ ] Run:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_layout_stability.gd
```

Expected: GREEN.

## Task 10: Remove Scene-Specific Layout Drift Safely

**Files:**
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Modify: `godot/scenes/run/battle_one_vertical.tscn`

- [ ] Keep host-specific panels outside `BallMachineView`:

```text
debug scene owns: controls, debug log, contract text
battle scene owns: title/readout wrapper, machine log, bridge, battlefield
BallMachineView owns: MachineBoardView, physics board, ball machine visual/physical contract
```

- [ ] Hidden readout nodes in `MachineStripView` may be deleted only after:
  - `render()` still updates `machine_board` and `log_label`.
  - every public method listed in Task 4 still exists.
  - `get_readable_log_text()` still works.
  - `landing_resolved` still forwards.

Do not reduce `MachineStripView` to only `machine_board.render()` if that breaks log or battle wrapper responsibilities.

## Task 11: Register Verifiers and Update Progress

**Files:**
- Modify: `tools/verify_godot.sh`
- Modify: `docs/PROGRESS.md`

- [ ] Add new verifiers to `tools/verify_godot.sh` only after targeted GREEN:

```bash
run_godot_verifier "res://tools/verify_ball_machine_shared_view_contract.gd"
run_godot_verifier "res://tools/verify_ball_machine_layout_rect_alignment.gd"
run_godot_verifier "res://tools/verify_ball_machine_host_size_layout.gd"
run_godot_verifier "res://tools/verify_ball_machine_landing_distribution.gd"
```

- [ ] Record in `docs/PROGRESS.md`:
  - ball machine shared component decision.
  - layout single-source decision.
  - `keep` stretch-mode caveat.
  - no gameplay canon changed.

## Task 12: Full Verification and Manual Check

**Files:** modify only if verifier failures identify regressions.

- [ ] Run targeted verifiers:

```bash
godot --headless --path godot --script res://tools/verify_ball_machine_shared_view_contract.gd
godot --headless --path godot --script res://tools/verify_ball_machine_layout_rect_alignment.gd
godot --headless --path godot --script res://tools/verify_ball_machine_host_size_layout.gd
godot --headless --path godot --script res://tools/verify_ball_machine_landing_distribution.gd
godot --headless --path godot --script res://tools/verify_ball_machine_debug_scene.gd
godot --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
godot --headless --path godot --script res://tools/verify_machine_physics_contract.gd
godot --headless --path godot --script res://tools/verify_ball_machine_layout_stability.gd
```

- [ ] Run full verifier:

```bash
bash tools/verify_godot.sh
```

- [ ] Run diff hygiene:

```bash
git diff --check
```

- [ ] Manual scene check:

```bash
godot --path godot res://scenes/machine/ball_machine_debug.tscn
godot --path godot res://scenes/run/battle_one_vertical.tscn
```

Expected manual result:
- Debug and battle use the same ball machine component.
- Debug controls do not appear in battle.
- Battle bridge/battlefield do not appear in debug.
- Ball launches from the visible muzzle in both scenes.
- Visible board rects, physics board rects, slots, moving plates, and bottom catchers are aligned.
- Runtime window resize under current `keep` setting does not stretch or jitter the component.

## Execution Notes

- Do not read or reuse archived `docs/archive/implementations/godot-mvp-v0-20260611/` code.
- Do not change gameplay canon or slot rules in this refactor.
- Do not change `project.godot` stretch mode in this refactor.
- Do not make debug-only behavior part of `BallMachineView`.
- Keep `BallMachineView` API host-neutral and testable from headless verifiers.
- Treat any non-1 physical scaling as gameplay-affecting until the landing-distribution verifier passes.
