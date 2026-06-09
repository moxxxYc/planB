# 球机物理表现 MVP v0 输入

**最后更新：** 2026-06-08
**仓库状态：** 文档主导，MVP v0 实现已在 `mvp/` 启动；本文不作为代码状态证明。
**文档状态：** MVP v0 实现输入。球机物理表现层的根决策已通过对话逐项确认，并已吸收 2026-06-08 `/plan-design-review` 提出的候选收口内容。用户已确认本文作为 MVP v0 的实现假设进入 `/implementation-handoff`，但这不等于最终 canon；钉子 / 活动块具体布局、层间随机范围、球物理参数和各 Guardian / 修正 / 反制的具体物理表现仍未定，未经 playtest，未最终锁定。

本文只记录球机的**物理表现与运动形态**。机器逻辑结算规则仍以 `docs/machine-warehouses.md` 为准；本文叠加在其之上，不替代其结算定义。战场规则见 `docs/battlefield-rules.md`，Guardian 见 `docs/guardian-system.md`，奖励经济见 `docs/rewards-economy.md`。

## 0. 草案边界声明

- 本文是 MVP v0 实现输入，不参与长期 canon 的文档权威顺序；当前确认状态是“进入 MVP v0 handoff 的实现假设”，不是“提升为最终正式规则”。
- 本文不新增机器逻辑规则，不改写 `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Unit slot`、`Queue`、`Deploy Lane` 的通用语义。
- 本文记录的物理形态是"如何把现有机器逻辑做成真物理球机"的方向，不是最终实现规格。
- 涉及的所有具体数值仍以 `docs/machine-warehouses.md` 的 first-pass 值为准；本文不发明新数值。
- `/plan-design-review` 已提出并写入同屏层级、物理反馈语法、灰阶可读规则和视觉身份约束；这些内容仍按候选草案处理。
- 第 17 节的五个候选决策已确认按当前写法进入 `/implementation-handoff`；它们是 MVP v0 实现假设，不是最终 canon。
- `docs/DESIGN.md` 已确认为 MVP v0 实现前置文档；handoff 应引用它，但仍需把最终美术资源和混音视为未定。

## 1. 目标

把 `concept.md` 的"物理出兵机器 / 物理球路"幻想，与 `docs/machine-warehouses.md` 的三仓机器逻辑统一成一台**真物理球机**：

> 玩家看得见球在机器里真实运动、真实落槽，并能把奖励、商店、Guardian、反制读成机器结构被可见地改写。

## 2. 结算模型：模型 A 真物理

- 采用**模型 A：真物理**。球的命中结果由**物理落点**决定，而不是先 roll 概率再播动画。
- `docs/machine-warehouses.md` 中的百分比（Route Board `65/15/15/5`、Tuning 槽宽 `55/15/15/15`）是**物理布局要逼近的目标分布**，由钉子 / 活动块 / 槽宽涌现，不是 RNG roll 出来的。
- 例外：强制落槽类 override（见第 8 节）允许逻辑强制某一颗球的落点。
- 这意味着单局存在自然方差。可读性靠物理结构、反馈和构筑改写支撑，不靠隐藏数值。

## 3. 三球机串联拓扑

三仓 = **三块串联的缩小版钉板结构**，在左侧竖条里自上而下垂直堆叠，球自上而下穿过。`Peglin 钉板` 只作为结构参考，不作为 UI 外观目标：

```text
左侧竖条 = 三块钉板结构串联：

┌──────────────────┐
│ 球机① Launch      │  顶部摆动炮台发球
│  · 钉 · 活动块 ·   │  钉子+活动块塑造弹跳
│   ·   ·    ·     │  底槽 = 进Tuning / Split / Recycle / Waste
└────┬─────────────┘
     │ 层间传递：范围内随机落点
┌────▼─────────────┐
│ 球机② Tuning      │  钉子+活动块
│  · 钉 · 活动块 ·   │  底槽 = Gate / Prime / Echo / Surge → 打 tuning_mark
└────┬─────────────┘
     │ 层间传递：范围内随机落点
┌────▼─────────────┐
│ 球机③ Unit        │  钉子+活动块 + Exposure 挡板
│  ·钉· 活动块·      │  底槽 = slot1 / slot2 / slot3 / slot4
│  [1][2][3][4]    │  落入已暴露槽 → 得 progress；未暴露 → 弹开继续运动
└──────────────────┘
   ↑__ Split / Recycle 球回流到 Pool；Waste 落废弃口
```

