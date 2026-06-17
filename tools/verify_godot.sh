#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-godot}"
GODOT_ERROR_PATTERN="ERROR:|SCRIPT ERROR:|Parse Error|Can't load script"

if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
  echo "Missing active Godot project at $PROJECT_DIR/project.godot" >&2
  exit 1
fi

run_godot_verifier() {
  local script_path="$1"
  local log_file
  local godot_status

  log_file="$(mktemp "${TMPDIR:-/tmp}/planb-godot-verify.XXXXXX")"

  if "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "$script_path" >"$log_file" 2>&1; then
    godot_status=0
  else
    godot_status=$?
  fi

  cat "$log_file"

  if grep -Eq "$GODOT_ERROR_PATTERN" "$log_file"; then
    rm -f "$log_file"
    echo "verify_godot: FAIL ($script_path emitted Godot errors)" >&2
    return 1
  fi

  rm -f "$log_file"

  if [[ "$godot_status" -ne 0 ]]; then
    echo "verify_godot: FAIL ($script_path exited $godot_status)" >&2
    return "$godot_status"
  fi
}

run_godot_verifier "res://tools/verify_project.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_m1_machine_to_lane.gd" ]]; then
  echo "Missing required M1 verifier at $PROJECT_DIR/tools/verify_m1_machine_to_lane.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_m1_machine_to_lane.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_m2_run_flow.gd" ]]; then
  echo "Missing required M2 verifier at $PROJECT_DIR/tools/verify_m2_run_flow.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_m2_run_flow.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_m3_counter_flow.gd" ]]; then
  echo "Missing required M3 verifier at $PROJECT_DIR/tools/verify_m3_counter_flow.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_m3_counter_flow.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_m4_second_reward_flow.gd" ]]; then
  echo "Missing required M4 verifier at $PROJECT_DIR/tools/verify_m4_second_reward_flow.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_m4_second_reward_flow.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_entity_battlefield.gd" ]]; then
  echo "Missing required entity battlefield verifier at $PROJECT_DIR/tools/verify_entity_battlefield.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_entity_battlefield.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_full_handoff_flow.gd" ]]; then
  echo "Missing required full handoff verifier at $PROJECT_DIR/tools/verify_full_handoff_flow.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_full_handoff_flow.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_endpoint_result_fields.gd" ]]; then
  echo "Missing required endpoint result verifier at $PROJECT_DIR/tools/verify_endpoint_result_fields.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_endpoint_result_fields.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_machine_physics_contract.gd" ]]; then
  echo "Missing required machine physics verifier at $PROJECT_DIR/tools/verify_machine_physics_contract.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_machine_physics_contract.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_ball_machine_design_alignment.gd" ]]; then
  echo "Missing required ball machine design alignment verifier at $PROJECT_DIR/tools/verify_ball_machine_design_alignment.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_ball_machine_design_alignment.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_ball_machine_debug_scene.gd" ]]; then
  echo "Missing required ball machine debug scene verifier at $PROJECT_DIR/tools/verify_ball_machine_debug_scene.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_ball_machine_debug_scene.gd"

if [[ ! -f "$PROJECT_DIR/tools/verify_ball_machine_layout_stability.gd" ]]; then
  echo "Missing required ball machine layout stability verifier at $PROJECT_DIR/tools/verify_ball_machine_layout_stability.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_ball_machine_layout_stability.gd"

red_gate_failures=0

run_red_godot_verifier() {
  local script_path="$1"
  local local_path="${script_path#res://}"

  if [[ ! -f "$PROJECT_DIR/$local_path" ]]; then
    echo "Missing required red gate verifier at $PROJECT_DIR/$local_path" >&2
    red_gate_failures=1
    return
  fi

  if ! run_godot_verifier "$script_path"; then
    red_gate_failures=1
  fi
}

run_red_godot_verifier "res://tools/verify_physics_machine_integration.gd"
run_red_godot_verifier "res://tools/verify_exposure_gate.gd"
run_red_godot_verifier "res://tools/verify_guardian_contract_behaviors.gd"
run_red_godot_verifier "res://tools/verify_hive_unit_and_battle_profile.gd"
run_red_godot_verifier "res://tools/verify_modifier_semantics.gd"
run_red_godot_verifier "res://tools/verify_complete_learning_record.gd"

if [[ "$red_gate_failures" -ne 0 ]]; then
  echo "verify_godot: FAIL (red verification gates failed)" >&2
  exit 1
fi

echo "verify_godot: PASS"
