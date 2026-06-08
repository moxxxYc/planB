# 中立机器修正候选草案

**最后更新：** 2026-06-08
**仓库状态：** 纯文档态，无当前正式实现。
**草案状态：** 候选池结构、软分池、奖励 / 商店投放规则、Gold faucet、价格带、职责带平衡口径和休整结果页口径已确认；第二次奖励固定为 Battle 4 后的免费奖励，不开第二次商店。精确 playtest 后最终平衡和种族包装未确认。

本文暂存第一批中立修正候选，用于 `/game-ideation` 逐项确认。第一次奖励三轴锚点、第一次商店候选池、`Echo Latch` 位置、第二次奖励生成规则、Gold faucet、价格带、职责带平衡口径和休整结果页口径已确认；其余未确认内容不定义逐场战斗脚本、具体种族单位或 Guardian 技能。

## 1. 目标

第一批中立修正候选用于证明三件事：

1. `Launch / Tuning / Unit` 三条轴都有可读构筑方向。
2. 奖励和商店不是泛用数值购买。
3. 玩家能把某次选择复盘成“我改了哪个机器组件，它怎样改变战场”。

MVP 中实际使用效果最多 9 个。本文列出 9 个候选，每条轴 3 个；第一次奖励、第一次商店、第二次奖励生成规则、Gold faucet、价格带和职责带平衡口径已确认。精确 playtest 后最终平衡和种族包装仍未定。

## 2. 候选边界

- 中立修正没有种族身份，不替代 Hive 或未来种族内容。
- 中立修正采用软分池：每个修正有主来源，少数修正可以同时进入奖励池和商店池。
- 一局不需要看到全部 9 个。
- 不允许把同一个中立修正无限叠成主策略。
- 不允许出现“所有单位加伤害”“所有输出提高”“所有敌人变弱”。
- 每个修正必须走 `Machine Contract 1.0`。

已确认的候选池结构：

1. 第一次奖励教玩家识别 `Launch / Tuning / Unit` 三条机器轴。
2. 商店优先提供对已公开危险和反制的补洞项。
3. Battle 4 后的第二次奖励再根据玩家主轴提供加强项或补洞项。
4. 奖励池和商店池采用软分池，不硬切，也不完全共用。
5. 第一次奖励三轴锚点为 `Pool Pocket` / `Prime Charge` / `Slot Primer`。
6. 第一次商店候选池为 `Front Recycle` / `Junk Sieve` / `Surge Buffer` / `Queue Brace` / `Muster Pair`。
7. `Echo Latch` 保留为第二次奖励的 Tuning 深化项，不进入第一次商店。
8. 第二次奖励采用主轴优先池：展示 2-3 个候选，至少 1 个强化当前主轴，至少 1 个补洞或转向；第二次奖励是免费奖励，不开第二次商店。

候选投放方式：

| 时机 | 内容 |
|---|---|
| 第一次奖励 | 给 3 个不同轴的低风险修正，让玩家承诺方向。 |
| 商店 | 提供 3-5 个修正，至少 1 个补洞项，也允许少数主轴强化项出现。 |
| 第二次奖励 | Battle 4 后出现，按玩家当前主轴生成 2-3 个候选，至少 1 个强化主轴，至少 1 个补洞或转向；不消耗 Gold。 |

## 3. 总览

| 名称 | 轴 | 主要用途 | 推荐来源 |
|---|---|---|---|
| `Pool Pocket` | `Launch` | 扩大可见缓存，抵抗断档和 Junk 挤压。 | 奖励 / 商店 |
| `Front Recycle` | `Launch` | 让 miss 回流更快转成下一轮压力。 | 奖励 / 商店 |
| `Junk Sieve` | `Launch` | 给 Pool Polluter 一个机器层面的补洞解法。 | 商店 |
| `Prime Charge` | `Tuning` | 强化高价值命中。 | 奖励 / 商店 |
| `Echo Latch` | `Tuning` | 让重复结算更集中、更可读。 | 奖励 |
| `Surge Buffer` | `Tuning` | 让未成形的 Surge 也能留下部署节奏价值。 | 商店 |
| `Queue Brace` | `Unit` | 降低队列断档，回应 Stagger Punisher。 | 商店 |
| `Muster Pair` | `Unit` | 形成可读批量部署。 | 奖励 / 商店 |
| `Slot Primer` | `Unit` | 让一个槽位整局始终领先一步。 | 奖励 / 商店 |

