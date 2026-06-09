# MVP 学习检查点

**最后更新：** 2026-06-08
**仓库状态：** 文档主导，MVP v0 实现已在 `mvp/` 启动；本文不作为代码状态证明。
**权威范围：** 第一版 MVP 的玩家学习目标、验收信号和失败信号。

本文不定义新系统，不替代 `docs/mvp-scope.md`。本文只回答：MVP 每个关键节点要让玩家学会什么，以及怎么判断玩家没有学会。

## 1. 设计目的

MVP 不是内容展示，也不是数值平衡测试。MVP 第一版要证明：

1. 玩家能读懂 `Launch / Tuning / Unit` 三条机器轴。
2. 玩家能把奖励、商店和敌人反制理解成机器组件变化，而不是随机 buff。
3. 玩家能在三路自动战斗里看到构筑承诺兑现或失败。
4. 玩家不会把 `Deploy Lane` 误读成主要玩法。

如果某个节点不能产生可观察学习信号，那个节点就不能支撑 MVP 开发。

## 2. 检查点总览

| 节点 | 玩家必须学会 | 验收方式 |
|---|---|---|
| Battle 1 前 30 秒 | 球机从造球到成兵的基础链路。 | 玩家能指出 Pool、Tuning、Unit 槽和当前 Deploy Lane。 |
| 第一次奖励 | 三个奖励分别代表 `Launch / Tuning / Unit`。 | 玩家能说出自己选的是哪条轴，以及战场期待是什么。 |
| 第一次商店 | 商店是补洞或转向，不是买泛用强度。 | 玩家能解释为什么只能认真买 1 个机器修正。 |
| 第一次反制 | 敌人正在攻击某个机器弱点。 | 玩家能指出反制攻击的是 Pool、Echo / Surge、还是队列空档。 |
| 第二次奖励 | 当前主轴开始成形，但仍需要补洞。 | 玩家能区分强化主轴和处理危险。 |
| 终点战 | 胜负来自机器轴兑现或断裂，不是只来自点路。 | 玩家能复盘赢或输的主要机器原因。 |

## 3. Battle 1 前 30 秒

### 玩家必须学会

- `Launch` 在造球、存球、发射。
- `Tuning` 在把 fired ball 结算成 `Gate / Prime / Echo / Surge`。
- `Unit` 槽从左到右是低需求到高需求，当前暴露区域决定球能落入哪个槽。
- `Unit` 槽在获得 progress，槽满后进入部署队列。
- `Deploy Lane` 只决定后续队列部署到哪一路，不改变机器产出。

### UI 最小反馈

| UI 元素 | 最小反馈 |
|---|---|
| Pool | 显示 `current / capacity`，每个球占一个可见槽。球进入和离开 Pool 必须有方向感。 |
| Forge | 显示下一颗球的生成进度，可以是环形进度或短条。 |
| Launcher | 显示发射节拍，发射瞬间必须能看出 fired ball 离开 Pool。 |
| Tuning | 显示 fired ball 本次命中的槽名：`Gate / Prime / Echo / Surge`。 |
| Unit slots | 4 个槽显示当前 progress 和 `progress_required`，并显示从低需求到高需求的顺序。第一版 baseline 为 `3 / 5 / 8 / 12`。获得 progress 时槽位闪一下或跳数。 |
| Slot Exposure Gate | 显示当前挡板 / 闸门位置、每个 slot 的暴露区域，以及球打到未暴露区域后会被弹开继续运动。Battle 1 前 30 秒应能看到 Slot 2 已完整暴露。 |
| Queue | 至少显示即将部署的下一个 queue entry。 |
| Deploy Lane | `Left / Mid / Right` 三路可点，当前选中路线高亮。 |
| Lane danger | 三路保留 0-3 档危险提示，但 Battle 1 可以只出现 0-1 档。 |

### 验收信号

玩家不需要懂完整规则，但必须能用自己的话说：

> 球先被机器造出来，经过调校，落到当前暴露的单位槽里，槽满后进入队列。点路只是决定单位去哪一路。

### 失败信号

