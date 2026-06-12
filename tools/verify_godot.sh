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

echo "verify_godot: PASS"