## 4. Launch 修正

### Pool Pocket

| 字段 | 内容 |
|---|---|
| source | Neutral reward / shop |
| warehouse | `Launch` |
| target component | `Launch.Pool.capacity` |
| operation | add |
| scope | 整局 |
| rule | Pool 容量 `+1`。第一版最多叠 1 次。 |
| player read | Pool 多出一个可见槽位，断档更少，Junk 挤压时还有缓冲。 |
| failure risk | 容量过大时，Pool Polluter 失去威胁，Launch 退化成稳定多出兵。 |
| guardrail | MVP 第一版 Pool 容量上限为 6，不能通过中立修正到 7。 |

### Front Recycle

| 字段 | 内容 |
|---|---|
| source | Neutral reward / shop |
| warehouse | `Launch` |
| target component | `Launch.Recycle.return_position` |
| operation | replace |
| scope | 整局 |
| rule | Miss + Recycle 回流的 clean ball 插入 Pool 前半段，而不是默认尾部。Pool 满时仍然回流失败。 |
| player read | miss 后的回流更快进入 Launcher，战场表现为持续补线而不是瞬间爆发。 |
| failure risk | 如果回流太快，玩家会把 Launch 读成“永远不断兵”，削弱 Tuning 和 Unit 价值。 |
| guardrail | 不改变 Recycle 数量，不继承父球标签，不绕过 Pool 满失败。 |

### Junk Sieve

| 字段 | 内容 |
|---|---|
| source | Neutral shop |
| warehouse | `Launch` |
| target component | `Launch.Junk.fire_behavior` |
| operation | convert |
| scope | 整局，带冷却 |
| rule | 每 10s 最多 1 次，Launcher 发现 Pool 头部是 Junk Ball 时，将该 Junk 丢弃为 Waste，不发射，不产生 Unit hit。 |
| player read | Junk 到达发射口时被筛掉，Pool 空位释放，玩家看见污染被处理。 |
| failure risk | 如果无冷却，会让 Pool Polluter 完全失效。 |
| guardrail | 只处理 Pool 头部 Junk，不清空 Pool 内全部 Junk，不产生 clean ball。 |

## 5. Tuning 修正

### Prime Charge

| 字段 | 内容 |
|---|---|
| source | Neutral reward / shop |
| warehouse | `Tuning` |
| target component | `Tuning.Prime.value_bonus` |
| operation | add |
| scope | 整局 |
| rule | Prime 的 Unit hit 从 `value + 1` 改为 `value + 2`。 |
| player read | Prime 命中时 Unit 进度跳得更明显，读成少数高价值命中。 |
| failure risk | Prime 过强时，Tuning 只剩找 Prime，不再需要 Echo 或 Surge。 |
| guardrail | 不改变 Prime 槽宽，不让 Gate 获得额外价值。 |

### Echo Latch

| 字段 | 内容 |
|---|---|
| source | Second reward candidate |
| warehouse | `Tuning` |
| target component | `Tuning.Echo.target_lock` |
| operation | replace |
| scope | 整局 |
| rule | Echo 复制结算锁定到触发它的同一个 Unit slot，并显示一次可见 ghost hit。 |
| player read | 玩家能看到同一槽位被连续敲两次，读成重复重击，而不是随机多了一点进度。 |
| failure risk | 如果 ghost hit 反馈不清楚，Echo 仍会像隐藏数学。 |
| guardrail | 不增加 Echo copy 次数，不触发二次 Echo，不复制物理球。 |

### Surge Buffer

| 字段 | 内容 |
|---|---|
| source | Neutral shop |
| warehouse | `Tuning` |
| target component | `Tuning.Surge.charge_buffer` |
| operation | trigger |
| scope | 整局 |
| rule | Surge 命中但没有立刻生成 queue entry 时，在该 Unit slot 存 1 个 `surge_charge`。该槽下一次生成 queue entry 时，entry 使用 0.25s 部署延迟并消耗 charge。每个 slot 最多存 1 个 charge。 |
| player read | 玩家看到 Surge 标记留在槽上，下一次该槽出兵更快落地。 |
| failure risk | 如果 charge 可以堆叠，Surge 会变成全局队列加速器。 |
| guardrail | charge 不跨 slot，不全局加速队列，不改变 Unit 进度需求。 |

