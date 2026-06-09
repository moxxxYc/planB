# MVP Hive Loadout

**最后更新：** 2026-06-09
**仓库状态：** 文档主导，MVP v0 实现已在 `mvp/` 启动；本文不作为代码状态证明。
**权威范围：** MVP v0 的 Hive 单位、Guardian、职责带和起始配置。

本文只记录 MVP v0 第一种族 Hive 的具体 loadout。MVP 做什么 / 不做什么见 `docs/mvp-scope.md`；机器规则见 `docs/machine-warehouses.md`；战场规则见 `docs/battlefield-rules.md`；Guardian 通用规则见 `docs/guardian-system.md`。

## 1. Hive 边界

MVP 需要 1 个正式种族。第一种族方向已确认为 Hive，并采用 `Caste Hive`：巢群分工阶级，用 4 个 `Unit slot` 表达从低承诺到高承诺的单位职责梯度。单位工作名、占位剪影和轻行为已定；两个 Guardian 的身份、轴倾向、技能结构、技能方向、差异化战术技能效果、战术技能冷却和中数值起点、战略技能目标、战略技能 operation、保守强度起点、战略计数重置口径、战术技能目标优先级、`酸冠反喷` 第一版范围和 `Guardian Contract` 第一版表已定；最终美术资源和最终数值仍未定。

种族必须提供：

- 4 个 Unit 槽的单位模板，必须符合低需求到高需求梯度。
- 可读的战场身份。
- 能表达 `Launch / Tuning / Unit` 三条构筑方向。
- 种族化视觉表现和可见 Machine Contract 改写，但不能拥有种族专属球机核心规则。Hive MVP 不做核心轴副名。
- 如果种族内容影响 `Unit.Slot.Exposure Gate`，必须走命名规则和 Machine Contract，不能作为默认种族时间表。

MVP 第一种族不采用 `Infection Hive` / 感染、孵化、寄生作为 baseline；该方向保留给未来其他种族或后续大内容。

Hive MVP 单位采用轻技能深度：每个单位只保留 1 个可见行为特征，不做主动技能、单位成长线、复杂状态或独立种族资源。单位行为必须服务球机读法，不能抢走 `Launch / Tuning / Unit` 的主系统位置。

Hive MVP 不为 `Launch / Tuning / Unit` 三条机器轴设置副名；构筑读法通过虫壳、酸液、巢脉材质、图标风格、组件外观、运动反馈和命名效果表达。未来种族如何命名和包装这些读法另行确认。

## 2. Unit Slot

Hive MVP 单位属性采用职责优先属性表，并使用中对比职责表作为第一版数值口径。每个单位只锁第一版核心属性起点，包括 HP、伤害、攻击间隔、移动速度、攻击范围和一个特殊行为参数。属性服务 4 个槽的职责读法，不在当前阶段追求完整战斗平衡表。

Hive 4 个 `Unit slot` 的 MVP 单位原型：

| Slot | `progress_required` | MVP 工作名 | 职责 | 攻击方式 | 可见行为特征 | 占位剪影 | 边界 |
|---|---:|---|---|---|---|---|---|
| Slot 1 | 3 | 短牙虫 | 稳定补线，快速接线。 | 近战轻咬。 | 快速进入接战点，无额外状态。 | 小体型、低伏身体、短牙前突。 | 不抗线，不爆发。 |
| Slot 2 | 5 | 盾壳虫 | 守线抗压，减少漏兵。 | 近战稳定攻击。 | 接敌后更能站住，承受第一轮接触压力。 | 宽壳、低重心、前盾状甲壳。 | 不快速推进。 |
| Slot 3 | 8 | 酸囊虫 | 破僵持，打开持续接战或门前卡住的局面。 | 短程酸液弹道，命中点小范围溅射。 | 用弹道和小溅射读成半远程破点。 | 背部或腹部酸囊、短喷口、短程喷射弧线。 | 不做持续炮台，不留酸池或 DoT，不替代 `Tuning` 的重复重击读法。 |
| Slot 4 | 12 | 碾壳兽 | 高承诺翻线，到线后明显推回战线。 | 同一路线接战点横扫重击。 | 横扫命中时明显压回战线。 | 大型厚壳、重前肢或重头部、明显压线体量。 | 不频繁出现，不跨路线，不做持续控场。 |

