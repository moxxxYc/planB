# MVP 范围

**最后更新：** 2026-06-09
**仓库状态：** 文档主导，当前活动 MVP v0 实现目录为 `godot/`；本文不作为代码状态证明。
**权威范围：** 第一版完整 MVP 的内容边界。

本文只回答第一版 MVP 做什么、不做什么。具体系统规则和配置见：

- `docs/machine-warehouses.md`：三仓机器规则。
- `docs/battlefield-rules.md`：基础战场、单位接战、基地圈和胜负结算。
- `docs/enemy-rules.md`：敌人波次、反制家族和终点战压力。
- `docs/deploy-lane-ui.md`：`Deploy Lane` 直接选路和路线危险提示。
- `docs/guardian-system.md`：Guardian 通用机制。
- `docs/mvp-hive-loadout.md`：Hive 单位、Guardian、职责带和起始配置。
- `docs/rewards-economy.md`：奖励、商店、Gold、休整和中立修正候选。
- `docs/mvp-learning-checkpoints.md`：学习目标、验收信号、结果页字段和失败观察。

## 1. MVP 目标

MVP 是 15-20 分钟的短完整局，不是 Steam 试玩、Itch 试玩、正式发布版本或生产级垂直切片。

它要回答：

> 一个短局能否证明三仓球机、三路自动战斗、`Deploy Lane`、奖励/商店、反制和终点战共同形成可读的会话循环？

MVP 失败条件：

- 玩家只能说“我造了更多兵”。
- 玩家只能说“我点对了路线”。
- 玩家说不出机器轴如何改变战场。

## 2. 硬范围上限

| 项目 | MVP 上限 |
|---|---:|
| 正式种族 | 1 |
| 第一种族方向 | Hive / `Caste Hive`，具体 loadout 见 `docs/mvp-hive-loadout.md` |
| 战斗数 | 默认 6，最多 8 |
| 目标时长 | 15-20 分钟 |
| 机器构筑方向 | 3 |
| 奖励/商店实际使用效果 | 最多 9 |
| 反制家族 | 3 |
| 终点战 | 1 |
| 基础战场路线 | 3 |
| 可选 Player Guardian | 2 |
| 局外成长 | 0 |
| 第二种族 | 0 |
| 完整遗物池 | 0 |
| 完整事件池 | 0 |

不能用扩内容解决不可读。不可读时先减少内容或加强反馈。

## 3. 必须包含的会话循环

线性路线即可，不需要节点地图。

1. 新手引导战斗。
2. 第一次奖励。
3. 第二场战斗验证机器方向。
4. 商店。
5. 反制战斗。
6. Battle 4 后给第二次奖励，用于主轴深化或补洞；不开第二次商店。
7. 终点战。
8. 胜负结算。

## 4. 必须包含的系统

### 机器

使用 `docs/machine-warehouses.md` 的基础规则：

- `Launch`：Forge、Pool、Launcher、Route Board、Split、Recycle、Waste、Junk。
- `Tuning`：Gate、Prime、Echo、Surge。
- `Unit`：4 个独立单位槽、左到右低需求到高需求、`Unit.Slot.Exposure Gate`、进度、队列、部署节拍。
- `Deploy Lane`：直接点击 `Left / Mid / Right` 战场路线，当前选中路线高亮。

MVP 机器主题采用通用规则和种族化球机表现。种族不能替换 `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Unit slot`、`Queue` 或 `Deploy Lane` 的通用语义。Hive 具体包装、单位和 Guardian 见 `docs/mvp-hive-loadout.md`。

`Overdrive` 不属于 MVP 基础按钮。

### 战场、敌人和路线

战场使用 `docs/battlefield-rules.md` 的基础规则：两个基地圈、三条固定路径、每边每路一个 Lane Gate、单位真实接战、推进/僵持/漏兵可读、固定基地 Guardian 和终点 Guardian。

敌人和反制使用 `docs/enemy-rules.md` 的基础规则：普通战斗目标 90-150s，终点战目标 150-210s，普通战斗最多启用 1 个反制家族，单局根据玩家主轴看到 1-2 个反制家族，不要求一局塞满三类。

路线选择和危险提示使用 `docs/deploy-lane-ui.md` 的基础规则：直接点击战场路线选择出兵路线；当前选中路线高亮；没有切路冷却，没有待切路线；路线危险使用 0-3 四档提示，不自动切路。

### Guardian 和 Hive

Guardian 通用规则见 `docs/guardian-system.md`。MVP 第一版使用 2 个可选 `Player Guardian`，选择发生在第一场战斗前，选择后整局固定；战术技能和战略技能固定，战略技能走 Machine Contract。

Hive 具体 `Unit slot`、`Player Guardian`、`Guardian Contract`、第一版属性起点和职责带调参口径见 `docs/mvp-hive-loadout.md`。