## 6. Unit 修正

### Queue Brace

| 字段 | 内容 |
|---|---|
| source | Neutral shop |
| warehouse | `Unit` |
| target component | `Unit.Queue.empty_gap_response` |
| operation | trigger |
| scope | 整局，带冷却 |
| rule | 当队列连续 3s 没有部署条目时，在当前已暴露或可合法落入的 Unit slot 中，给最低进度 slot 加 `+1` progress。每 12s 最多触发 1 次。 |
| player read | 队列空档出现时，机器自己补一个低阶进度，帮助玩家避免长时间无部署。 |
| failure risk | 如果触发太频繁，Stagger Punisher 失去意义，Unit 轴过稳。 |
| guardrail | 只加进度，不直接生成 queue entry，不取消已经公开的 Stagger 突袭，不给未暴露的高需求 slot 绕过 Slot Exposure Gate。 |

### Muster Pair

| 字段 | 内容 |
|---|---|
| source | Neutral reward / shop |
| warehouse | `Unit` |
| target component | `Unit.Queue.merge_window` |
| operation | trigger |
| scope | 整局 |
| rule | 同一个 Unit slot 在 1.2s 内连续生成 2 个 queue entries 时，合并为 1 个 `paired_entry`，在同一部署节拍生成 2 个单位。 |
| player read | 玩家看到同一槽位成对出兵，战场表现为批量冲锋。 |
| failure risk | 如果合并窗口太宽，所有 Unit 构筑都会稳定成批，Launch 和 Tuning 被压掉。 |
| guardrail | 只合并同 slot entries，不跨 slot 合并，不改变单位属性。 |

### Slot Primer

| 字段 | 内容 |
|---|---|
| source | Neutral reward / shop |
| warehouse | `Unit` |
| target component | `Unit.Slot.progress_floor` |
| operation | set floor |
| scope | 整局，选择 1 个 slot |
| rule | 选择 1 个 Unit slot。接下来整局游戏中，该 slot 的 progress 下限为 `1`：每场战斗开始时至少有 `1` 点 progress，生成 queue entry 后也重置回 `1` 而不是 `0`。 |
| player read | 玩家能把一个槽位读成本局 Unit 锚点，它始终比其他槽领先一步。 |
| failure risk | 如果多个槽都获得 progress floor，Unit 会变成默认最优轴。 |
| guardrail | 只能选择 1 个 slot，不降低 `progress_required`，不改变 loaded unit，不给每次 Unit hit 额外加点，不改变该 slot 的暴露状态；第一版 baseline 的 `progress_required = 3 / 5 / 8 / 12`，所以 floor 1 只是让目标槽领先一步，不会单独触发出兵。 |

## 7. MVP 投放候选

第一版不要一次把 9 个都塞进玩家脸上。候选池结构和投放规则已确认；经济、数值和战斗脚本未确认前，不能作为实现计划输入。

候选节奏：

| 节点 | 投放 |
|---|---|
| 第一次奖励 | 已确认 3 选 1：`Pool Pocket` / `Prime Charge` / `Slot Primer`。 |
| 第一次商店 | Battle 2 后出现；已确认候选池：`Front Recycle` / `Junk Sieve` / `Surge Buffer` / `Queue Brace` / `Muster Pair`，展示 3 个，至少 1 个补洞项。 |
| 第二次奖励 | Battle 4 后出现；已确认主轴优先池，见下方规则；不消耗 Gold，不开第二次商店。 |

候选投放规则：

- 第一次奖励必须覆盖三个轴，已确认使用 `Pool Pocket` / `Prime Charge` / `Slot Primer`。
- 第一次商店从 `Front Recycle` / `Junk Sieve` / `Surge Buffer` / `Queue Brace` / `Muster Pair` 中展示 3 个，至少提供 1 个补洞项。
- 第二次奖励按当前主轴生成候选，展示 2-3 个，至少 1 个强化当前主轴，至少 1 个补洞或转向。
- `Launch` 主轴：优先 `Front Recycle`，外加 `Junk Sieve` 或跨轴补洞 / 转向项。
- `Tuning` 主轴：优先 `Echo Latch`，外加 `Surge Buffer` 或跨轴补洞 / 转向项。
- `Unit` 主轴：优先 `Muster Pair`，外加 `Queue Brace` 或跨轴补洞 / 转向项。
- 主来源是奖励的修正可以少量进入商店，但不能让商店替代奖励的三轴教学。
- 主来源是商店的修正可以少量进入第二次奖励，但不能挤掉第一次奖励的三轴锚点。
- 如果 Battle 3 使用 Pool Polluter，商店池必须允许 `Junk Sieve` 或 `Pool Pocket`。
- 如果 Battle 3 使用 Echo Breaker，商店池必须允许 `Prime Charge` 或 `Surge Buffer`。
- 如果 Battle 3 使用 Stagger Punisher，商店池必须允许 `Queue Brace` 或 `Slot Primer`。