这个拓扑和 GDD 的"三仓"字面对应：三个 warehouse = 三块物理钉板。

## 4. 单板结构

每块球机都是一块缩小简略版的钉板结构：

- 顶部进球。
- 中间是**钉子 + 活动块**，塑造球的弹跳路径。
- 底部是一排**结果槽**，球最终落入某个槽，决定该板的结算结果。
- 钉子和活动块是物理结构，是 override 的物理化载体（见第 8 节）。

## 5. 层间传递：范围内随机落点

- 球从上一块板的底槽出来后，落入下一块板顶部时，**落点在一定范围内随机**。
- 这是层间的天然打散：使上一板的结果与下一板的落点**不完全正交，也不完全耦合**（折中弱打散）。
- 随机范围的大小直接决定正交程度和方差，**仍未定**，留作后续细化。

## 6. 发射机制：摆动炮台

- `Launch` 球机顶部是一个**自动来回摆动的炮台**，按 `Launcher` 节奏（first-pass 1.3s）发射 Pool 头部球。
- 炮台摆动让每颗球入射角不同，钉板弹跳路径不同，底槽落点自然有变化。
- 玩家**不控制炮台**，不瞄准。
- 炮台摆动范围、摆速、是否覆盖整板宽，**仍未定**。

## 7. 交互模式：全自动

- 球机**全自动**运行：炮台自动发球，球自动弹跳落槽。
- 玩家不直接操作球，不瞄准。
- 玩家只能通过两条间接路径影响球机：
  1. **构筑**：奖励 / 商店 / Guardian / 种族 / 反制改变钉子、活动块、槽宽等物理结构。
  2. **`Deploy Lane`**：决定 Unit 队列条目部署到哪一路。
- 这与 `docs/gdd.md` 的"玩家不直接操作"支柱和"战中输入是 Deploy Lane"一致。

## 8. override 物理化（A1）

承接模型 A 的 A1 选择：会改变球**路由**的 override 必须做成可见的物理改写。落地分两类：

### 8.1 倾向类（改分布）

- 通过改钉子 / 活动块 / 槽宽，改变落点**分布**。
- 例：改 Tuning 槽宽、`Pool Pocket` 多一个物理 Pool 槽、`Pool Polluter` 往板上塞 Junk 球。

### 8.2 强制落槽类（改单颗落点）

- 必须保证**某一颗指定球落进指定槽**；光改钉子只改概率，保证不了单颗。
- 需要**槽位强制导入表现**：目标槽必须用可见结构把这颗指定球强制引入，并带明显视觉，让玩家看出"这一颗是被机器强行掰进去的"，而不是自然弹进去。
- 第 17 节当前候选决策统一使用"导轨 / 引导槽"作为默认语言；吸入口、磁吸只保留为待确认备选，不作为实现默认。
- 例：酸冠母 `Tuning.Gate` miss 计数满后，强制下一颗本应进 Gate 的球落进 Prime 槽。

### 8.3 结算类保持逻辑（不物理化）

- 球**落定之后**的数值 / 进度效果不改变落点，保持逻辑结算，不做物理结构。
- 例：`Prime Charge`（value +1→+2）、Echo 复制结算、Surge 部署延迟、`Slot Primer`（progress floor）、`Queue Brace`（补 progress）。

## 9. 同屏布局：左右分屏

- 左侧竖条：三块串联球机。
- 右侧：三路战场（横向），含 `Deploy Lane` 点击、`Player Guardian`、`Endpoint Guardian`。
- 球机区和战场区都常驻可见，玩家可同时读球机和点路线。

## 10. 战中 1 秒扫视信息层级

战中 1 秒扫视只服务 3 个问题：

1. 下一次部署会去哪一路？
2. 这次部署来自哪条机器原因链？
3. 当前最危险的断裂是机器问题还是路线问题？

战中 HUD 优先级：