### 奖励、商店和经济

MVP 中实际使用的奖励/商店效果最多 9 个。第一次奖励、第一次商店、`Echo Latch` 位置、第二次奖励主轴优先池、Gold faucet、价格带、职责带平衡口径和休整结果页口径见 `docs/rewards-economy.md`。

## 5. MVP 构筑方向

MVP 至少要验证三种机器结果读法：

| 读法 | 机器轴 | 战场表现 |
|---|---|---|
| 持续流 | `Launch` | 稳定补兵、持续压线、减少断档。 |
| 重复重击 | `Tuning` | 少量高价值结算造成重复击穿或扩散。 |
| 批量冲锋 | `Unit` | 蓄力后成批部署，翻转某一路。 |

Hive MVP 不为 `Launch / Tuning / Unit` 三条机器轴设置副名；构筑读法通过虫壳、酸液、巢脉材质、图标风格、组件外观、运动反馈和命名效果表达。未来种族如何命名和包装这些读法另行确认。

## 6. 敌人和终点战

敌人范围：

- 3 个反制家族。
- 2-3 个普通敌人或波次脚本即可。
- 不做完整敌人表。
- 不做完整 Boss 阵容。

终点战范围：

- 1 个终点战。
- 必须测试机器轴是否能转成战场优势。
- 使用固定终点 Guardian。
- 不能只是高 HP 木桩。

## 7. 结算页

MVP 结果页可以文字较重，但必须帮助玩家复盘：

- 本局主要机器方向。
- 关键奖励/商店选择。
- 主要反制攻击了什么。
- `Deploy Lane` 如何影响战场落点。
- 终点战如何测试构筑。
- 胜负原因。
- 失败时的 `main_break_reason` 和 `next_run_watch_tag`。

具体学习验收、失败信号、结果页记录字段和失败观察方式见 `docs/mvp-learning-checkpoints.md`。

## 8. 可以假做

- 美术：原始占位图形、剪影、简单路径。
- 动画：移动、攻击、死亡、击退的基础反馈即可。
- UI：可读原型 UI。
- 事件：无，或一个脚本事件。

不能假做：

- 完整单局循环。
- 三仓机器因果。
- 三种构筑读法。
- 三路自动战斗。
- 反制预警和干扰。
- 终点战验证。
- 结果解释。

## 9. 明确不做

- 第二种族。
- 完整 Hive 大内容包，MVP 只做第一种族最小可读内容。
- Mech / Arcane 实现。
- 完整遗物池。
- 完整事件池。
- 局外成长。
- 挑战层级。
- 完整 Boss 阵容。
- 大型敌人表。
- 单位配装选择。
- Guardian 宝物槽。
- Guardian 装备、升级、局外养成、主动指令。
- 建筑系统。
- 自由 RTS 地图。
- 复杂 RTS 寻路。
- 直接单位控制。
- 基础 `Overdrive` 按钮。
- Steam、账号、后端、联网、PVP。

## 10. 成功标准

MVP 成功时：

- 一个完整短局能在 15-20 分钟内胜利或失败。
- 玩家能说出本局主要强化的是 `Launch / Tuning / Unit` 哪条轴。
- 玩家能说出某次奖励/商店改了哪个机器组件。
- 玩家能看出反制攻击的是 Pool、Echo 窗口或队列空档。
- 玩家能从单位战斗看出某路正在推进、僵持或漏兵。
- 玩家能解释 `Deploy Lane` 改变了部署位置，而不是替代机器构筑。
- 玩家能说出终点战为什么赢或输。
- 两个 `Player Guardian` 都有人愿意选，且没有明显超过软护栏的成功率差距。
- 4 个 Unit slot 都有可见贡献路径，关键 queue entry 没有长期被单一 slot 吞掉。
- 玩家不会连续两场只是在看球掉，而说不出自己的选择或等待的兑现结果。
- 最优观察策略不是永远买 Unit。
- 最优观察策略不是只点最危险路线然后忽略球机。
- `docs/mvp-learning-checkpoints.md` 的 6 个关键节点都有可观察验收信号。

MVP 第一轮 playtest 使用软阈值护栏，不把它当最终平衡：10-20 局后，任一 Guardian 选择率低于 30% 或成功率差距超过 15 个百分点，需要回查可读性、吸引力或强度；非 `Slot Primer / Unit` 构筑下，单一 Unit slot 不应长期占据 60% 以上关键 queue entry；不允许连续 2 场战斗只有自动播放而没有可解释选择、反制、兑现提示或结果页复盘点。

## 11. 下一批范围问题

1. 新实现计划开始前，把完整 MVP 的实现输入边界补齐。
2. 如实现需要，再收束 `Unit.Slot.Exposure Gate` 暴露插值方式。