- 玩家以为点路会改变造球速度或出兵数量。
- 玩家只盯着战场，不看机器。
- 玩家看不出 Unit 槽为什么增加 progress。
- 玩家以为被闸门弹开的球消失了，或者以为右侧槽是随机不能用。
- 玩家把 `Prime / Echo / Surge` 读成随机闪光。

## 4. 第一次奖励

第一次奖励已确认为 3 选 1：

- `Pool Pocket`
- `Prime Charge`
- `Slot Primer`

### 玩家必须学会

- `Pool Pocket` 代表 `Launch`：机器输入流更稳。
- `Prime Charge` 代表 `Tuning`：少数高价值命中更有分量。
- `Slot Primer` 代表 `Unit`：一个槽位整局始终领先一步。

### UI 最小反馈

| 奖励 | 最小反馈 |
|---|---|
| `Pool Pocket` | 卡面标记 `Launch`。说明显示 `Pool capacity +1`。选择后 Pool 增加一个槽位，并在槽位边缘显示本局修正标记。 |
| `Prime Charge` | 卡面标记 `Tuning`。说明显示 `Prime hit value +1 -> +2`。选择后 Prime 命中时显示更大的 hit 数字或更强反馈。 |
| `Slot Primer` | 卡面标记 `Unit`。说明显示 `Choose 1 Unit slot, progress floor = 1`。选择后目标 slot 常驻 floor 标记。 |

共同要求：

- 奖励卡必须显示 `warehouse -> component -> operation`。
- 奖励卡必须显示玩家读法，不只显示数值。
- 选择后，HUD 要出现本局已选奖励的小标记。

### 验收信号

玩家选择后能说：

> 我选了 Launch / Tuning / Unit，因为我想让本局变成稳定流 / 高价值命中 / 固定槽位成兵。

第一次奖励采用战场结果模型验收：

| 奖励 | 战场验收 |
|---|---|
| `Pool Pocket` | Battle 2-3 中，主压路线更少出现可见断档；玩家能把持续补线读成 `Launch sustained flow`。 |
| `Prime Charge` | Prime 命中后 4-6s 内，至少能看到一次路线状态变化或关键队列结果；玩家能把它读成 `Tuning high-value hit`，而不是隐藏数字。 |
| `Slot Primer` | 被选 Unit slot 在 Battle 2-5 中形成可见锚点；玩家能说出自己选了哪个槽，以及该槽单位怎样影响一路战场。 |

### 失败信号

- 玩家说“这个加兵更多”但说不出是哪条机器轴。
- 玩家把三项都理解成不同强度的通用 buff。
- 玩家选完后在战斗中找不到奖励生效位置。
- 玩家无法在战场上指出第一次奖励兑现出的 `Launch sustained flow`、`Tuning high-value hit` 或 `Unit anchor slot`。

## 5. 第一次商店

第一次商店候选池已确认为：

- `Front Recycle`
- `Junk Sieve`
- `Surge Buffer`
- `Queue Brace`
- `Muster Pair`

第一次商店实际出现在 Battle 2 后，展示 3 个中立修正，至少 1 个是补洞项。若 Battle 1 和 Battle 2 都是普通胜利，进入第一次商店时玩家通常有 12 Gold；第一版通过“第一次商店最多购买 1 个中立修正”控制信息量和买穿风险，剩余 Gold 用于休整或保留到后续节点。

### 玩家必须学会

- 商店不是买泛用强度。
- 商店里的每项都改某个机器组件。
- 补洞项处理当前风险，转向项改变构筑形状。
- 买休整会和机器修正竞争 Gold。

### UI 最小反馈

| UI 元素 | 最小反馈 |
|---|---|
| Gold | 显示当前 Gold。Battle 1 胜利后应显示 `6 Gold`；Battle 2 后进入第一次商店时，若前两战胜利，应显示 `12 Gold`。Battle 3 强反制胜利后增加 `8 Gold`；Battle 4 / Battle 5 / Endpoint 不再增加 Gold。 |
| 商品卡 | 每项显示价格、机器轴、目标组件和一句玩家读法。 |
| 补洞标签 | 补洞项显示 `Patch` 标签，并写明回应的危险，例如 `Pool pollution`、`Queue gap`。 |
| 转向标签 | 转向项显示 `Pivot` 标签，并写明它改变的构筑形状。 |
| 不足 Gold 状态 | 买不起的项置灰，但仍可读说明。 |
| 休整 | 只在 `Player Guardian` HP 受损且当前节点允许休整时出现，显示 `休整 3 Gold` 和 `restore 20 Player Guardian HP`。第一次商店和 Battle 3 反制战胜利后最多各 1 次；Battle 5 后的 Endpoint 前整备窗口最多 2 次。 |
| 购买后状态 | 已购买项标记 `Sold`，不可再次购买。 |
| 第一次商店购买额度 | 显示 `Neutral modifier purchase: 0 / 1` 或等价反馈。玩家买 1 个中立修正后，其他中立修正进入本次商店不可购买状态，但说明仍可读。 |

