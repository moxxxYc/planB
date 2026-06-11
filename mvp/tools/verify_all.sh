#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MVP_DIR="$ROOT_DIR/mvp"

find_godot() {
  if [[ -n "${GODOT_BIN:-}" ]]; then
    printf '%s\n' "$GODOT_BIN"
    return 0
  fi

  local candidate
  for candidate in godot4.6 godot4 godot; do
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

run_check() {
  local name="$1"
  local script_path="$2"

  printf '\n==> %s\n' "$name"

  if [[ ! -f "$script_path" ]]; then
    echo "ERROR: required verifier not found: $script_path" >&2
    exit 2
  fi

  run_godot_clean --headless --path "$MVP_DIR" --script "res://tools/$(basename "$script_path")" --no-header
}

run_godot_clean() {
  local output
  local status

  set +e
  output="$("$GODOT" "$@" 2>&1)"
  status=$?
  set -e

  printf '%s\n' "$output" | awk '
    /^WARNING: [0-9]+ RIDs of type "CanvasItem" were leaked\./ { skip_at = 1; next }
    /^ERROR: [0-9]+ RID allocations of type .* were leaked at exit\./ { next }
    /^WARNING: ObjectDB instances leaked at exit/ { skip_at = 1; next }
    skip_at && /^[[:space:]]+at: (_free_rids|cleanup) / { skip_at = 0; next }
    { skip_at = 0; print }
  '

  return "$status"
}

GODOT="$(find_godot)" || {
  echo "ERROR: Godot executable not found. Set GODOT_BIN=/path/to/godot." >&2
  exit 127
}

echo "[verify-all] repo root: $ROOT_DIR"
echo "[verify-all] Godot executable: $GODOT"

if [[ ! -f "$MVP_DIR/project.godot" ]]; then
  echo "ERROR: mvp/project.godot not found." >&2
  exit 2
fi

printf '\n==> Godot version\n'
"$GODOT" --version

printf '\n==> Headless project open\n'
run_godot_clean --headless --path "$MVP_DIR" --quit --no-header

run_check "Project verification" "$MVP_DIR/tools/verify_project.gd"
run_check "Machine causality" "$MVP_DIR/tools/verify_machine_causality.gd"
run_check "Battlefield deploy loop" "$MVP_DIR/tools/verify_battlefield_deploy_loop.gd"
run_check "MVP session" "$MVP_DIR/tools/verify_mvp_session.gd"
run_check "Playable session" "$MVP_DIR/tools/verify_playable_session.gd"

printf '\nAll verification checks passed.\n'
