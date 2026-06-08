# 08 — 测试、验证与 CI

## 1. 验证层级

每次任务至少说明验证到了哪一层。

```text
Level 0: 静态检查 — 代码读通、路径存在、类名/节点名一致
Level 1: Godot headless 打开 mvp/ 工程并退出
Level 2: 关键 scene 烟测（不报缺失节点/资源）
Level 3: 玩法路径烟测（球机产出 / 一路接战 / Deploy 选路 / 波次）
Level 4: 导出烟测（桌面 / Web）
Level 5: 自动化测试 / CI
```

---

## 2. Headless 检查

推荐使用（`GODOT_BIN` 指向 Godot 4.6）：

```bash
GODOT_BIN=/path/to/Godot ./mvp/tools/verify_godot.sh
```

脚本会尝试：打印 Godot 版本、headless 打开 `mvp/` 工程、若存在 `tools/verify_project.gd` 则运行项目自定义检查、若存在 Web/桌面 preset 则提示可执行导出检查。

如果 `mvp/project.godot` 尚不存在，脚本会报告 `Not run: mvp/project.godot not found` 并以非 0 状态退出。这只说明 Godot 工程尚未创建，不能汇报为 Level 1 通过。M0 创建工程后，缺少 `project.godot` 应视为验证失败。

---

## 3. 自定义验证脚本

可创建 `res://tools/verify_project.gd`（即 `mvp/tools/verify_project.gd`）：

```gdscript
extends SceneTree

## 启动期资源存在性检查：确认关键场景/资源没丢
func _init() -> void:
	var required_paths := [
		"res://project.godot",
		"res://scenes/run/run.tscn",   # 路径按实际主场景调整
	]
	for path in required_paths:
		if not ResourceLoader.exists(path):
			push_error("缺少必需资源：%s" % path)
			quit(1)
			return
	print("verify_project.gd passed")
	quit(0)
```

实际 `required_paths` 要按真实存在的场景填，不要写不存在的路径假装通过。

---

## 4. 场景烟测

为关键场景保留测试场景（见 `02` / `07`）：

```text
scenes/test/ball_machine_test.tscn
scenes/test/lane_combat_test.tscn
scenes/test/deploy_lane_test.tscn
scenes/test/enemy_wave_test.tscn
```

每次相关改动后至少打开对应测试场景。

---

## 5. 手动验收模板

玩法任务完成后给出：

```md
## Manual Validation
- Scene:
- Steps:
  1.
  2.
  3.
- Expected:
- Actual:
- Result: pass / fail / not run
- Notes:
```

针对本项目核心链，玩法验收尽量覆盖：球能进 Tuning/Unit 槽并产出队列、Deploy Lane 点击切路生效且高亮正确、单位沿路自动接战、敌人波次/反制预警出现、Endpoint 结算可读。不要写空泛的“已测试”。

---

## 6. 自动化测试

Godot 生态可选测试框架：GdUnit4、GUT。引入测试框架属于新增依赖，需按 `mvp/AGENTS.md` 第 8 节确认。

建议：

- MVP 阶段优先手动烟测 + 少量核心纯逻辑测试。
- 适合先写自动化测试的纯逻辑：接战伤害结算、队列部署节奏、奖励/商店价格带、波次/反制配置解析、路径坐标换算。
- 不要为了覆盖率重构整个项目。

---

## 7. CI 建议

最小 CI：

```text
checkout
install/download Godot 4.6
run mvp/tools/verify_godot.sh
optional run test framework
optional export desktop / Web
upload build artifact
```

CI 不需要一开始很复杂。先保证能自动发现导入错误、脚本错误、资源缺失。

---

## 8. 导出检查

若 `export_presets.cfg` 配置了 preset，可执行（preset 名要和配置一致）：

```bash
# Web
mkdir -p build/web
"$GODOT_BIN" --headless --path mvp --export-release "Web" build/web/index.html

# 桌面（示例 preset 名按实际配置）
mkdir -p build/desktop
"$GODOT_BIN" --headless --path mvp --export-release "macOS" build/desktop/planB.zip
```

注意：需安装 export templates；导出成功不代表运行成功，仍需在目标平台/浏览器打开并看控制台。

---

## 9. Agent 汇报格式

每次改动结束必须汇报（详见 `09-ai-coding-workflow.md`）：

```md
## Changed
-
## Validation
- Command:
- Result:
- Manual steps:
- Not run:
## Risks
-
## Next
-
```

没有实际运行的验证写 `Not run: 原因`，不能写“应该可以”。