## 8. 第一次奖励战场结果模型

第一次奖励的三选一先用战场结果模型比较，不先追求精确 Unit progress 数学等价。机器 telemetry 可以辅助解释，但 MVP 第一版的通过标准是玩家能在战场和结果页看到不同奖励兑现成不同压力形态。

比较原则：

- 不要求 `Pool Pocket` / `Prime Charge` / `Slot Primer` 产生相同数量的单位或相同胜率。
- 三个奖励必须分别兑现不同战场标签：持续流、高价值命中、锚点槽位。
- 如果三项最后都只被玩家读成“兵更多”，第一次奖励失败。
- 如果任一奖励只在机器 UI 上有数字变化，战场上没有可见结果，该奖励不能算通过 MVP 验收。

第一次奖励战场结果表：

| 奖励 | 战场结果目标 | 观察字段 | 失败信号 |
|---|---|---|---|
| `Pool Pocket` | Battle 2-3 的主压路线更少出现可见断档；玩家能看到同一路线持续有我方单位接线或补线，而不是一波后空掉。 | `reward1.battlefield_result = Launch sustained flow`；记录压力波后是否出现 `lane_empty_gap`、持续接战是否被保持。 | 玩家只看到 Pool 多一格，但战场仍频繁空线；或者 Pool Polluter 完全失去压力，Launch 变成无脑稳定。 |
| `Prime Charge` | Prime 命中后 4-6s 内应至少出现一次可见战场转折：僵持线被打破、漏兵压力被缓解、敌方门前压力增加，或高价值单位进度导致关键 queue entry 更快出现。 | `reward1.battlefield_result = Tuning high-value hit`；记录 `prime_charge_swing_seen` 和对应路线状态变化。 | 只看到 Prime 数字变大，但玩家说不出哪一路因此改变；或者 Prime 过强导致 Echo / Surge 读法被压掉。 |
| `Slot Primer` | 被选 Unit slot 应在 Battle 2-5 中形成可见锚点：该槽单位更早或更稳定地成为一路战场状态的原因。Slot 4 的兑现可以偏晚，但必须在 Endpoint 前能被结果页复盘到。 | `reward1.battlefield_result = Unit anchor slot`；记录 `slot_primer.selected_slot`、该槽关键 queue entry 和对应路线结果。 | 玩家记不住选了哪个槽；被选槽位的单位没有可见战场贡献；或 Slot 3 / Slot 4 过早压倒其他选择，让 Unit 线成为默认最优。 |

结果页不需要给玩家显示完整数学。第一版只需要记录：玩家选了哪张第一次奖励、它对应哪条机器轴、它在战场上有没有出现对应标签。

## 9. 复盘标签

如果候选进入正式规则，结果页需要记录每个中立修正的复盘标签：

| 标签 | 对应修正 |
|---|---|
| `Launch sustained flow` | `Pool Pocket`、`Front Recycle` |
| `Launch pollution patch` | `Junk Sieve` |
| `Tuning high-value hit` | `Prime Charge` |
| `Tuning repeated hit` | `Echo Latch` |
| `Tuning fast landing` | `Surge Buffer` |
| `Unit gap patch` | `Queue Brace` |
| `Unit batch release` | `Muster Pair` |
| `Unit anchor slot` | `Slot Primer` |

如果结果页不能把修正归到这些标签，说明修正读法仍然太含混，不能直接锁为正式规则。

## 10. 职责带平衡口径

MVP 第一版不使用精确终局数值表来判断中立修正是否合格。中立修正的平衡先按职责带验收：它改了哪个机器组件、回应了什么风险、在战场和结果页上产生了什么可读后果。

通用规则：

