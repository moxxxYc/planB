# 进度与决策日志

**最后更新：** 2026-06-04
**仓库状态：** 纯文档态，无当前正式实现。

## 当前正式文档

- `README.md`
- `AGENTS.md`
- `docs/concept.md`
- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `docs/battlefield-rules.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/mvp-scope.md`
- `docs/PROGRESS.md`

旧方向、过时计划、历史 artifacts 和旧 prototype 已归档到 `docs/archive/`，不作为当前正式规则。

## 当前总状态

- 旧 Web MVP、旧脚本、旧验证命令和旧实现假设都不再作为当前设计依据。
- 旧 Godot prototype 已归档到 `docs/archive/prototypes/`，完全过期，不再作为 build、验证、评审或路由信号。
- 当前优先级是基础机制，不是具体种族内容。
- 球机主系统是 `Launch / Tuning / Unit`。
- Tuning 基础槽是 `Gate / Prime / Echo / Surge`。
- 战场方向是两端基地圈、三条固定路径、自动单位接战。
- 战中基础输入是 `Deploy Lane`。
- `Overdrive` 不属于 MVP 基础按钮。
- Guardian 是固定基地对象，也可以作为开局构筑锚点，但不是第四主系统。
- Guardian 的战术技能和战略技能在单局开始后固定，不解锁、不升级、不换状态。
- Guardian 宝物槽记录为 MVP 后扩展，不进当前 MVP。

## 2026-06-02

- 删除旧 Web MVP 方向的实现和验证假设。
- 重写 GDD 为纯文档态正式设计来源。
- 确认旧 `Standby / decision / Gold / Magic / Upgrade` 等实现术语不再是正式设计。

## 2026-06-03

- 从 Three-Axis Readability Battle Lab 转向完整短局 MVP。
- 确认三仓方向：
  - `Launch` 管输入量、发射节奏、路线倾向、回流、污染。
  - `Tuning` 管 `Gate / Prime / Echo / Surge` 转换质量。
  - `Unit` 管槽位、进度、队列、部署节奏。
- 确认 `Gate` 是最宽普通 Unit 入口，`Prime / Echo / Surge` 是奖励槽。
- 确认 `Launch Route Board`，已发射球不保证有效进入 Unit。
- 拆出 `docs/machine-warehouses.md`。
- 确认基础 Pool 目标：
  - Pool 容量 5。
  - Forge 约 2.2s 造 1 球。
  - Launcher 约 1.3s 发 1 球。
  - Pool 通常 2-4 / 5。
- 确认第一版 Route Board 倾向：
  - Tuning 路径 65%。
  - Split 15%。
  - Miss + Recycle 15%。
  - Waste 5%。
- 确认第一版 Tuning 槽宽倾向：
  - Gate 55%。
  - Prime 15%。
  - Echo 15%。
  - Surge 15%。
- 确认 Unit 4 个中立激活槽。
- 确认 Unit 队列 FIFO，每 0.5s 最多部署 1 个条目。
- 确认 `Surge` 只加速触发它的 entry，目标部署延迟 0.25s。
- 用 `Deploy Lane` 替代基础 `Overdrive` 按钮。
- 确认 `Left / Mid / Right` 三路。
- 确认 `Deploy Lane` 只改变部署位置，不改变机器产出。
- 拆出 `docs/mvp-scope.md`。

## 2026-06-04

- 确认战场不是压力条，而是真实单位自动战斗。
- 确认基础战场拓扑：
  - 两个基地圈。
  - 三条固定路径。
  - 每边每路一个 `Lane Gate / portal`。
  - 路径视觉可弯，规则上按有序路径处理。
- 确认单位基础战斗：
  - 同路移动。
  - 同路最近目标。
  - 自动攻击、受伤、死亡、继续推进。
- 确认路线状态应读出推进、僵持、漏兵。
- 确认 `Lane Gate` 是固定 HP blocker，不是建筑系统或塔防层。
- 确认 `Player Guardian`：
  - 固定基地对象。
  - 有 HP、基础攻击、战术技能槽、战略技能槽。
  - 不移动、不寻路、不离开基地圈、不打敌方 Guardian、不接受直接操作。
- 确认终点 Guardian 使用 `Telegraphed Sweep`：
  - 每 8-10s 预警。
  - 选择入侵单位最多的基地接触区。
  - 范围伤害。
  - 沿路短击退。
  - 不跨路、不眩晕、不减速、不复杂寻路。
