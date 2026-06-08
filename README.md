# planB

planB 当前仍没有可运行实现、包脚本、生成资源或自动验证链。正式设计来源仍在根目录和 `docs/` 下；MVP v0 实现将在 `mvp/` 下开始。

## MVP 开发目录

- `mvp/`：MVP v0 的当前实现目录。MVP 阶段的工程代码、场景、配置和验证入口都应放在这个目录下。
- `mvp/.gitkeep`：空目录占位文件，便于在尚未创建工程文件前提交目录。
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
- `docs/PROGRESS.md`：近期决策日志与下一步。
- `AGENTS.md`：协作规则和文档权威顺序。

## 候选草案

- `docs/neutral-modifiers.md`：记录已确认的中立奖励 / 商店结构、Gold faucet、价格带、职责带平衡口径和休整结果页口径。精确 playtest 后最终平衡未确认。
- `docs/ball-machine-physical.md`：记录球机物理表现层候选草案（模型 A 真物理、三仓三块串联钉板结构，`Peglin` 仅作为结构参考、摆动炮台、override 物理化、左右分屏、同屏信息层级、物理反馈语法和灰阶可读规则）。具体物理参数和各效果物理表现未定，未 playtest，未最终锁定。

## 归档内容

- `docs/archive/`：旧方向、过时计划、历史 skill 产物和旧实现假设的归档目录。

归档内容不是当前正式设计，除非被上述正式文档明确重新提升。
`docs/archive/prototypes/three_axis_readability_battle_lab/` 已完全过期，不再作为构建、验证、评审或路由依据。

## 项目意图

玩家从一个不稳定的物理出兵机器开始，通过奖励、商店、事件、种族机制、敌人干扰和战场选择，逐步把 `Launch / Tuning / Unit` 某个机器方向推成可读的前线优势。

核心不是买数值，也不是直接操作单位。核心是：

> 玩家能否看出本局该放大哪条机器轴，做出构筑承诺，并在三路自动战斗中看到这个承诺转化成真实战果。

## 当前状态

- 仓库当前无实现代码作为正式来源。
- 旧 Web MVP 和旧 Godot Battle Lab 假设都不能直接恢复为当前设计。
- 旧 Godot prototype 已归档，不需要也不应该参与未来上下文扫描。
- 正式机器术语是 `Launch / Tuning / Unit`。
- 正式 Tuning 基础槽是 `Gate / Prime / Echo / Surge`。
- 当前基础战斗方向是两端基地圈、三条固定路径、自动单位接战、`Deploy Lane` 选择。
- `Overdrive` 不是 MVP 基础按钮，只能以后作为命名构筑、遗物、事件或种族规则回归。