### 验收信号

玩家能说：

> 我现在有 12 Gold，但第一次商店只能买一个中立机器修正。剩下的 Gold 要么休整，要么留到后面；这个商店项是在处理我的 Pool / Tuning / Unit 问题。

### 失败信号

- 玩家把商店当成“便宜就全买”。
- 玩家不知道为什么买不了第二个中立修正。
- 玩家只比较价格，不理解机器组件差异。
- 玩家觉得休整和机器修正没有机会成本。

## 6. 第一次反制

MVP 当前反制家族：

- `Pool Polluter`
- `Echo Breaker`
- `Stagger Punisher`

### 玩家必须学会

- 敌人不是单纯变强。
- 反制在攻击某个机器弱点。
- 危险提示来自可见战场状态和已公开反制，不是隐藏数值。
- 商店和奖励提供的是机器层面的应对，不是直接削弱敌人。

### UI 最小反馈

| 反制 | 最小反馈 |
|---|---|
| `Pool Polluter` | 预警时高亮 Pool，并标记 incoming Junk。Junk 插入时必须显示进入哪个 Pool 槽。 |
| `Echo Breaker` | 预警时高亮 Tuning 的 Echo 区域。生效时显示 Echo copy 被降级为普通 Gate 结算。 |
| `Stagger Punisher` | 预警时高亮 Queue 空档和危险路线。生成 `Enemy Raider` 时显示来自队列空档惩罚。 |

共同要求：

- 反制预警必须显示倒计时或持续时长。
- 反制 UI 必须标出被攻击的机器组件。
- 可用补洞项必须和反制使用同一套标签语言，例如 `Pool pollution patch`、`Unit gap patch`。

### 验收信号

玩家能说：

> 这波敌人是在污染 Pool / 打断 Echo 或 Surge 价值 / 惩罚队列空档，所以我需要对应的机器补洞。

### 失败信号

- 玩家只觉得敌人突然变强。
- 玩家以为反制是随机事件。
- 玩家只想通过点危险路线解决问题。
- 玩家找不到补洞项和反制之间的关系。

## 7. 第二次奖励

第二次奖励固定在 Battle 4 后出现，不开第二次商店。它采用主轴优先池：

- 展示 2-3 个候选。
- 至少 1 个强化当前主轴。
- 至少 1 个补洞或转向。
- `Launch` 主轴优先 `Front Recycle`，外加 `Junk Sieve` 或跨轴补洞 / 转向项。
- `Tuning` 主轴优先 `Echo Latch`，外加 `Surge Buffer` 或跨轴补洞 / 转向项。
- `Unit` 主轴优先 `Muster Pair`，外加 `Queue Brace` 或跨轴补洞 / 转向项。

### 玩家必须学会

- 当前构筑有主轴。
- 主轴可以继续深化。
- 被反制暴露出来的洞需要处理。
- 转向不是放弃前面选择，而是让机器结构更完整。

### UI 最小反馈

| UI 元素 | 最小反馈 |
|---|---|
| 当前主轴提示 | 第二次奖励界面顶部显示当前主轴：`Current axis: Launch / Tuning / Unit`。 |
| 主轴强化项 | 至少一个候选带 `Deepen current axis` 标签。 |
| 补洞 / 转向项 | 至少一个候选带 `Patch` 或 `Pivot` 标签。 |
| 候选来源说明 | 候选下方显示为什么出现，例如 `Because you chose Slot Primer` 或 `Because Pool Polluter appeared`。 |
| `Echo Latch` | 只在第二次奖励里出现时显示 `Tuning deepen`，不显示为商店补洞项。 |