| Priority | 信息 | 屏幕位置 / 视觉处理 | 失败信号 |
|---|---|---|---|
| P0 | 当前 `Deploy Lane` + 下一次队列部署时间 + 最高危险路线 | 右侧战场上直接显示，稳定选中标记与短时危险标记分层 | 玩家以为点路会立刻造兵，或只跟危险提示点路 |
| P1 | 当前 active ball 的机器因果链 | 左侧球机只高亮当前球所在板和刚触发的结果槽，其他球降到背景层 | 玩家看不出 Unit progress 来自哪个球 |
| P2 | Queue head + 即将填满的 Unit slot | 左右连接处显示队列首项和目标路线标记 | 玩家不知道下一批兵去哪一路 |
| P3 | Pool / Forge / 炮台节奏 / 其他球 | 左侧常驻但低对比，只有变化时短闪 | 玩家被所有运动分散注意 |

默认不让三块球机板同等抢眼。当前 active ball 所在板、被反制攻击的组件和刚发生的结算结果可以短时抢 P1；其余物理运动保持背景可见。

## 11. 物理反馈状态语法

每次球机事件必须落入一种可见状态，不允许只闪一下。

| State | 触发 | 玩家看到 | 玩家读法 |
|---|---|---|---|
| Natural Hit | 球自然落入结果槽 | 槽口压下 / 咬合，球颜色保持自然，槽名短亮 | 这是物理落点决定的结果 |
| Forced Redirect | 命名规则强制改单颗落点 | 目标槽伸出导轨 / 引导槽，球出现短暂牵引线，源规则标记贴在槽边 | 这一颗被规则掰进去了 |
| Distribution Shift | 构筑改概率分布 | 钉子 / 活动块 / 槽宽发生永久或持续期形变，组件边缘保留来源小标记 | 以后更容易往这里走 |
| Blocked Bounce | Unit 未暴露区挡住球 | 挡板实体碰撞 + 反弹轨迹，不显示失败文字 | 球没消失，只是高级槽还没开 |
| Valid Unit Hit | 球进入已暴露 slot | slot 进度条吃入球，显示 `+value`，队列若生成则连线到 Queue head | 这个球推进了哪个单位槽 |
| Split Return | Launch Split | 球进入分裂回流通道，Pool 增加球时有回流路径动线 | 这是回流压力，不是直接出兵 |
| Recycle Return | Miss + Recycle | 球走回收通道，Pool 前 / 后位置按规则落位 | miss 但保住了输入流 |
| Waste | 无有效结算 | 球进入废弃口，短灰化，不弹错误弹窗 | 这颗没有产生有效机器结果 |
| Logic Settlement | Prime / Echo / Surge 等落定后效果 | 物理球已结束后，用槽位 / 队列的小标签展示数值或延迟变化 | 这是结算效果，不是第二颗物理球 |
| Counter Disruption | Pool Polluter / Echo Breaker / Stagger Punisher | 被攻击组件先预警，再显示生效结果，再留短暂痕迹 | 敌人打的是机器组件，不是随机加压 |

### 11.1 关键可见状态矩阵

| Feature | Normal | Success | Blocked / Failed | Forced / Override | Counter | Full / Capacity | Tutorial Read |
|---|---|---|---|---|---|---|---|
| Pool | 5-slot FIFO visible | ball enters / leaves with direction | Pool full rejects Recycle with clear lost-return feedback | N/A | Junk occupies visible slot | `current / capacity` and full outline | Player can point to supply buffer |
| Launcher | automatic 1.3s cadence | fired ball visibly leaves Pool | Pool empty shows dry-fire wait, no panic warning | N/A | counter can affect input only if named | N/A | Player sees launch rhythm |
| Launch Board | ball bounces through pins | Tuning / Split / Recycle / Waste slot bite | Waste greys out as no valid result | forced route uses guide rail if named | Pool Polluter marks input layer | N/A | Player sees supply vs miss vs return |
| Tuning Board | ball enters four-slot board | Gate / Prime / Echo / Surge label lights | Echo Breaker downgrades copy, not ball | Acid Crown forced Prime uses visible guide rail | Echo area cracks during warning | N/A | Player sees quality conversion |
| Unit Board | ball approaches slot bays | progress rises on exposed slot | blocked bounce off unexposed gate | slot-target rules mark target bay | Stagger warns Queue, not slot itself | slot progress overflow obeys machine rules | Player sees low-to-high slots open over time |
| Queue | next 3 entries visible | entry moves to selected lane on deploy tick | empty queue shows gap timer only when relevant | Surge marks accelerated entry | Stagger gap warning attaches here | N/A | Player sees deployment is delayed |
| Deploy Lane | selected lane stable | birth flash confirms lane | clicking current lane no-op, no spam effect | named batch lock rules must mark lock | danger uses separate shape / motion | N/A | Player sees click changes route, not output |
| Lane Danger | 0-3 visible state | pressure resolves by deployed units | danger persists if unresolved | N/A | Stagger can raise route to 2 | N/A | Player sees warning, not recommendation |

