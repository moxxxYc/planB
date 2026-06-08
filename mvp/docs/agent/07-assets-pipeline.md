# 07 — 资产与 AI 美术流程

## 1. 资产目录

推荐（`res://assets/` 即 `mvp/assets/`）：

```text
assets/
  sprites/
    ball_machine/   # 球、钉板、炮台、仓壳
    units/          # 玩家单位
    enemies/        # 敌人
    battlefield/    # 路线、门、基地、Guardian
    ui/             # 面板、Deploy 高亮、危险提示、结算页
    vfx/
  audio/
    sfx/
    music/
  source/
    ai_reference/   # AI 生成参考、prompt 记录
    aseprite/
    psd/
    _scratch/       # 临时实验，完成后清理
```

`source/` 放源文件、AI 参考、可编辑工程文件；正式 Godot 使用资源放到对应 runtime 目录；`_scratch/` 完成后清理。

---

## 2. AI 生成资产规则

AI 生成素材必须记录来源和用途。建议每批资产写：

```text
assets/source/ai_reference/<date>-<topic>/README.md
```

内容：

```md
# Asset Batch
- Purpose:
- Prompt:
- Tool / Model:
- Generated date:
- Human cleanup:
- Used files:
- Rejected files:
- License / risk notes:
```

AI 资产进入正式目录前必须人工筛选和清理。

---

## 3. 灰阶可读性约束（本项目专属）

来自候选草案 `docs/ball-machine-physical.md`：表现层要在灰阶下仍可读，关键信息不能只靠颜色区分。

资产制作时：

- 球、单位、敌人、关键 UI 要有清晰剪影/明度差异，去色后仍能区分。
- 选中高亮（玩家色）和危险提示（敌方色）除颜色外要有形状/动态差异（描边 vs 脉冲）。
- 出图后做一次灰阶检查，确认关键信息没丢。

---

## 4. Sprite Sheet 规则

- 保持强剪影、小尺寸清晰。
- 动作帧数优先服务手感，不追求过度平滑。
- 每个动作命名稳定，统一朝向规则。
- 导入 Godot 后用测试场景验证（`scenes/test/`）。

单位/敌人示例动作：

```text
idle
march
attack
hit
death
```

球机表现（球、炮台）按 `ball-machine-physical.md` 候选草案的物理反馈语法处理，具体表现未锁定。

---

## 5. AnimatedSprite2D 与 AnimationPlayer

| 场景 | 工具 |
|---|---|
| 简单帧动画（单位、敌人动作） | `AnimatedSprite2D` + `SpriteFrames` |
| UI / 节点属性动画（高亮、面板） | `AnimationPlayer` |
| 复杂混合动画 | `AnimationTree`，MVP 默认不用 |

球的运动主要由物理驱动，不要用动画硬覆盖物理位置。MVP 阶段不要过早引入复杂动画状态机。

---

## 6. 导入设置原则

- 角色、敌人、道具、球贴图保证透明边缘干净。
- 控制单张贴图尺寸（见 `06` 性能预算）。
- Web 目标下优先压缩和减小资源。
- 像素风关闭不必要过滤；非像素风按项目美术规则处理。
- 资源旁的 `*.import` 元文件要随资产一起提交（见 `01-project-structure.md` 第 5 节），保证他人导入一致；只忽略 `.godot/` 本地缓存。修改 import 设置后记得把更新的 `.import` 一并提交。

---

## 7. Placeholder 规则

MVP 允许灰盒/占位资源，但必须标记：

```text
assets/sprites/_placeholder/
```

或文件名带 `placeholder_` / `temp_`。进入更正式阶段前要清点所有 placeholder。占位资产也要满足灰阶可读约束的最低限度（能区分球/单位/敌人/路线）。

---

## 8. 资产命名

```text
ball_machine_peg.png
ball_machine_turret.png
unit_melee_idle.png
enemy_rusher_march.png
battlefield_lane_mid.png
ui_deploy_highlight.png
ui_counter_warning.png
```

不要用：`新建图像.png`、`角色最终版2.png`、`temp-final-final.png`。

---

## 9. 场景测试

每类资产要有最小测试场景：

```text
scenes/test/ball_machine_test.tscn
scenes/test/unit_sprite_test.tscn
scenes/test/ui_state_test.tscn
```

测试内容：尺寸是否合理、剪影是否清晰、碰撞/判定是否对齐、动画循环是否正确、灰阶下是否仍可读、Web 下是否糊/卡/透明边异常。