### 验收信号

玩家能说：

> 我现在主要是 Launch / Tuning / Unit，所以这个选择是在继续强化它，另一个选择是在补我刚才暴露出来的问题。

### 失败信号

- 玩家看不出系统为什么给这些候选。
- 玩家觉得候选是随机刷新。
- 玩家只买最贵或最便宜，不看机器语义。
- 玩家无法区分强化主轴和补洞。

## 8. 终点战

### 玩家必须学会

- 终点战不是高 HP 木桩。
- 终点战在测试本局机器轴是否能兑现为战场优势。
- `Deploy Lane` 可以影响落点，但不能代替机器构筑。
- 胜负要能复盘到 `Launch / Tuning / Unit` 的表现。

### UI 最小反馈

| UI 元素 | 最小反馈 |
|---|---|
| 终点 Guardian 威胁 | 显示 `Telegraphed Sweep` 预警范围、倒计时和命中路线 / 基地区域。 |
| 三路状态 | 每路显示推进、僵持、破门风险、入侵中的一种状态。 |
| 机器兑现提示 | 当主轴造成明显战场结果时，短暂显示对应标签，例如 `Launch sustained flow`、`Tuning high-value hit`、`Tuning repeated hit`、`Unit anchor slot`、`Unit batch release`。 |
| Guardian HP | 显示玩家 Guardian 和 Endpoint Guardian 当前 HP。 |
| 结果页入口 | 战斗结束后必须进入结果页，不允许只弹胜负文字。 |

### 验收信号

玩家能说：

> 我赢是因为某条机器轴兑现了；或我输是因为某条机器轴断了、被反制打穿，或者我没有补洞。

### 失败信号

- 玩家说赢输只是因为点路快慢。
- 玩家说赢输只是因为单位多或少。
- 玩家无法指出关键奖励 / 商店选择。
- 玩家看不出终点战和前面构筑有关。

## 9. 结果页检查

结果页必须支持玩家复盘，而不是只给胜负。

结果页字段只记录本局已经发生的机器事实，不做隐藏评分，不替玩家判断“正确选择”。失败观察方式另行定义。

### 总览字段

| 字段 | 目的 |
|---|---|
| 主机器轴 | 玩家本局主要强化 `Launch / Tuning / Unit` 哪条轴。 |
| 关键奖励 | 记录第一次奖励和第二次奖励选择。 |
| 关键商店 | 记录购买的机器修正和休整。 |
| Guardian 选择 | 记录玩家选择了哪个 Guardian，以及它的轴倾向是否被读懂。 |
| Unit 槽贡献 | 记录 4 个 Unit slot 是否都产生过可见贡献路径。 |
| 主要反制 | 记录敌人攻击了哪个机器组件。 |
| Deploy Lane 影响 | 记录关键路线选择造成的战场变化。 |
| 终点战结论 | 说明机器轴如何兑现或断裂。 |

### 按检查点记录字段

