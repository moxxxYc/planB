# 01 — 项目结构、命名与版本控制

> Godot 工程根 = `mvp/`，即 `res://` 对应仓库里的 `mvp/` 目录。本文所有 `res://` 路径都落在 `mvp/` 下。

## 1. 目录原则

目录按“职责/系统”组织，而不是按“文件类型堆平”。结构应能直接对应本项目的核心系统：球机（`Launch / Tuning / Unit`）、三路战场、Deploy Lane、敌人波次、奖励/商店、一局流程。

推荐结构：

```text
res://   (= mvp/)
  project.godot
  scenes/
    run/            # 一局流程、关卡、Endpoint 结算
    ball_machine/   # 三仓球机、钉板、炮台等物理表现
    battlefield/    # 三条路、单位、门、基地、Guardian
    deploy/         # Deploy Lane 选路 UI 与交互
    economy/        # 奖励、商店、休整结果页
    enemy/          # 敌人、波次、反制预警
    ui/             # HUD、面板、通用 UI
    test/           # 手动验证用测试场景
  scripts/
    core/           # 跨系统基础类、工具、Resource 基类
    run/
    ball_machine/
    battlefield/
    deploy/
    economy/
    enemy/
    ui/
  resources/
    machine/        # Launch/Tuning/Unit 组件、Gate/Prime/Echo/Surge 槽配置
    units/          # 单位属性
    enemies/        # 敌人属性、波次表
    economy/        # 奖励/商店条目、价格带
    levels/         # 关卡/局配置
  assets/
    sprites/
    audio/
    vfx/
    ui/
    source/         # 源文件、AI 参考、可编辑工程文件
  docs/
    agent/          # 本工程规则目录
  tools/            # 工程辅助：Godot CLI/编辑器脚本(.gd) + shell 脚本(.sh)
  tests/
```

目录职责约定（避免脚本放错位）：

- `res://scripts/` **只放 GDScript 游戏代码**（`.gd`）。
- shell 辅助脚本（如 `verify_godot.sh`）和 Godot CLI 验证脚本（如 `verify_project.gd`）统一放 `res://tools/`。`.sh` 不是 Godot 资源，放在 `tools/` 不会被当资源导入，也不和"GDScript 游戏代码目录"混淆。
- 不要把 shell 脚本放进 `scripts/`，那是游戏代码目录。

系统目录名以本项目术语为准，不要发明与设计 canon 冲突的新系统名。新系统目录出现前，先确认它对应某个已确认设计。

如果项目已有稳定结构，不强制迁移。新文件优先按此结构放置。

---

## 2. 命名规则

采用 Godot 风格：

| 类型 | 规则 | 示例 |
|---|---|---|
| 文件名 | `snake_case` | `launch_chamber.gd` |
| 目录名 | `snake_case` | `ball_machine`, `deploy` |
| class_name | `PascalCase` | `class_name LaunchChamber` |
| Node 名 | `PascalCase` | `LaunchChamber`, `PegBoard`, `Lane` |
| 函数 | `snake_case` | `spawn_unit()` |
| 变量 | `snake_case` | `launch_power` |
| 私有变量/函数 | `_snake_case` | `_current_target` |
| 常量 | `CONSTANT_CASE` | `MAX_UNITS_ON_LANE` |
| Signal | `snake_case`，过去式优先 | `unit_spawned`, `lane_selected` |

代码标识符用英文术语对齐设计 canon：`launch` / `tuning` / `unit` / `gate` / `prime` / `echo` / `surge` / `lane` / `deploy` / `guardian` / `gold`。不要用旧术语（如 `overdrive` 作为基础按钮）。

文件名要避免大小写歧义。不要同时存在 `Lane.gd` 和 `lane.gd` 这种跨平台风险文件（Web 导出与 macOS 大小写不敏感文件系统会踩坑）。

---

## 3. Scene 与 Script 放置

推荐一一对应，但不强制：

```text
scenes/ball_machine/launch_chamber.tscn
scripts/ball_machine/launch_chamber.gd
```

对于复杂对象，可按职责拆分脚本：

```text
scenes/battlefield/unit.tscn
scripts/battlefield/unit.gd          # 主控
scripts/battlefield/unit_stats.gd    # 属性（也可做成 Resource）
scripts/battlefield/unit_combat.gd   # 接战结算
```

不要为了“分层”把 20 行逻辑拆成 5 个脚本。先保持简单。

---

## 4. Resource 放置

可复用配置优先放 `resources/`：

```text
resources/machine/gate_slot.tres
resources/machine/launch_component_basic.tres
resources/units/melee_unit.tres
resources/enemies/wave_01.tres
resources/economy/shop_item_*.tres
```

适合 Resource 的内容：

- 机器组件 / Tuning 槽（`Gate / Prime / Echo / Surge`）数值
- 单位属性
- 敌人属性、波次表、反制配置
- 奖励 / 商店条目、价格带
- 关卡 / 一局配置
- UI 文案配置

不适合 Resource 的内容：

- 一次性临时变量
- 运行中不断变化的瞬时状态（如球的实时位置、当前接战进度）
- 强依赖具体 scene 节点的引用

具体数值未在设计文档锁定时，Resource 字段用占位默认值并标注“占位/调试起手值，非最终平衡”，不要伪装成已定平衡。

---

## 5. 版本控制规则

必须提交：

- `project.godot`
- `.tscn`、`.gd`、`.tres` / `.res`
- 源资产和正式资产
- `export_presets.cfg`（如果需要复现导出配置）
- `docs/`、`scripts/`、`tools/`、`tests/`

仓库根 `.gitignore` 当前为：

```gitignore
.DS_Store
.godot/
*.translation
```

`.import` 策略（按 Godot 4 惯例）：

- **忽略** `.godot/`（本地导入缓存，可由源资产重新生成）。
- **提交** 各资源旁的 `*.import` 元文件，保证他人 clone 后导入可复现，避免首次打开报错。
- `*.translation` 是由 `.po` / `.csv` 生成的产物，可忽略；提交对应翻译源文件。

不要静默改动 `.gitignore`；如需调整策略先确认。

通常不要提交：`.godot/`、临时 build 输出、导出目录（如 `build/`）、系统文件、编辑器个人缓存、大体积中间产物（除非项目明确需要）。

大体积二进制资产可考虑 Git LFS，但不要一开始就把所有东西塞进 LFS，先按资产规模决定。

---

## 6. 修改 project.godot 的规则

`project.godot` 是高风险文件。AI agent 不得静默修改。

允许修改的情况（任务明确要求时）：

- 新增 Input Action。
- 新增 Autoload。
- 修改主场景。
- 修改渲染器、显示、导出、物理层等项目级配置。

修改后必须说明：改了哪个配置项、为什么、如何验证、是否影响桌面或 Web 导出。

---

## 7. 临时文件规则

临时实验文件统一放：

```text
scenes/test/
tools/
assets/source/_scratch/
```

正式完成后要么删除，要么迁移到正式目录。

禁止把 AI 生成的临时图片、测试场景、一次性脚本混入正式目录而不标记。
