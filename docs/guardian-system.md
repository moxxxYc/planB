# Guardian 通用系统

**最后更新：** 2026-06-04
**仓库状态：** 纯文档态，无当前正式实现。
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
- 两个 Guardian 的身份、名称、技能和数值等第一种族设计阶段再定。
- 选择发生在第一场战斗前。
- 选择后整局固定。
- 选择 Guardian 不能替代后续奖励、商店、事件和反制决策。

当前不做：

- 具体 Hive Guardian。
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

以后如果特殊事件或特殊机制要改写 Guardian 技能，必须作为命名规则单独声明，并重新评估是否仍服务球机主系统。

## 5. 战术技能

战术技能负责基地防守表现。

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

1. 两个 Guardian 的具体身份、名称和种族包装。
2. 两个 Guardian 的战术技能。
3. 两个 Guardian 的战略技能。
4. Guardian 选择在 UI 上如何展示其软倾向。
5. Guardian 战略技能如何避免硬锁构筑。
6. Guardian 战术技能如何避免自动守家过强。
