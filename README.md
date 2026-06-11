# planB

planB 当前是文档主导、Godot 实现已重新启动的 MVP 项目。正式设计来源仍在根目录和 `docs/` 下；原 `mvp/` Godot MVP v0 实现已在 2026-06-11 归档到 `docs/archive/implementations/godot-mvp-v0-20260611/`。

当前阶段：MVP v0 M0-M1 活动实现。当前活动 Godot 工程位于 `godot/`，当前验证命令是 `bash tools/verify_godot.sh`。M0-M1 之外的新里程碑、范围扩展或玩法 canon 变更，必须先从正式文档重新写有范围约束的实现计划，并等待用户明确确认。

## MVP 实现状态

- `godot/`：当前活动 Godot MVP 工程。M0 建立 fresh project、Main Menu 和验证入口；M1 建立 Battle 1 vertical，证明机器结果到 Queue 再到选中路线出兵口的基础因果链。
- `tools/verify_godot.sh`：当前主验证入口。
- `mvp/`：旧实现路径已归档，不再作为活动实现或当前 build artifact。
- `docs/archive/implementations/godot-mvp-v0-20260611/`：已归档的旧 Godot MVP v0 实现。它不是当前 build artifact，不是验证命令来源，也不能作为新实现的默认结构依据。
- `docs/archive/prototypes/` 不是当前实现来源，不要从旧 prototype 恢复代码或验证假设。

## 当前文档

- `docs/concept.md`：中文概念一页纸。
- `docs/gdd.md`：总设计文档，只放高层方向和跨系统边界。
- `docs/machine-warehouses.md`：`Launch / Tuning / Unit` 三仓机器规则。
- `docs/battlefield-rules.md`：三路战场、单位战斗、门、基地与 Guardian 的基础规则。
- `docs/enemy-rules.md`：敌人波次、机器反制预警和反制生效规则。
- `docs/deploy-lane-ui.md`：`Deploy Lane` 直接点路、选中高亮和路线危险提示。
- `docs/guardian-system.md`：Guardian 通用系统规则，不放具体种族 Guardian。
- `docs/mvp-learning-checkpoints.md`：MVP 玩家学习检查点、验收信号和失败信号。
- `docs/mvp-scope.md`：第一版完整 MVP 的内容边界。
- `docs/mvp-hive-loadout.md`：MVP v0 的 Hive 单位、Guardian、职责带和起始配置。
- `docs/rewards-economy.md`：MVP v0 的奖励、商店、Gold、休整和中立修正候选。
- `docs/DESIGN.md`：已确认的 MVP v0 美术风格、资源生产约束和视觉反馈规范。
- `docs/PROGRESS.md`：近期决策日志与下一步。
- `AGENTS.md`：协作规则和文档权威顺序。

## 候选与实现输入

- `docs/ball-machine-physical.md`：MVP v0 实现输入。记录球机物理表现层候选草案（模型 A 真物理、三仓三块串联钉板结构，`Peglin` 仅作为结构参考、摆动炮台、override 物理化、左右分屏、同屏信息层级、物理反馈语法和灰阶可读规则）。它可作为当前 MVP v0 handoff / 实现假设，但具体物理参数和各效果物理表现未定，未 playtest，未最终锁定为长期 canon。

## 归档内容

- `docs/archive/`：旧方向、过时计划、历史 skill 产物和旧实现假设的归档目录。
- `docs/archive/implementations/godot-mvp-v0-20260611/`：2026-06-11 归档的旧 Godot MVP v0 实现。

归档内容不是当前正式设计，除非被上述正式文档明确重新提升。
`docs/archive/prototypes/three_axis_readability_battle_lab/` 已完全过期，不再作为构建、验证、评审或路由依据。

## 项目意图

玩家从一个不稳定的物理出兵机器开始，通过奖励、商店、事件、种族机制、敌人干扰和战场选择，逐步把 `Launch / Tuning / Unit` 某个机器方向推成可读的前线优势。

核心不是买数值，也不是直接操作单位。核心是：

> 玩家能否看出本局该放大哪条机器轴，做出构筑承诺，并在三路自动战斗中看到这个承诺转化成真实战果。

## 当前状态

- 原 `mvp/` Godot MVP v0 实现目录已归档；当前活动实现目录是 `godot/`。
- 当前 MVP 工程目标是 Godot 4.6、GDScript、Compatibility / `gl_compatibility` 渲染路径。
- 当前可运行的 Godot MVP 主验证命令是 `bash tools/verify_godot.sh`。归档目录里的旧验证脚本只作历史背景，不作为当前验收入口。
- 旧 Web MVP 和旧 Godot Battle Lab 假设都不能直接恢复为当前设计。
- 旧 Godot prototype 已归档，不需要也不应该参与未来上下文扫描。
- 正式机器术语是 `Launch / Tuning / Unit`。
- 正式 Tuning 基础槽是 `Gate / Prime / Echo / Surge`。
- 当前基础战斗方向是两端基地圈、三条固定路径、自动单位接战、`Deploy Lane` 选择。
- `Overdrive` 不是 MVP 基础按钮，只能以后作为命名构筑、遗物、事件或种族规则回归。