Hive 4 个 `Unit slot` 的第一版属性起点：

| Slot | 单位 | hp | attack_damage | attack_interval | attack_range | move_speed | 特殊行为参数 | 调试读法 |
|---|---|---:|---:|---:|---:|---:|---|---|
| Slot 1 | 短牙虫 | 6 | 1 | 0.7s | 1.5 | 10 | 同路最近目标，单体近战，无隐藏行为。 | 低 HP、低伤害、快移动、快攻击，用数量补线。 |
| Slot 2 | 盾壳虫 | 18 | 2 | 1.4s | 1.5 | 6 | 同路最近目标，单体近战，无嘲讽、无格挡光环。 | 更慢、更硬，减少漏兵，不快速推进。 |
| Slot 3 | 酸囊虫 | 8 | 3 | 1.8s | 7 | 7 | 弹道速度 14 路径单位/s；命中点同路溅射半径 2.5；最多命中主目标 + 2 个附近目标；目标死亡时打到目标死亡位置。 | 短程半远程破点，打破僵持，不做持续炮台。 |
| Slot 4 | 碾壳兽 | 26 | 6 | 2.6s | 2 | 5 | 同路接战点横扫 3.5 路径单位；最多命中 3 个目标；不击退，不跨路。 | 高承诺慢到场，低频横扫制造翻线。 |

这些数值和攻击几何是第一版职责读法起点，不是最终平衡。Slot 3 的半远程单位是 MVP 初期验证目标，只验证短程远程单位能否在 Hive 前线分工中被读懂，不展开完整远程兵种体系。具体最终美术资源、攻击频率和最终平衡仍未定。

## 3. Player Guardian

MVP 当前要求系统结构和 Hive 第一版开局入口清楚：

- MVP 第一版使用 2 个可选 `Player Guardian`。
- 选择发生在第一场战斗前。
- 选择后整局固定。
- Guardian 可以作为开局构筑锚点。
- 战术技能和战略技能固定。
- 战略技能走 Machine Contract。
- Hive 两个 Guardian 的身份、轴倾向、技能结构、技能方向、差异化战术技能效果、战术技能冷却和中数值起点、战略技能目标、战略技能 operation、保守强度起点、战略计数重置口径、战术技能目标优先级、`酸冠反喷` 第一版范围和 `Guardian Contract` 第一版表已确认，最终数值仍未定。
- Hive Guardian 技能结构为“弱守家 + 轻 Machine Contract”：每个 Guardian 有 1 个低强度自动守家战术技能，以及 1 个服务轴倾向的轻量战略技能。
- Player Guardian 有基础普通攻击作为防偷家手段，独立于战术技能存在；普通攻击可以清理少量入侵单位，但不能替玩家稳住持续漏线。基础攻击参数见 `docs/battlefield-rules.md`。
- Hive 两个 Guardian 的战术技能采用完全不同的自动守家规则，而不是同结构换表现；英雄特色需要在战术技能上可见，但仍不能独自解决漏兵或让玩家忽略三路稳线。
- Hive Guardian 战术技能效果已确认：`巢脉母` 使用 `巢脉牵缚`；`酸冠母` 使用 `酸冠反喷`，并允许有限卖血打法。
- Hive Guardian 采用单一 `Guardian Contract` 表记录战略和战术效果；表内用 `contract_layer=strategic_machine / tactical_battle` 区分结算层。`strategic_machine` 行进入机器结算，`tactical_battle` 行只进入战场 / Guardian 结算。
- Hive Guardian 技能方向采用轴内种族化表现改写：`巢脉母` 只在 `Launch` 内表达 Hive 回流 / 巢脉输送，`酸冠母` 只在 `Tuning` 内表达酸液弹道 / 命中反馈，两者都不跨轴直接补 `Unit`。
- Hive Guardian 战略技能目标采用折中方案：规则目标保持清楚，表现包装承担种族味。
- Hive Guardian 战略技能强度采用保守起点，避免 Guardian 选择压过第一次奖励和第一次商店。

