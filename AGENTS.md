## 项目状态

当前仓库是文档主导的 Godot MVP 项目。`mvp/` 是当前 Godot MVP v0 实现目录；正式设计来源仍在根目录和 `docs/` 下。旧 Web MVP、旧 Battle Lab、归档 prototype、归档生成资源、旧包脚本、旧验证探针和项目内旧本地技能在 2026-06-02 后不再作为当前方向的依据。

当前正式文档：

- `README.md`
- `docs/concept.md`
- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `docs/battlefield-rules.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/mvp-learning-checkpoints.md`
- `docs/mvp-scope.md`
- `docs/mvp-hive-loadout.md`
- `docs/rewards-economy.md`
- `docs/DESIGN.md`
- `docs/PROGRESS.md`
- `AGENTS.md`

当前候选与实现输入：

- `docs/ball-machine-physical.md`：MVP v0 实现输入。记录球机物理表现层候选草案（模型 A 真物理、三仓三块串联钉板结构，`Peglin` 仅作为结构参考、摆动炮台、override 物理化、左右分屏、同屏信息层级、物理反馈语法和灰阶可读规则）。叠加在 `docs/machine-warehouses.md` 逻辑之上，不改其规则。当前可作为 MVP v0 handoff / 实现假设；具体物理参数和各效果物理表现未定，未 playtest，未最终锁定为长期 canon。

`docs/archive/` 是旧方向、过时计划、历史 skill 产物、旧 prototype 和旧实现假设的归档目录。除非被正式文档明确引用为当前规则，否则只当作背景材料。

`docs/archive/prototypes/three_axis_readability_battle_lab/` 已完全过期。不要把它当作当前 build artifact，不要用它触发 `BUILDING` / `SHIPPING` 路由，也不要为了判断当前设计主动读取它。

## 协作要求

要求保持客观公正，不要献媚，不要敷衍。

- 不要发明缺失玩法、实现状态、内容表或生产进度。
- 未定事项必须标记为未定，不要用合理猜测补齐。
- 不要恢复旧 Web MVP 或旧 Battle Lab 的实现假设。
- 不要把归档 prototype 当作实现证明、验证命令来源或当前计划输入。
- 如果未来进入实现，必须从当前正式文档重新写有范围约束的实现计划。
- 任何真正开发前必须先获得用户明确确认。未经确认，不得创建、修改或恢复代码、资源、构建脚本、验证脚本、Godot/Web prototype 或其他实现文件；只能读取上下文、分析问题、提出候选方案、写用户明确要求的文档约束。
- 优先长期清晰的项目结构，不为了表面连续性保留错误旧术语。

## 游戏设计技能和原型流程要求

- 游戏设计、GDD、玩法规则、经济、平衡、UI 手感、种族、Guardian、奖励、商店、敌人、战场规则相关工作，默认走项目的 gstack-game 技能链路；但快速验证场景可以先走轻量 Fast Prototype Lane，不强制完整评审链路。
- 不要用 Superpowers 或通用 brainstorming 代替 gstack-game 的设计技能，除非用户明确要求进入工程实现、代码计划或通用软件开发流程。
- 涉及玩法 canon 的新增、删改或锁定，必须先通过 gstack-game 设计流程提出候选、说明取舍，并等待用户确认。
- 未经确认的设计内容只能标记为候选草案、假设或待确认，不能写成“已锁定”“正式规则”或实现输入。
- 如果技能规则冲突，游戏设计场景下以 gstack-game 技能和本文件为准。
- Fast Prototype Lane 只用于快速验证，不直接产生正式 canon。进入该 lane 时先给出一句话验证假设、最小 playable slice、哪些内容是假数据 / 假 UI / 假平衡，以及退出判断；用户确认后才能开始实现。
- Formal Design Lane 用于锁 canon、更新正式 GDD、决定长期系统、进入正式 Godot 实现计划或做 review / gate 结论。

## Godot 开发技能优先级