| 检查点 | 字段 | 记录内容 | 结果页显示目的 |
|---|---|---|---|
| 开局 Guardian | `guardian.choice_id` | 玩家选择的 `Player Guardian`。 | 记录 Guardian 选择率，避免某个 Guardian 因不可读或明显弱势无人选择。 |
| 开局 Guardian | `guardian.choice_read` | 玩家是否能说出该 Guardian 的轴倾向和守家特色。 | 判断 Guardian 是开局构筑锚点，不是随机英雄皮肤。 |
| 开局 Guardian | `guardian.outcome` | 本局是否到达 Endpoint、是否胜利、结束时 Guardian HP。 | 给 Guardian 软平衡护栏提供观察依据。 |
| 开局 Guardian | `guardian.hp_pressure_events` | 本局 Guardian 被入侵、受伤、休整购买和低血量节点。 | 判断战术技能是否只是装饰，或是否独自稳住所有漏兵。 |
| Battle 1 前 30 秒 | `battle1.machine_chain_sample` | 一次完整链路样例：Pool 入槽、fired ball、Tuning 命中、Slot Exposure Gate 判定、Unit slot 获得 progress、queue entry 生成。 | 让玩家复盘球机从造球到成兵的基础因果。 |
| Battle 1 前 30 秒 | `battle1.exposure_gate_snapshot` | 前 30 秒的槽位闸门位置和已暴露 slot。 | 说明低需求 slot 先出兵，高需求 slot 会逐步开放。 |
| Battle 1 前 30 秒 | `battle1.deploy_lane_selection` | 前 30 秒当前选中路线和玩家是否切过路线。 | 说明 `Deploy Lane` 只改变部署落点，不改变机器产出。 |
| Battle 1 前 30 秒 | `battle1.lane_danger_snapshot` | 前 30 秒三路最高危险档，使用 0-3 档。 | 说明危险提示是路线状态，不是机器强度来源。 |
| Unit 槽贡献 | `unit.visible_contribution_slots` | 本局哪些 Unit slot 产生过可见贡献：稳线、破僵、解漏、Endpoint 关键输出或关键队列结果。 | 验证 4 个 slot 都不是纯数字摆设。 |
| Unit 槽贡献 | `unit.key_queue_entries_by_slot` | 按 slot 记录关键 queue entry，不统计普通刷屏数量。关键 queue entry 指改变路线状态、防漏、破门压力或 Endpoint 结果的队列条目。 | 防止低需求槽或某个高价值槽长期吞掉全部战场意义。 |
| Unit 槽贡献 | `unit.dominant_slot_share` | 本局关键 queue entry 中占比最高的 slot 及比例。 | 判断 `Unit` 是否退化成永远押单槽。 |
| 第一次奖励 | `reward1.choice_id` | 选择了 `Pool Pocket`、`Prime Charge` 或 `Slot Primer`。 | 让玩家看到第一张关键构筑锚点。 |
| 第一次奖励 | `reward1.axis` | 该奖励对应 `Launch`、`Tuning` 或 `Unit`。 | 让玩家把奖励读成机器轴选择。 |
| 第一次奖励 | `reward1.component_operation` | 该奖励改的组件和操作，例如 `Pool capacity +1`、`Prime hit value +1 -> +2`、`Unit slot progress floor = 1`。 | 让玩家看到奖励不是泛用强度。 |
| 第一次奖励 | `reward1.battlefield_expectation` | 奖励对应的预期战场标签：`Launch sustained flow`、`Tuning high-value hit` 或 `Unit anchor slot`。 | 让玩家知道自己不是在买泛用强度。 |
| 第一次奖励 | `reward1.battlefield_result` | 本局是否出现对应战场结果，以及出现在哪一场、哪一路。 | 判断第一次奖励是否真的被战场读出来。 |
| 第一次商店 | `shop1.gold_before` | 进入商店时 Gold；若 Battle 1 和 Battle 2 都是普通胜利，第一次商店应为 12。 | 解释第一次商店为什么用购买额度而不是低 Gold 限制信息量。 |
| 第一次商店 | `shop1.purchase_id` | 买了哪个机器修正或是否买了休整。 | 记录关键商店选择。 |
| 第一次商店 | `shop1.purchase_role` | 购买项是 `Patch`、`Pivot`、`Deepen`、`Rest` 中哪类。 | 让玩家复盘自己是在补洞、转向、深化还是休整。 |
| 第一次商店 | `shop1.gold_after` | 购买后的 Gold。 | 显示商店选择存在机会成本。 |
| 休整窗口 | `rest_windows` | 本局出现过哪些休整窗口、是否购买、花费 Gold、恢复 HP。 | 让玩家看到休整是有限战后整备，不是每场自动回血。 |
| 第一次反制 | `counter1.family` | 出现的反制家族：`Pool Polluter`、`Echo Breaker` 或 `Stagger Punisher`。 | 让玩家知道敌人不是单纯变强。 |
| 第一次反制 | `counter1.target_component` | 被攻击的机器组件：Pool、Echo / Surge 价值、queue gap。 | 把失败或压力复盘到机器弱点。 |
| 第一次反制 | `counter1.visible_effect` | 可见结果：Junk 插入、Echo 降级、Raider 因 queue gap 出现。 | 让玩家能把预警和实际后果连起来。 |
| 第一次反制 | `counter1.response_link` | 本局是否有对应的已购补洞项或候选补洞项。 | 说明奖励 / 商店如何回应反制。 |
| 第二次奖励 | `second_offer.current_axis` | 进入第二次奖励前的当前主轴。 | 让玩家看到系统为什么给这些候选。 |
| 第二次奖励 | `second_offer.candidates` | 展示过的候选、每个候选的 `Deepen current axis` / `Patch` / `Pivot` 标签和出现原因。 | 让玩家区分主轴深化和补洞。 |
| 第二次奖励 | `second_offer.choice_id` | 玩家最终选择的奖励。 | 记录第二个关键构筑承诺。 |
| 第二次奖励 | `second_offer.choice_role` | 选择项属于深化主轴、补洞还是转向。 | 让玩家复盘本局从单点选择变成构筑结构。 |
| 终点战 | `endpoint.outcome` | 胜利或失败。 | 给结果页基础结论。 |
| 终点战 | `endpoint.primary_axis_payoff` | 本局最明显的机器兑现标签：`Launch sustained flow`、`Tuning high-value hit`、`Tuning repeated hit`、`Unit anchor slot`、`Unit batch release`，或未明显兑现。 | 让玩家看到主轴有没有转成战场优势。 |
| 终点战 | `endpoint.main_break_reason` | 最主要断裂原因：Pool 卡住、Echo / Surge 价值被打断、queue gap、路线漏兵、Guardian HP 被打穿，或未定。 | 让失败复盘回到机器和战场边界。 |
| 终点战 | `endpoint.next_run_watch_tag` | 失败时显示 1 个下一局重点观察标签，例如 `Launch pollution patch`、`Tuning repeated hit`、`Unit gap patch`、`lane leak watch`、`Guardian HP pressure`。 | 让玩家知道下一局该观察什么，而不是给资源补偿。 |
| 终点战 | `endpoint.deploy_lane_impact` | 关键路线选择如何影响落点，例如把 queue entry 投到危险路线、错过危险路线，或没有关键影响。 | 防止玩家把点路误读成唯一胜负原因。 |
| 终点战 | `endpoint.guardian_hp` | 玩家 Guardian 和 Endpoint Guardian 结束 HP。 | 让终点战不是只显示胜负文字。 |
| 会话节奏 | `session.decision_windows` | 本局出现过的可解释选择：Guardian、第一次奖励、第一次商店、休整窗口、第二次奖励、Endpoint 前整备和关键 Deploy Lane 改变。 | 判断玩家是否在连续多场只看球掉，没有构筑或路线判断。 |
| 会话节奏 | `session.consecutive_no_explained_decision_battles` | 连续没有可解释选择或可复盘结果的战斗数。 | 防止 MVP 中段出现无聊空窗。 |

