## 项目状态

当前仓库是纯文档态。旧实现、生成资源、包脚本、验证探针和项目内本地技能在 2026-06-02 后不再作为当前方向的依据。

当前正式文档：

- `README.md`
- `docs/concept.md`
- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `docs/battlefield-rules.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/mvp-scope.md`
- `docs/PROGRESS.md`
- `AGENTS.md`

`docs/archive/` 是旧方向、过时计划、历史 skill 产物、旧 prototype 和旧实现假设的归档目录。除非被正式文档明确引用为当前规则，否则只当作背景材料。

`docs/archive/prototypes/three_axis_readability_battle_lab/` 已完全过期。不要把它当作当前 build artifact，不要用它触发 `BUILDING` / `SHIPPING` 路由，也不要为了判断当前设计主动读取它。

## 协作要求

要求保持客观公正，不要献媚，不要敷衍。

- 不要发明缺失玩法、实现状态、内容表或生产进度。
- 未定事项必须标记为未定，不要用合理猜测补齐。
- 不要恢复旧 Web MVP 或旧 Battle Lab 的实现假设。
- 不要把归档 prototype 当作实现证明、验证命令来源或当前计划输入。
- 如果未来进入实现，必须从当前正式文档重新写有范围约束的实现计划。
- 优先长期清晰的项目结构，不为了表面连续性保留错误旧术语。

## 文档权威顺序

- `docs/gdd.md`：总设计与跨系统边界。
- `docs/machine-warehouses.md`：三仓机器规则。
- `docs/battlefield-rules.md`：基础战场规则。
- `docs/enemy-rules.md`：敌人波次与机器反制规则。
- `docs/deploy-lane-ui.md`：`Deploy Lane` 直接点路、选中高亮和路线危险提示。
- `docs/guardian-system.md`：Guardian 通用系统规则。
- `docs/mvp-scope.md`：第一版 MVP 内容边界。
- `docs/PROGRESS.md`：近期决策日志，不是实现证明。

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
- MVP 范围变更：更新 `docs/mvp-scope.md` 和 `docs/PROGRESS.md`。
- 实现工作开始前：先创建新的实现计划，不引用已删除实现。
- 如果发现归档 prototype 或归档实现文件，默认忽略；只有用户明确要求考古时才读取。
- 当前仓库没有 npm 命令、构建命令或自动验证命令。