- 开发 Godot 相关功能时，优先加载 GodotPrompter 的 Godot skills。
- 涉及需求澄清、规格、实现计划、测试策略、代码审查时，使用 Superpowers 的流程。
- 如果 GodotPrompter 和 Superpowers 的建议冲突，先以项目已有 `docs/` 和现有代码为最高优先级。
- 在项目已有 `docs/` 和现有代码没有明确约束的范围内，Godot API、场景树、资源、GDScript/C# 写法，以 GodotPrompter 为准。
- 在项目已有 `docs/` 和现有代码没有明确约束的范围内，任务拆解、实现顺序、测试和 review 流程，以 Superpowers 为准。
- 以上技能优先级不能绕过用户确认门槛；真正开发前仍必须等待用户明确确认。

## 文档权威顺序

- `docs/gdd.md`：总设计与跨系统边界。
- `docs/machine-warehouses.md`：三仓机器规则。
- `docs/battlefield-rules.md`：基础战场规则。
- `docs/enemy-rules.md`：敌人波次与机器反制规则。
- `docs/deploy-lane-ui.md`：`Deploy Lane` 直接点路、选中高亮和路线危险提示。
- `docs/guardian-system.md`：Guardian 通用系统规则。
- `docs/mvp-learning-checkpoints.md`：MVP 玩家学习检查点、验收信号和失败信号。
- `docs/mvp-scope.md`：第一版 MVP 内容边界。
- `docs/mvp-hive-loadout.md`：MVP v0 的 Hive 单位、Guardian、职责带和起始配置。
- `docs/rewards-economy.md`：MVP v0 的奖励、商店、Gold、休整和中立修正候选。
- `docs/DESIGN.md`：MVP v0 美术风格、资源生产约束和视觉反馈规范；不改写玩法规则。
- `docs/PROGRESS.md`：近期决策日志，不是实现证明。

候选草案不参与文档权威顺序，除非用户确认后再提升为正式规则。MVP v0 实现输入可以指导当前 `mvp/` 构建，但不自动提升为长期 canon。

如果文档冲突，先以更具体的规则文档为准，再更新 GDD 和 PROGRESS 消除冲突。

## 设计边界

- 球机必须是主系统。
- 不做 PVP、联网、账号、后端服务、匹配、Steam 集成。
- 战场不是自由 RTS 地图。
- 不把复杂 RTS 寻路作为核心需求。
- 不允许直接操作已部署单位。
- 正式机器术语是 `Launch / Tuning / Unit`。
- 正式 Tuning 基础槽是 `Gate / Prime / Echo / Surge`。
- `Gold / 金币` 主要来自战后结算。
- `Overdrive` 不属于 MVP 基础按钮。
- 种族、Guardian、遗物、商店、事件都必须服务 `Launch / Tuning / Unit`，不能替代球机。

## 工作流

- 总方向变更：更新 `docs/gdd.md` 和 `docs/PROGRESS.md`。
- 机器规则变更：更新 `docs/machine-warehouses.md` 和 `docs/PROGRESS.md`。
- 战场规则变更：更新 `docs/battlefield-rules.md` 和 `docs/PROGRESS.md`。
- 敌人波次或反制变更：更新 `docs/enemy-rules.md` 和 `docs/PROGRESS.md`。
- `Deploy Lane` UI 或选路规则变更：更新 `docs/deploy-lane-ui.md` 和 `docs/PROGRESS.md`。
- Guardian 通用规则变更：更新 `docs/guardian-system.md` 和 `docs/PROGRESS.md`。
- MVP 学习检查点变更：更新 `docs/mvp-learning-checkpoints.md` 和 `docs/PROGRESS.md`。
- Hive MVP loadout 变更：更新 `docs/mvp-hive-loadout.md` 和 `docs/PROGRESS.md`。
- 奖励、商店、Gold、休整或中立修正候选变更：更新 `docs/rewards-economy.md` 和 `docs/PROGRESS.md`，精确 playtest 后最终平衡仍需标明未定。
- MVP 范围变更：更新 `docs/mvp-scope.md` 和 `docs/PROGRESS.md`。
- 美术风格、资源生产或视觉反馈规范变更：更新 `docs/DESIGN.md` 和 `docs/PROGRESS.md`。
- 实现工作开始前：先创建新的实现计划，不引用已删除实现；计划必须等待用户明确确认后才能执行。
- 如果发现归档 prototype 或归档实现文件，默认忽略；只有用户明确要求考古时才读取。
- 当前仓库没有 npm 命令、构建命令或自动验证命令。