- 价格带保持 `休整 3 / 补洞 4 / 转向 5 / 主轴深化 6`。
- 第一次奖励是免费三轴锚点，不参与 Gold 价格比较。
- 不要求不同修正产生相同胜率、相同单位数量或相同 Unit progress。
- 不允许通过中立修正直接做全单位伤害、全敌人削弱、全局产出提高。
- 如果一个修正提高胜率但让玩家只读成“兵更多”或“数字更大”，不能算 MVP 正式平衡方向。
- 如果一个修正让对应反制家族完全失去威胁，说明过强；如果只能在机器 UI 上看到数字、战场和结果页无法复盘，说明过弱。

按价格带的职责：

| 类型 | Gold | 合格职责 | 过强信号 | 过弱信号 |
|---|---:|---|---|---|
| 休整 | 3 | 用 Gold 换 `Player Guardian` HP，给受压玩家一次战后整备机会。它是 sink，不是机器修正。 | 玩家只要买休整就稳定越过 Endpoint；休整让 Guardian HP 压力不再是失败原因。 | 玩家买了也无法改变任何 HP 压力判断；结果页看不出花 Gold 的意义。 |
| 补洞项 | 4 | 回应一个已公开风险或反制目标，把危险从“会打穿”降到“可继续处理”。 | 单个补洞项抹掉整个反制家族，使对应敌人不再需要观察。 | 玩家买完仍不知道它回应了什么风险，或结果页没有 `response_link`。 |
| 转向项 | 5 | 改变构筑形状，让玩家从当前机器状态转向另一种可读战场结果。 | 转向项同时解决当前风险并强化主轴，变成默认最优购买。 | 下一场到第二次奖励前仍看不到构筑形状变化。 |
| 主轴深化项 | 6 | 强化当前已形成的机器轴，让结果页能复盘成更强的主轴兑现。 | 不看当前主轴也总是最优，压掉补洞和转向选择。 | 只有机器数字变化，没有 `primary_axis_payoff` 或对应复盘标签。 |

9 个中立修正的职责带：

| 修正 | 职责带 | 合格信号 | 过强 / 过弱信号 |
|---|---|---|---|
| `Pool Pocket` | 免费时是 `Launch` 三轴锚点；商店中属于转向项。 | 主压路线断档减少，结果页能记录 `Launch sustained flow`。 | 过强：Pool Polluter 和断档风险消失。过弱：只看到 Pool 多一格，战场无变化。 |
| `Front Recycle` | `Launch` 转向项，让 miss 回流更快参与持续补线。 | Miss 后的 clean ball 更快进入发射节奏，下一场能看到持续补线。 | 过强：Launch 变成永不断兵。过弱：玩家看不出回流位置改变。 |
| `Junk Sieve` | `Launch` 补洞项，专门回应 Pool 污染。 | Pool 头部 Junk 被筛掉，结果页能记录 `Launch pollution patch` 和对应反制回应。 | 过强：Pool Polluter 失效。过弱：Junk 仍持续堵死发射口。 |
| `Prime Charge` | 免费时是 `Tuning` 三轴锚点；商店中属于主轴深化项。 | Prime 命中后 4-6s 内能看到路线状态变化或关键队列结果。 | 过强：Tuning 只剩找 Prime。过弱：只看到数字变大，看不到战场转折。 |
| `Echo Latch` | `Tuning` 主轴深化项，强化重复结算读法。 | 同 slot 的 ghost hit 可见，结果页能记录 `Tuning repeated hit`。 | 过强：重复命中稳定压掉 Surge / Prime 差异。过弱：ghost hit 像隐藏数学。 |
| `Surge Buffer` | `Tuning` 补洞 / 节奏项，把未成形 Surge 留成下一次落地价值。 | Surge charge 留在槽上，下一次该槽 queue entry 更快落地。 | 过强：变成全局队列加速器。过弱：玩家看不到 charge 和落地延迟的因果。 |
| `Queue Brace` | `Unit` 补洞项，回应队列断档和 Stagger 风险。 | 队列空档后最低进度合法 slot 获得补点，结果页能记录 `Unit gap patch`。 | 过强：Stagger Punisher 失去意义。过弱：连续空档仍没有可见缓解。 |
| `Muster Pair` | `Unit` 转向 / 爆发项，形成同 slot 批量部署。 | 同 slot 成对出兵，战场读成 `Unit batch release`。 | 过强：所有 Unit 构筑都稳定成批。过弱：合并窗口太窄，玩家几乎看不到 paired entry。 |
| `Slot Primer` | 免费时是 `Unit` 三轴锚点；商店中属于主轴深化项。 | 被选 slot 在 Battle 2-5 形成可见锚点，结果页能记录 `Unit anchor slot`。 | 过强：高需求 slot 过早压倒其他路线。过弱：玩家记不住选了哪个 slot，或该 slot 无战场贡献。 |