Hive MVP `Player Guardian`：

| Guardian | 轴倾向 | 战术技能结构 | 战略规则目标 | 战略 operation | 种族化表现包装 | 玩家读法 | 边界 |
|---|---|---|---|---|---|---|---|
| 巢脉母 | `Launch` | `巢脉牵缚`：敌人进入玩家基地圈后，低频牵缚 / 减速入侵者；第一版为 8s 冷却、单目标、优先选择最接近 Player Guardian 的入侵者，距离并列时选最低 HP，4 damage、停顿 0.5s、减速 40% 持续 1.2s。 | `Launch.Recycle / Launch.Pool` | 隐藏 pity 伪随机 Recycle 强化：合法 Recycle 未触发强化时推进隐藏保底，触发时该次 Recycle 额外返回 1 个 clean ball，触发后重置。第一版基础触发概率为 15%，第 6 次合法 Recycle 保底触发。 | `Route Board / Recycle path` 表现为巢脉回流 / 巢脉输送。 | 更容易读到稳定补线、持续压线；基地被压时看到拖延。 | 软倾向，不锁死本局主轴，不直接生成更多单位，不跨轴直接补 `Unit`；普通攻击是基础防偷家手段，战术技能不能独自守住一路；基地圈内不按 `entered_from` 路线筛选；不改变 Route Board 概率、Pool 容量或 Recycle 标签继承规则，不绕过 Pool 满时的 Recycle 回流失败规则。 |
| 酸冠母 | `Tuning` | `酸冠反喷`：玩家 Guardian 受到实际 HP 伤害后，低频向攻击者反喷酸液并造成小范围低伤害；第一版为 6s 冷却，一次受击最多触发一次，冷却中受击不储存额外触发次数，攻击者 4 damage，以攻击者位置为中心在 Player base circle 内半径 3.0，最多 2 个附近入侵者各 1 damage。 | `Tuning.Prime` | Gate miss 计数：只有 `Tuning.Gate` 计数；第一版调参起点为 6 次 Gate miss 后，下次本应进入 `Gate` 的结果改为 `Prime`，触发后重置。 | `Gate -> Prime ingress` 表现为酸冠入槽，Prime 命中带酸液反馈。 | 更容易读到高价值命中、酸囊弹道、小范围破点；允许有限卖血反击。 | 软倾向，不替代奖励、商店和反制决策，不让酸囊虫变成持续炮台，不跨轴直接补 `Unit`；普通攻击是基础防偷家手段，战术技能不能独自守住一路；卖血必须消耗真实 HP，不治疗、不返还资源、不提高最大 HP、不降低本次受击伤害；基地圈内不按 `entered_from` 路线筛选；不把 `Echo / Surge` 计入 Prime miss，不统计 `Launch` 结果。 |

两个 Guardian 的战略计数都在每场战斗开始时重置为 0，不跨战斗保留。

Hive MVP `Guardian Contract` 第一版：