结果页不需要复杂统计图。第一版可以文字较重，但必须用机器语言解释胜负。

MVP 信息恢复口径：

- 失败后本局结束。
- 不返还 Gold。
- 不续关。
- 不给下一局资源补偿。
- 失败恢复只通过结果页信息完成：`endpoint.main_break_reason` 说明哪里断，`endpoint.next_run_watch_tag` 说明下一局该观察什么。
- `endpoint.next_run_watch_tag` 不保证下一局刷出对应奖励或商店项，也不隐藏提高候选权重。

## 10. 失败观察方式

失败观察只用于 MVP playtest 和实现验收，不是游戏内评分系统。观察目标是找出玩家是否把画面读成机器因果，而不是测试玩家能不能背规则。

### 观察规则

- 观察者只能记录玩家行为、结果页字段和玩家原话，不能先解释规则再问。
- 每个检查点只问一个短复盘问题，避免把 playtest 变成口试。
- 玩家回答必须提到机器轴、机器组件或 `Deploy Lane` 边界，只有“兵更多”“怪更强”“我点了危险路”不算通过。
- 单次失败只记录问题，不直接改设计；同类失败反复出现时，回到对应 UI、规则或节奏。

### 按检查点观察

| 检查点 | 观察时点 | 观察动作 | 记录为失败的情况 |
|---|---|---|---|
| Battle 1 前 30 秒 | 第一个 queue entry 生成后，或 Battle 1 结束后立刻。 | 让玩家指出 Pool、Tuning、Slot Exposure Gate、Unit slot、当前 Deploy Lane，并用一句话说单位怎么来的。对照 `battle1.machine_chain_sample`。 | 玩家只能指出战场路线；说不出 fired ball 到 Unit progress 的链路；以为点路改变造球、调校或出兵数量；以为被闸门弹开的球消失了。 |
| 第一次奖励 | 玩家选完 `Pool Pocket` / `Prime Charge` / `Slot Primer` 后先问一次；Battle 2-3 后再对照战场结果。 | 先问“你刚才选的是哪条机器轴？你期待它在战场上变成什么？”之后观察是否出现 `reward1.battlefield_result`。 | 玩家只说更强、更快、兵更多；说不出 `Launch / Tuning / Unit`；选完后找不到 HUD 上的奖励生效位置；Battle 2-3 后看不到对应战场标签。 |
| 第一次商店 | 玩家完成购买或离开商店时。 | 问玩家“你买的是补洞、转向、深化还是休整？为什么现在不能随便买第二个？”对照 `shop1.gold_before`、`shop1.purchase_role`、`shop1.gold_after`。 | 玩家只按价格解释选择；不知道 Gold 机会成本；不知道商品改了哪个机器组件；把休整当作无成本安全项。 |
| 第一次反制 | 反制预警出现后到反制生效后。 | 观察玩家是否看向被高亮机器组件，并在战后问“这波敌人在攻击你的哪一块机器？”对照 `counter1.target_component` 和 `counter1.visible_effect`。 | 玩家只说敌人变强；把反制当随机事件；只想通过点危险路线解决；无法把补洞项和反制目标连起来。 |
| 第二次奖励 | 第二次候选出现并完成选择后。 | 问玩家“哪个候选是在深化当前主轴，哪个是在补洞或转向？你为什么选这个？”对照 `second_offer.current_axis`、`second_offer.candidates`、`second_offer.choice_role`。 | 玩家觉得候选随机；只看稀有感；无法说出当前主轴；无法区分 `Deepen current axis`、`Patch`、`Pivot`。 |
| 终点战 | 终点战结束并进入结果页后。 | 让玩家先看结果页，再用一句话复盘胜负原因。对照 `endpoint.primary_axis_payoff`、`endpoint.main_break_reason`、`endpoint.deploy_lane_impact`。 | 玩家只归因于点路快慢、单位数量或 Guardian 血量；说不出主轴是否兑现；说不出哪里断裂；看不出终点战和前面构筑有关。 |