### 休整结果页口径

`休整` 必须在结果页上作为 Gold sink 和 HP 压力回应显示，不能混进中立机器修正。

结果页字段：

| 字段 | 记录内容 | 显示目的 |
|---|---|---|
| `rest.total_purchases` | 本局购买休整次数。 | 让玩家看到休整是有限整备，不是自动回血。 |
| `rest.total_gold_spent` | 本局休整总花费。 | 显示休整和机器修正竞争 Gold。 |
| `rest.total_hp_restored` | 本局休整恢复的 `Player Guardian` HP 总量。 | 说明花费换来的生存价值。 |
| `rest.windows_used` | 哪些窗口购买过休整：第一次商店、Battle 3 后、Endpoint 前整备。 | 复盘玩家在哪些压力点选择保命。 |
| `rest.endpoint_relevance` | `none`、`helped_survive_to_endpoint`、`changed_endpoint_margin`、`insufficient`。 | 判断休整是否改变了进入 Endpoint 或 Endpoint 结局的 HP 压力。 |
| `rest.opportunity_cost` | 同局未购买或放弃的机器修正角色，例如 `Patch`、`Pivot`、`Deepen`。 | 防止玩家把休整理解成无成本安全项。 |

显示规则：

- 如果玩家没有购买休整，结果页只显示 `rest.total_purchases = 0`，不做指责性提示。
- 如果购买休整后仍因 Guardian HP 被打穿失败，显示 `rest.endpoint_relevance = insufficient`，并把主要断裂原因仍记为 `Guardian HP pressure` 或对应机器断裂。
- 如果购买休整让玩家以低 HP 进入或赢下 Endpoint，显示 `changed_endpoint_margin`，但不把休整写成机器主轴兑现。
- 如果玩家高额购买休整导致无法购买补洞项，结果页必须在 `rest.opportunity_cost` 中显示被放弃的购买角色。

## 11. Gold 与商店经济

第一版 MVP 的经济只用于测试“买一个机器修正是否有取舍”。它不能变成战中刷钱、表现结算或泛用经济游戏。

Gold faucet：

| 节点 | Gold | 规则 |
|---|---:|---|
| 起始 | 0 | 开局不带 Gold。 |
| Battle 1 胜利 | 6 | 支撑 Battle 1 后第一次奖励的可见战后结算，但不进入商店。 |
| Battle 2 胜利 | 6 | 与 Battle 1 的 6 Gold 合并，让第一次商店通常以 12 Gold 开始。 |
| Battle 3 强反制胜利 | 8 | Gold faucet 的最后一次发放，用于支撑 Battle 3 后休整和 Endpoint 前整备。 |
| Battle 4 胜利 | 0 | Battle 4 后给第二次奖励，不再发 Gold。 |
| Battle 5 胜利 | 0 | Battle 5 后只进入 Endpoint 前整备窗口，不再发 Gold。 |
| Endpoint | 0 | 局结束，不再发 Gold。 |
| 失败 | 未定义 | MVP 第一版不做失败后继续，因此不定义失败 Gold；失败不返还 Gold，不续关，不给下一局资源补偿。 |

不使用以下 Gold 来源：

- 击杀奖励。
- 破门奖励。
- 快胜奖励。
- 剩余 HP 奖励。
- 战中 Gold 槽。
- 基础事件额外 Gold。

特殊构筑或事件可以在未来提供额外 Gold，但必须是命名规则，不进入当前中立修正基础经济。

MVP 第一版基础 Gold projection：