## 12. 灰阶 / 色盲可读规则

所有战中关键信息必须使用 color + shape + motion 三重编码。颜色可以加强识别，但不能单独承载规则含义。

| 信息 | Color | Shape | Motion |
|---|---|---|---|
| 当前 `Deploy Lane` | 玩家色 | 双轨边框 + 入口 / 出口箭头 | 稳定慢流动 |
| 路线危险等级 1 | 敌方色 | 小三角预告点 | 短脉冲 |
| 路线危险等级 2 | 敌方色 | Gate 外框锯齿 / 破门符号 | 快脉冲 |
| 路线危险等级 3 | 敌方色 | 基地圈裂纹 / 入侵符号 | 一次强闪 + 短音效 |
| 机器组件被反制 | 反制色或敌方色 | 组件局部裂纹 / 污染覆盖 / 断线符号 | 预警倒计时 + 生效残留 |
| 当前 active ball | 中性色高亮 | 球外环 | 连续轨迹短尾 |

最低验收口径：把战斗画面转成灰阶后，玩家仍应能区分当前选路、最高危险路线、被反制组件和当前 active ball。

## 13. 物理机器视觉身份约束

`Peglin 钉板` 只作为结构参考，不作为 UI 外观目标。

通用标签保持 `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`。视觉身份来自组件形态：

- `Launch`：读成供给和回流。Pool 口、回流管、废弃口和炮台必须比普通钉子更像机器组件。
- `Tuning`：读成转换质量。`Gate` 是宽出口；`Prime` 是充能槽；`Echo` 是双影 / 复写槽；`Surge` 是脉冲槽。四槽用形状区分，不只靠颜色。
- `Unit`：读成单位槽进度。四个 slot 是机器仓位，不是抽象 UI 条；Exposure Gate 是实体挡板。
- Hive 包装只改变材质、外壳、运动反馈和命名效果，不遮挡通用标签。

## 14. 保留的离散层

下列保持离散逻辑，不强行物理化：

- `Forge` 造球节奏（first-pass 2.2s）。
- `Pool` 作为可见 FIFO 缓冲（容量 5）。
- Unit `Queue` FIFO，每 0.5s 最多部署 1 个条目。
- `Loop Safety`：一颗物理球最多一个 Tuning 结果、一个 Unit hit、一个 queue entry。

物理球路从炮台发射口开始；供给区（Forge / Pool）保持离散缓冲表现。

## 15. 三板底槽映射

| 球机 | 对应仓 | 底部结果槽 | 槽含义（以 machine-warehouses 为准） |
|---|---|---|---|
| 球机① | `Launch` | 进 Tuning / Split / Recycle / Waste | Route Board 分流，目标分布 `65 / 15 / 15 / 5` |
| 球机② | `Tuning` | Gate / Prime / Echo / Surge | 打 tuning_mark，目标槽宽 `55 / 15 / 15 / 15` |
| 球机③ | `Unit` | slot 1 / slot 2 / slot 3 / slot 4 | 落入已暴露槽得 progress，未暴露弹开；Exposure baseline 见 machine-warehouses |

底部"宽度倾向"靠**槽宽物理宽度**还是**钉子引导**实现，**仍未定**。

## 16. 与现有 canon 的关系

| 现有 canon | 物理层处理 | 性质 |
|---|---|---|
| Tuning 槽宽 `55/15/15/15` | 落地为球机②底槽的物理分布 | 改述，不改逻辑 |
| Route Board `65/15/15/5` | 落地为球机①的钉子/活动块分流 | 改述，需定物理结构 |
| Exposure Gate "球弹开" | 球机③的物理挡板，本就是物理描述 | 无冲突 |
| Guardian / 修正 / 反制的路由类改写 | 物理化为钉子/活动块/强制导入（第 8 节） | 需逐个设计物理表现 |
| Guardian / 修正的结算类效果 | 保持逻辑 | 无冲突 |
| Forge / Pool / Launcher / Queue / Loop Safety | 保持离散 | 无冲突 |