| Guardian | contract_layer | source | owner / warehouse | target component | trigger | operation | first-pass parameters | reset / scope | player read | guardrail |
|---|---|---|---|---|---|---|---|---|---|---|
| 巢脉母 | `strategic_machine` | `Guardian.StrategicSkill` | `Launch` | `Launch.Recycle.return_count` / `Launch.Pool` | 合法 `Recycle` 结算。 | `trigger` | 基础触发概率 15%；未触发时推进 hidden pity；第 6 次合法 `Recycle` 保底触发；触发时该次 `Recycle` 额外返回 1 个 clean value-1 ball。 | 每场战斗开始计数为 0；触发后 hidden pity 重置；整局固定。 | `Route Board / Recycle path` 表现为巢脉回流，玩家看到回流偶尔多吐一个 clean ball。 | 不改变 Route Board 概率、Pool 容量、Recycle 标签继承；Pool 满时仍按 Recycle 回流失败处理；不直接补 `Unit`。 |
| 巢脉母 | `tactical_battle` | `Guardian.TacticalSkill` | `Battlefield / Player Guardian` | `PlayerGuardian.base_zone_intruder` | 敌人进入玩家基地圈，且技能不在冷却中。 | `trigger` | `巢脉牵缚`：8s 冷却；在所有已进入 Player base circle 的敌人中，优先选择最接近 Player Guardian 的入侵者；距离并列时选最低 HP；4 damage；停顿 0.5s；减速 40% 持续 1.2s。 | 每场战斗开始冷却可用；战斗内按冷却循环。 | 基地被压时看到巢脉触须拖住最接近 Guardian 的入侵者。 | 不离开基地圈，不直接操作单位，不能独自守住一路，不替代基础普通攻击；基地圈内不按 `entered_from` 路线筛选。 |
| 酸冠母 | `strategic_machine` | `Guardian.StrategicSkill` | `Tuning` | `Tuning.Gate.to_Prime_override` | `Tuning` 结果为 `Gate`。 | `convert` | 只有 `Tuning.Gate` 计数；第 6 次 Gate miss 后，下次本应进入 `Gate` 的结果改为 `Prime`；触发后计数重置。 | 每场战斗开始计数为 0；触发后计数重置；整局固定。 | `Gate -> Prime ingress` 表现为酸冠入槽，玩家看到普通入口被酸冠推成 Prime。 | 不统计 `Echo / Surge`；不统计 `Launch` 的 Split / Recycle / Waste；不改变 Prime 槽宽；不提高 Prime value；不跨轴直接补 `Unit`。 |
| 酸冠母 | `tactical_battle` | `Guardian.TacticalSkill` | `Battlefield / Player Guardian` | `PlayerGuardian.damage_taken_response` | 玩家 Guardian 受到实际 HP 伤害，且技能不在冷却中。 | `trigger` | `酸冠反喷`：6s 冷却；一次受击最多触发一次；冷却中受击不储存额外触发次数；攻击者 4 damage；以攻击者位置为中心，在 Player base circle 内半径 3.0；最多 2 个附近入侵者各 1 damage。 | 每场战斗开始冷却可用；战斗内按冷却循环。 | 玩家看到 Guardian 被打后酸液反喷，允许有限卖血反击。 | 必须消耗真实 HP；不治疗、不返还资源、不提高最大 HP、不降低本次受击伤害；不能让玩家长期忽略三路稳线；基地圈内不按 `entered_from` 路线筛选。 |

## 4. 职责带调参

Hive 第一种族的 MVP 数值采用职责带口径，不采用一次性精确终局表。第一版调参要先保住 4 个 Unit slot 和 2 个 `Player Guardian` 的战场职责，再用战斗时长、失败率和软阈值护栏修正强度。

通用规则：

- 可以调 HP、伤害、攻击间隔、移动速度、攻击范围、弹道速度、溅射半径、横扫范围、Guardian 技能冷却和触发参数。
- 不能通过调数值抹掉单位职责，例如把 `短牙虫` 调成抗线单位，或把 `盾壳虫` 调成推进输出。
- 不能用 Guardian 战术技能补掉持续漏线；Guardian 只能处理少量入侵和表达英雄特色。
- 不用“所有单位 DPS 接近”作为目标。4 个 slot 的价值来自不同出场时机、进度需求和战场职责。
- 若完整短局失败率不达标，先查失败原因属于机器读法、敌人压力、路线漏兵、Guardian HP，还是 Unit slot 职责失衡，再改数值。

Unit 职责带：