### 失败回流

| 失败集中位置 | 优先回流 |
|---|---|
| Battle 1 链路读不懂 | 改 `Pool / Forge / Launcher / Tuning / Slot Exposure Gate / Unit slots` 的 UI 最小反馈。 |
| 奖励读成通用 buff | 改奖励卡的 `warehouse -> component -> operation` 表达。 |
| 商店只按价格买 | 改价格带、标签和商品卡玩家读法。 |
| 反制读成随机变强 | 改反制预警、目标组件高亮和生效反馈。 |
| 第二次候选读成随机刷新 | 改当前主轴提示和候选来源说明。 |
| 终点战只能复盘点路 | 改终点战机器兑现提示、结果页结论或战斗节奏。 |
| Guardian 选择率或成功率超过软护栏 | 先改 Guardian 选择卡、轴倾向读法、战术技能反馈和失败原因记录；确认不是误读后再动数值。 |
| 单一 Unit slot 长期吞掉关键队列贡献 | 改 `progress_required`、`Unit.Slot.Exposure Gate` 节奏、单位职责或关键 queue entry 反馈。 |
| 连续两场出现决策空窗 | 改战斗时长、反制出现点、奖励 / 休整时机或结果页复盘提示，不先加新系统。 |

## 11. MVP 软阈值护栏

这些护栏只用于 10-20 局第一轮 playtest 和实现验收，不是最终平衡，也不是游戏内评分。样本太小时不直接重做数值；先判断问题属于可读性、吸引力、强度，还是节奏。

### Guardian 护栏

MVP 第一版有 2 个可选 `Player Guardian`。两个 Guardian 都必须能作为开局构筑锚点被读懂，不能出现一个默认正确、另一个只是摆设。