| 节点 | 收入 | 强制支出 | 可选支出 | 余额口径 |
|---|---:|---:|---:|---|
| 开局 | 0 | 0 | 0 | 0 |
| Battle 1 后 | +6 | 0 | 0 | 6 |
| Battle 2 后第一次商店 | +6 | 1 个中立修正：4 / 5 / 6 | 休整 0 / 3 | 12 - 中立修正 - 休整 |
| Battle 3 后 | +8 | 0 | 休整 0 / 3 | 20 - 中立修正 - 已购休整 |
| Battle 4 后 | +0 | 0 | 0 | 不变；获得第二次免费奖励 |
| Battle 5 后 Endpoint 前整备 | +0 | 0 | 休整 0 / 3 / 6 | 20 - 中立修正 - 已购休整 |
| Endpoint 后 | +0 | 0 | 0 | 局结束 |

Endpoint 前余额参考：

| 路线 | 中立修正花费 | 休整花费 | Endpoint 前 Gold |
|---|---:|---:|---:|
| 不休整，买补洞项 | 4 | 0 | 16 |
| 不休整，买主轴深化项 | 6 | 0 | 14 |
| 常规受压，买主轴深化项 + 2 次休整 | 6 | 6 | 8 |
| 高压力，买主轴深化项 + 4 次休整 | 6 | 12 | 2 |

这个 projection 只用于 MVP 第一版。它的目的不是清空 Gold，而是让 Gold 在第一次商店和反制后整备中有明确用途，并避免后半局继续发钱造成大额残留。

价格带：

| 类型 | Gold | 当前归类 |
|---|---:|---|
| 休整 | 3 | 只在 `Player Guardian` HP 受损后出现；MVP 第一版恢复 20 当前 HP，不提高最大 HP。 |
| 补洞项 | 4 | `Junk Sieve`、`Surge Buffer`、`Queue Brace`。 |
| 转向项 | 5 | `Pool Pocket`、`Front Recycle`、`Muster Pair`。 |
| 主轴深化项 | 6 | `Prime Charge`、`Echo Latch`、`Slot Primer`。 |

商店库存规则：

- 第一次商店在 Battle 2 后出现。若 Battle 1 和 Battle 2 都是普通胜利，进入第一次商店时玩家通常有 12 Gold。
- 第一次商店展示 3 个中立修正，至少 1 个补洞项。
- 第一次商店最多购买 1 个中立修正。这个限制只用于第一版 MVP 的 FTUE 和经济口径，不代表后续所有商店都只能买 1 个中立修正。
- 第一次商店的剩余 Gold 用于休整或保留到后续节点；休整不是中立修正，不消耗第一次商店的 1 个中立修正购买额度。
- 第二次奖励按主轴优先池生成。MVP 第一版不开第二次商店。
- 当前危险或已公开反制对应的补洞项必须提高出现优先级。
- 每个商店项只卖 1 次。
- MVP 第一版不做同列重复购买涨价。
- 价格带不按第一次商店的 12 Gold 上调；第一次商店通过购买额度控制信息量和买穿风险。

休整规则：

- 可见名称使用 `休整`，不使用 `修理 / Repair`。
- MVP 第一版效果：花费 3 Gold，恢复 `Player Guardian` 20 HP。
- 只恢复当前 HP，不提高最大 HP，不治疗战中单位，不返还 Gold，不提供下一局资源补偿。
- 休整作为战后商店服务项存在，不属于 `Launch / Tuning / Unit` 中立机器修正，不触发中立修正购买额度。
- 休整只在指定战后窗口开放：
  - 第一次商店中，如果 `Player Guardian` HP 受损，可以休整 1 次。
  - Battle 3 反制战胜利后，如果 `Player Guardian` HP 受损，可以休整 1 次。
  - Battle 5 反制战胜利后进入 Endpoint 前整备窗口；如果 `Player Guardian` HP 受损，可以休整最多 2 次。
  - 普通 Battle 1 / Battle 2 / Battle 4 后不单独开放休整窗口。
  - Endpoint 后不开放休整窗口。
- 第一次商店和 Battle 3 后窗口最多购买 1 次休整；Endpoint 前整备窗口最多购买 2 次休整。
- 失败直接结束本局，不进入休整窗口。
- Endpoint 前整备窗口不卖中立机器修正，不提供第二次商店，只允许休整和进入终点战。
- 后续版本可以给休整扩展其他恢复或整备作用，但必须重新声明价格、触发时机和结果页字段。

## 12. 仍未定

1. 精确 playtest 后最终平衡。
2. 休整的未来扩展作用。
3. 这些中立修正如何被 Hive 命名、包装或替换。