- 确认 Guardian 通用构筑规则：
  - MVP 第一版使用 2 个可选 `Player Guardian`。
  - 两个 Guardian 都属于同一个正式种族。
  - 具体身份、名称、技能和数值延后到第一种族设计阶段。
  - 战术技能固定。
  - 战略技能固定。
  - 战略技能必须走 Machine Contract。
  - 不能成为第四机器轴。
- 确认 Guardian 宝物槽只作为 MVP 后扩展记录：
  - 1 个槽。
  - 单局内获得宝物。
  - 只能战前换。
  - 效果走 Machine Contract。
  - 不进 MVP。
- 重新整理中文文档结构：
  - `docs/gdd.md` 只保留总设计。
  - `docs/machine-warehouses.md` 只保留三仓机器。
  - 新增 `docs/battlefield-rules.md`。
  - 新增 `docs/guardian-system.md`。
  - `docs/mvp-scope.md` 只保留 MVP 范围。
  - `docs/PROGRESS.md` 压缩为决策日志。
- 将旧方向、过时计划和历史 skill 产物统一移动到 `docs/archive/`。
- 锁定基础战场结算 1.0：
  - 三路使用 `0-100` 标准化路径坐标。
  - 玩家基地圈接触区为 `0-8`，敌方基地圈接触区为 `92-100`。
  - 单位同路移动、同路接战、清空接战后继续推进。
  - Gate 被打破后本场保持打破状态。
  - 破敌方 Gate 后进入敌方基地圈攻击 Endpoint Guardian。
  - 破玩家侧 Gate 后敌方单位进入玩家基地圈攻击 `Player Guardian`。
- 锁定第一版战场调试数值：
  - 参考单位 HP 10，攻击 2 / 1.0s，速度 8 路径单位/s。
  - Lane Gate HP 60。
  - Player Guardian HP 100。
  - 普通战斗 Endpoint Guardian HP 120。
  - 终点战 Endpoint Guardian HP 180。
  - Guardian 基础攻击 5 / 1.5s。
  - Telegraphed Sweep 每 9s，1.2s 预警，8 伤害，8 路径单位击退。
  - 正常战斗目标 90-150s，终点战目标 150-210s。
- 新增 `docs/enemy-rules.md`。
- 锁定敌人波次和反制 1.0：
  - 普通战斗目标 90-150s。
  - 普通战斗最多同时使用 2 个敌方模板，终点战最多使用 3 个。
  - 普通战斗最多启用 1 个反制家族。
  - 反制首次出现目标为战斗开始后 25-40s。
  - 反制预警 3-5s，活跃 12-20s。
  - `Pool Polluter` 预警 4s，插入 Junk Ball，活跃期最多追加 2 次。
  - `Echo Breaker` 预警 4s，活跃期内下一次 Echo 复制降级为普通 Gate 结算。
  - `Stagger Punisher` 监测 4s 无部署，预警 3s，在危险路线生成 2 个 `Enemy Raider`。
- 新增 `docs/deploy-lane-ui.md`。
- 锁定 `Deploy Lane` 直接点路、选中高亮和路线危险提示 1.0：
  - 玩家直接点击战场上的 `Left / Mid / Right` 路线。
  - 点到哪条路，哪条路就成为当前出兵路线。
  - 当前选中路线高亮。
  - 没有切路冷却。
  - 没有待切路线。
  - 普通队列条目在部署节拍读取当前选中路线。
  - 路线危险分 0-3 四档：安全、压力、破门风险、漏兵/入侵。
  - 危险提示只来自可见战场状态和已公开波次/反制预警，不读隐藏压力值，不自动切路。
- 将根目录 `prototype/three_axis_readability_battle_lab/` 移入 `docs/archive/prototypes/`。
- 确认该旧 prototype 完全过期，后续不再读取它来判断当前状态、设计方向或实现计划。

## 当前未定

- 两个 Guardian 的具体身份、名称、技能和数值。
- 第一批中立修正清单。
- 第一种族单位模板、Guardian、技能和数值。

## 下一步

下一步仍是设计，不是实现：

1. 写第一批中立修正清单。
2. 基础机制完成后，再进入第一种族设计。
3. 只有设计文档稳定后，才创建新的实现计划。
