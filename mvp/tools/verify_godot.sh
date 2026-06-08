#!/usr/bin/env bash
set -euo pipefail

# Godot 工程根 = mvp/（本脚本在 mvp/tools/ 下，父目录的上一级即 mvp/）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

cd "$ROOT"

echo "[verify] 工程根: $ROOT"
echo "[verify] Godot 可执行: $GODOT_BIN"

# 前置检查：还没建 Godot 工程时直接退出，避免误以为脚本坏了
if [[ ! -f "$ROOT/project.godot" ]]; then
  echo "[verify] Not run: mvp/project.godot not found"
  echo "[verify] 当前仓库还没有 Godot 工程。等创建 mvp/project.godot 后再运行本脚本。"
  exit 2
fi

echo "[verify] Godot 版本（需为 4.6.x）"
"$GODOT_BIN" --version

echo "[verify] headless 打开工程烟测"
"$GODOT_BIN" --headless --path "$ROOT" --quit --no-header

if [[ -f "$ROOT/tools/verify_project.gd" ]]; then
  echo "[verify] 运行 tools/verify_project.gd"
  "$GODOT_BIN" --headless --path "$ROOT" --script "res://tools/verify_project.gd" --no-header
else
  echo "[verify] 跳过自定义检查：未找到 tools/verify_project.gd"
fi

if [[ -f "$ROOT/tools/verify_machine_causality.gd" ]]; then
  echo "[verify] 运行 tools/verify_machine_causality.gd"
  "$GODOT_BIN" --headless --path "$ROOT" --script "res://tools/verify_machine_causality.gd" --no-header
else
  echo "[verify] 跳过 M1 机器因果验证：未找到 tools/verify_machine_causality.gd"
fi

if [[ -f "$ROOT/export_presets.cfg" ]]; then
  echo "[verify] 找到 export_presets.cfg"
  echo "[verify] 手动测试导出可执行（preset 名按实际配置）:"
  echo "  # Web"
  echo "  mkdir -p build/web && GODOT_BIN=\"$GODOT_BIN\" \$GODOT_BIN --headless --path \"$ROOT\" --export-release \"Web\" build/web/index.html"
  echo "  # 桌面"
  echo "  mkdir -p build/desktop && GODOT_BIN=\"$GODOT_BIN\" \$GODOT_BIN --headless --path \"$ROOT\" --export-release \"macOS\" build/desktop/planB.zip"
else
  echo "[verify] 跳过导出检查：未找到 export_presets.cfg"
fi

echo "[verify] 完成"