| Slot | 单位 | 合格职责带 | 优先调参数 | 不合格信号 |
|---|---|---|---|---|
| Slot 1 | 短牙虫 | 快速接线，制造持续前线存在，帮助 `Launch sustained flow` 读法。能清理轻压或拖住第一接触，但不该单独抗住持续压力。 | `move_speed`、`attack_interval`、少量 HP。 | 如果它能长期守住一路，说明太肉或太快；如果 Battle 1 前 30 秒玩家看不到它接线，说明速度、发射节奏或 Slot 1 进度太弱。 |
| Slot 2 | 盾壳虫 | 守线抗压，减少漏兵，承受第一轮接触压力。它应该让一路不那么容易崩，但不该快速推进或破僵。 | HP、少量攻击间隔、少量移动速度。 | 如果它变成主要推进输出，说明伤害或速度过高；如果它只是慢版短牙虫，说明 HP 和接触反馈不够。 |
| Slot 3 | 酸囊虫 | 短程半远程破僵，命中点小范围溅射，能在僵持线造成一次可见打开。它是破点单位，不是持续炮台。 | `attack_damage`、`attack_interval`、`attack_range`、弹道速度、溅射半径、最多命中数。 | 如果玩家把它读成持续远程炮台，说明射程、频率或安全性过高；如果 Prime / Tuning 的高价值命中被它吃掉，说明它的爆发存在感过强。 |
| Slot 4 | 碾壳兽 | 高承诺晚到翻线，低频横扫在同一路线接战点制造路线翻转。它应该稀有、重、到场后有明显压线感。 | HP、伤害、攻击间隔、横扫范围、移动速度。 | 如果它频繁出现或常驻清场，说明 `progress_required`、闸门节奏或伤害过强；如果 Endpoint 前完全复盘不到贡献，说明到场时机、存活或横扫反馈太弱。 |

Guardian 职责带：

| Guardian | 合格职责带 | 优先调参数 | 不合格信号 |
|---|---|---|---|
| Player Guardian 基础攻击 | 普通防偷家手段。能清理少量入侵者，让玩家知道基地不是完全无防御；不能替玩家稳住持续漏线。 | 基础攻击伤害、攻击间隔、目标选择范围。 | 如果玩家可以长期忽略漏兵，基础攻击过强；如果少量入侵也必死，基础攻击过弱。 |
| 巢脉母 | `Launch` 软倾向。战略技能让 Recycle 偶尔多返回 clean ball，帮助稳定补线；战术技能低频拖住最接近的入侵者，制造守家可见性。 | Recycle 强化触发率、保底次数、`巢脉牵缚` 冷却、伤害、停顿和减速。 | 如果玩家选它后默认不需要第一次奖励或商店，战略技能过强；如果玩家看不到持续流差异，战略技能过弱或反馈不足。 |
| 酸冠母 | `Tuning` 软倾向。战略技能把 Gate miss 计数转成 Prime，帮助高价值命中读法；战术技能允许有限卖血反喷，但消耗真实 HP。 | Gate miss 计数门槛、`酸冠反喷` 冷却、主目标伤害、溅射目标数和范围。 | 如果卖血成为默认最优，战术技能过强；如果玩家看不到 Prime 转化差异，战略技能过弱或反馈不足。 |

职责带调参顺序：

1. 先保证 Battle 1 前 30 秒能看懂 `短牙虫` 接线、Slot 2 开放和基础机器链路。
2. 再保证 Battle 2-3 能看到 Slot 2 抗压、Slot 3 破僵或第一次奖励的战场兑现。
3. 再保证 Battle 5 和 Endpoint 前能复盘 Slot 4 或 Unit 构筑的高承诺兑现。
4. 最后用 `docs/mvp-learning-checkpoints.md` 的软阈值护栏检查 Guardian 选择率、成功率差距、Unit slot 关键队列占比和连续空窗战斗。

如果某个数值修改能提高胜率但破坏职责带，不能作为 MVP 正式调参方向；只能作为临时沙盒参数。
