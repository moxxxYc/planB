# Guardian 通用系统

**最后更新：** 2026-06-06
**仓库状态：** 文档主导，MVP v0 实现已在 `mvp/` 启动；本文不作为代码状态证明。
**权威范围：** Guardian 通用机制，不包含具体种族 Guardian 设计。

本文只定义 Guardian 作为系统的通用规则。战场表现见 `docs/battlefield-rules.md`，机器修正合同见 `docs/machine-warehouses.md`。

## 1. 定位

Guardian 同时承担两层职责：

1. 基地对象
   Guardian 是战场上的固定基地目标。它不移动、不寻路、不直接操作。

2. 开局构筑锚点
   每个种族可以提供多个可选 Guardian。玩家在单局开始前选择一个，影响本局的初始构筑倾向。

Guardian 不是第四机器轴，也不是英雄养成系统。

## 2. 可选规则

通用规则：

- MVP 第一版使用 2 个可选 `Player Guardian`。
- 两个 Guardian 都属于同一个正式种族。
- 具体种族 Guardian 的身份、名称和轴倾向由种族文档或 MVP 范围文档记录；本文件只保留通用规则。
- MVP 第一版每个可选 Guardian 采用“弱守家 + 轻 Machine Contract”技能结构：1 个低强度自动守家战术技能，加 1 个服务开局轴倾向的轻量战略技能。
- 具体种族 Guardian 可以采用不同的战术技能规则来表达英雄特色，但仍必须是低强度自动守家，不得变成强守家英雄或第四主系统。
- MVP 第一版的具体种族 Guardian 战略技能采用轴内种族化表现改写，不跨轴直接补 `Unit`，不替代奖励、商店和反制决策。
- 具体种族 Guardian 的战术技能行为参数和第一版合同表由 `docs/mvp-scope.md` 或种族文档记录；本文件不重复具体技能表。最终数值仍需后续调试。
- 选择发生在第一场战斗前。
- 选择后整局固定。
- 选择 Guardian 不能替代后续奖励、商店、事件和反制决策。
- MVP 第一轮 playtest 的 Guardian 选择率、成功率差距和守家影响只按 `docs/mvp-learning-checkpoints.md` 的软阈值护栏观察；这些护栏不是 Guardian 最终数值。

当前不做：

- 具体 Guardian 技能表。
- Guardian 装备系统。

## 3. Guardian 模板字段

| 字段 | 含义 |
|---|---|
| `guardian_id` | Guardian 标识。 |
| `race` | 所属种族。 |
| `stat_profile` | HP、基础攻击、攻击间隔、攻击范围等。 |
| `tactical_skill` | 固定战术技能，偏战斗内守家表现。 |
| `strategic_skill` | 固定战略技能，偏整局构筑影响。 |
| `axis_lean` | 可选软倾向，指向 `Launch / Tuning / Unit` 或种族单位模板。 |

## 4. 固定技能规则

Guardian 的战术技能和战略技能在单局开始时固定。

MVP 基础规则：

- 不解锁。
- 不升级。
- 不切换状态。
- 不在战斗中换技能。
- 不通过 Guardian 经验成长。
- 不做技能树。
- 不做英雄装备。
- MVP 第一版的技能结构是“差异化弱守家 + 轻 Machine Contract”，不是高频施法、强守家英雄或第四机器轴。

具体 Guardian 可以用单一 `Guardian Contract` 表记录战略和战术效果。表内必须声明 `contract_layer`：

- `strategic_machine`：进入机器结算，必须遵守 Machine Contract。
- `tactical_battle`：进入战场 / Guardian 结算，不改变 `Launch / Tuning / Unit`。

以后如果特殊事件或特殊机制要改写 Guardian 技能，必须作为命名规则单独声明，并重新评估是否仍服务球机主系统。

## 5. 战术技能

战术技能负责基地防守表现。

Player Guardian 的基础普通攻击是防偷家的普通手段，独立于战术技能存在。战术技能负责英雄特色和低频反应，不能替代基础攻击，也不能把 Guardian 做成独自稳线的强守家单位。

可以是：

- 周期性横扫。
- 低血量脉冲。
- 基地被入侵时提高攻击频率。
- 对进入基地圈的敌人施加短暂可见效果。
- 基础攻击的特殊规则。

边界：

- 应自动或被动触发。
- 不要求玩家高频施法。
- 不接受直接单位控制。
- 不应强到独自解决漏兵。
- 不应让玩家忽略三路稳线。

## 6. 战略技能

战略技能负责开局构筑倾向。

合法目标：

- `Launch` 的命名组件。
- `Tuning` 的命名组件。
- `Unit` 的命名组件。
- 种族定义的单位模板。
- 可见敌方 debuff。

每个战略技能必须遵守 Machine Contract：

- `source=Guardian`
- owner warehouse
- target component
- operation type
- duration / scope
- player read
- failure risk

战略技能应是软倾向：

- 玩家第一场战斗前能读出它偏向什么。
- 它不能锁死本局主轴。
- 后续奖励、商店和反制应对仍能让玩家转向或补洞。

禁止：

- 全单位加伤害。
- 全输出提高。
- 全敌人变弱。
- 直接生成更多单位但不说明机器组件。
- 让 Guardian 选择比后续机器构筑更重要。

## 7. Guardian 与战场

战场层 Guardian 规则由 `docs/battlefield-rules.md` 负责。

通用边界：

- Guardian 可以看起来像英雄。
- 规则上它是固定基地对象。
- 它不移动。
- 它不离开基地圈。
- 它不和敌方 Guardian 对打。
- 它不接受玩家直接操作。
- 单位进入基地圈后，Guardian 基础攻击和战术技能按基地圈内空间关系选目标，不再按路线筛选。
- 单位可以保留 `entered_from = Left / Mid / Right` 作为危险来源、日志或结果页字段，但不能用作 Guardian 战斗筛选规则。

## 8. Guardian 宝物槽

`Guardian Treasure Slot` 是 MVP 后扩展，当前只记录方向，不进入 MVP。

未来方向：

- 一个 Guardian 只有 1 个宝物槽。
- 宝物在单局内获得。
- 只能战前换，不能战中换。
- 宝物效果必须走 Machine Contract。
- 宝物不能用来修补 MVP 当前的清晰度、反制或构筑深度问题。

当前不做：

- 宝物掉落池。
- 宝物 UI。
- 战前换装流程。
- Guardian 装备成长。
- 局外 Guardian 养成。

## 9. 仍未定

1. 两个 Guardian 调试后的最终数值。
2. 两个 Guardian 的具体最终参数。
3. Guardian 选择在 UI 上如何展示其软倾向。
4. Guardian 战略技能如何避免硬锁构筑。
5. Guardian 战术技能如何避免自动守家过强。