| 观察项 | 软阈值 | 触发后的判断 |
|---|---|---|
| 选择率 | 10-20 局后，任一 Guardian 选择率低于 30%，或另一个高于 70%。 | 如果胜率正常，优先查选择 UI、名称、剪影和轴倾向读法；如果胜率也低，再查强度和技能兑现。 |
| 成功率差距 | 两个 Guardian 的到达 Endpoint 率或通关率差距超过 15 个百分点。 | 视为软平衡问题，但不直接削弱；先看失败原因是否集中在 Guardian HP、守家技能、战略技能或玩家误读。 |
| 守家影响 | 某个 Guardian 很少触发守家价值，或能独自解决大多数漏兵。 | 前者说明战术技能像装饰；后者说明 Guardian 正在变成第四主系统。 |
| 构筑倾向 | 玩家选完后说不出该 Guardian 偏 `Launch / Tuning / Unit` 哪条轴。 | 先改开局选择卡和结果页读法，不先改数值。 |

### Unit 槽护栏

4 个 Unit slot 不需要平均出场，也不需要平均强度。它们必须各自有可见贡献路径。

Hive 第一种族使用职责带口径判断 Unit slot 数值是否合格：`短牙虫` 快速接线但不抗压，`盾壳虫` 抗压但不推进，`酸囊虫` 破僵但不做持续炮台，`碾壳兽` 晚到翻线但不常驻清场。若为了提高胜率而破坏这些职责，不能算 MVP 正式调参方向。

| 观察项 | 软阈值 | 触发后的判断 |
|---|---|---|
| 可见贡献 | 每个 slot 至少要在一种正常构筑或命名 Unit 构筑中产生可见贡献。 | 如果某个 slot 只在数字表里存在，改 `progress_required`、闸门节奏、单位职责或反馈。 |
| 关键队列占比 | 非 `Slot Primer / Unit` 构筑下，单一 slot 不应长期占据 60% 以上关键 queue entry。 | 如果 Slot 1 长期占比过高，高需求槽没有兑现；如果 Slot 4 长期占比过高，早期槽被压扁。 |
| 高需求槽兑现 | Slot 3 / Slot 4 可以晚，但 Endpoint 前必须能被结果页复盘到至少一种战场贡献。 | 如果玩家只记得低级槽，闸门节奏或高需求单位职责失败。 |
| Slot Primer 读法 | 选择 `Slot Primer` 后，玩家必须记得被选 slot，并能在 Battle 2-5 指出它的战场作用。 | 如果只记得“我选了 Unit”，但忘了槽位，`Slot Primer` UI 和 HUD 标记不够。 |

### 决策密度护栏

`Deploy Lane` 是轻策略，不能替代构筑选择。MVP 也不能连续多场让玩家只是看球掉和等结果。

| 观察项 | 软阈值 | 触发后的判断 |
|---|---|---|
| 可解释选择 | 每场战斗前后至少要有 1 个可解释选择或可复盘结果：Guardian、奖励、商店、休整、第二次奖励、Endpoint 前整备，或关键 Deploy Lane 改变。 | 如果玩家连续两场说不出自己在等什么，节奏有空窗。 |
| 连续空窗 | 不允许连续 2 场战斗只有自动播放，没有新选择、反制、兑现提示或结果页复盘点。 | 优先改战斗时长、反制出现点、奖励时机或结果页提示，不先加新系统。 |
| 选择解释 | 玩家至少能把选择说成 `强化某轴`、`补某洞`、`休整保命` 或 `把队列投到某条危险路线`。 | 如果只能说“我随便点一个”，说明 UI 文案、价格带或战场反馈没有支撑选择。 |

## 12. 实现前硬门槛

当前文档态实现前硬门槛已补齐：

- Hive 第一种族的 MVP 数值职责带口径已确认，见 `docs/mvp-scope.md`。
- 中立修正职责带平衡口径和休整结果页口径已确认，见 `docs/rewards-economy.md`。

具体精确平衡仍需模拟和 playtest，不作为文档态实现前硬门槛。新的实现计划必须引用上述口径，不能恢复旧 prototype 或旧 Web MVP 假设。