本文不改动 `docs/machine-warehouses.md` 的任何逻辑数值与规则。

## 17. `/plan-design-review` 后的候选决策

以下五项来自 2026-06-08 `/plan-design-review` 的 deferred decisions。用户已确认五项按当前写法进入 MVP v0 `/implementation-handoff`；它们是实现假设和验收输入，不提升为最终 canon。

| Decision | MVP v0 handoff 决策 | 取舍理由 | 仍需验证风险 |
|---|---|---|---|
| 同屏焦点规则 | 当前 active ball 所在板获得 P1 焦点， inactive boards 降低对比但保持可见。被反制组件和刚结算槽可短时抢 P1。 | 三块板同等亮度会制造运动噪音；只聚焦 active ball 能保住 1 秒扫视。 | 降低对比后，玩家是否仍能理解三仓串联关系。 |
| 实时分布统计 | 战中不显示精确百分比；只显示物理槽形、组件变化和当前样本反馈。Debug / 结果页可以显示样本摘要。 | 战中显示百分比会把真物理读成隐藏概率表，玩家会和方差争论。 | 结果页样本摘要是否足够解释异常方差。 |
| 强制落槽形式 | 统一候选为“导轨 / 引导槽”语言：目标槽伸出短导轨接住指定球，并显示来源标记。Hive 可把导轨包装成虫壳轨 / 酸液导槽，但规则读法一致。 | 导轨能显示路径和因果，比磁吸或吸入口更不容易读成隐藏 RNG 修正。 | 某些未来来源是否需要更有魔法感或生物感的变体。 |
| 音频语言 | 每个物理状态有小型音频族：Natural Hit 轻扣，Forced Redirect 导轨咔哒 + 上扬，Blocked Bounce 硬挡，Split / Recycle 回流管声，Waste 闷落，Counter Disruption 预警三连 + 生效残响。 | 视觉负载高时，音频能帮玩家分辨自然命中、被迫改道、被挡、回流、废弃和反制。 | 最终声音资产和混音仍未定，不能让音频替代视觉可读。 |
| `docs/DESIGN.md` 时机 | 进入实现 handoff 前必须存在最小 `docs/DESIGN.md`，至少包含 art direction、color / shape tokens、HUD components、animation / audio vocabulary；当前已创建 `docs/DESIGN.md` 作为 MVP v0 前置。 | 没有设计系统时，第一版实现会意外决定视觉语言。 | `DESIGN.md` 仍是最小实现假设，最终字体、图标、材质、混音和无障碍对比需要实现后验证。 |

## 18. 仍未定

1. 底部"宽度倾向"靠槽宽物理宽度、钉子引导，还是二者组合。
2. 层间随机落点的范围大小（决定正交程度与方差）。
3. 各板钉子 / 活动块的默认布局与密度。
4. 炮台摆动范围、摆速、是否覆盖整板宽。
5. 球的物理参数基调（重力 / 弹性 / 速度）与同屏球数。
6. Split / Recycle / Waste 回流通道的具体物理形态。
7. Unit 板 Exposure 挡板的具体物理形态。
8. 每个 Guardian / 中立修正 / 反制的具体物理表现。
9. 精确 playtest 后的物理手感与可读性验证。
10. 第 17 节五个 MVP v0 handoff 决策的实际可读性是否达标。
11. 是否、以及何时把本草案提升为正式规则（需走 gstack-game 流程并经用户确认）。

---

## Design Review Status

| Review | Date | Score | Status |
|---|---|---:|---|
| `/plan-design-review` | 2026-06-08 | 4.1 -> 7.3 candidate integrated | `DONE_WITH_CONCERNS` |

评审 artifact：`docs/gstack-artifacts/yang-mvp-plan-design-review-20260608-151213.md`

### Incorporated Candidate Additions

1. 战中 1 秒扫视信息层级已写入第 10 节。
2. 物理反馈状态语法和关键可见状态矩阵已写入第 11 节。
3. 灰阶 / 色盲可读规则已写入第 12 节。
4. `Peglin 钉板` 仅作为结构参考的视觉身份约束已写入第 13 节。
5. 五个 deferred decisions 已整理为第 17 节，并已确认进入 MVP v0 `/implementation-handoff`；仍不是最终 canon。
