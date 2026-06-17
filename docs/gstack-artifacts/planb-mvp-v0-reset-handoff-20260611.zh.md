# 实现交接文档：PlanB MVP v0 Reset

Slice plan：无。用户在本次会话中选择完整 MVP 6 战 handoff。
分支：`codex/implementation-design-gap-repair`
日期：2026-06-11
状态：Reset handoff artifact。本文本身不等于实现批准。

## 0. 权威来源与 Reset 规则

本文面向旧实现归档后的 reset 状态。

当前输入：

- `README.md`
- `AGENTS.md`
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

作为 MVP v0 实现输入，但不是长期 canon：

- `docs/ball-machine-physical.md`

不能作为当前实现来源：

- `docs/archive/`
- `docs/archive/implementations/godot-mvp-v0-20260611/`
- 旧 `mvp/` 验证脚本
- 旧 Web MVP
- 旧 Battle Lab
- 已归档生成资源

在用户明确确认实现计划之前，不创建代码、Godot 工程、构建脚本、资源或验证脚本。

## 1. 构建目标

一句话目标：

> 实现 PlanB MVP v0 的完整 Godot 短局目标：`Main Menu -> Guardian Contract -> Battle 1 -> Reward 1 -> Battle 2 -> Shop / Rest -> Battle 3 -> Rest -> Battle 4 -> Reward 2 -> Battle 5 -> Endpoint Prep -> Endpoint -> Final Result`，证明 `Launch / Tuning / Unit` 机器选择能在 15-20 分钟短局中转化为可读的三路战场结果。

验证假设：

> 玩家能完成或失败一局 6 战短局，并能解释本局主要是通过 `Launch` 持续流、`Tuning` 高价值命中、`Unit` 批量 / 锚点价值、敌人反制压力、`Deploy Lane` 落点或 Guardian HP 压力赢下或输掉。

这个 build 的核心：

1. 机器到前线的因果链必须可见：物理球结果 -> Unit progress -> Queue -> 当前出兵口 -> 路线状态。
2. 奖励、商店项、Guardian 契约和敌人反制必须读成机器组件变化，不能读成泛用 buff 或随机惩罚。
3. `Deploy Lane` 必须保持“部署落点选择”。如果它变成主要玩法，MVP 失败。

如果这三点失败，即使 6 战流程能跑通，也没有测到 PlanB。

## 2. 范围

### 范围内

- [ ] MUST：新的 Godot 4.6 GDScript 工程目标，使用 Compatibility / `gl_compatibility`，作为 fresh implementation path，不从归档恢复。
- [ ] MUST：完整玩家流程，从 Main Menu 到 Final Result。
- [ ] MUST：Battle 1 前的 Guardian Contract，包含两个 Hive Player Guardian：`巢脉母` 和 `酸冠母`。
- [ ] MUST：6 个战斗节点：Battle 1、Battle 2、Battle 3、Battle 4、Battle 5、Endpoint。
- [ ] MUST：Battle Screen 布局遵循 `三仓机器 38% | Queue / Deploy Bridge 14% | 战场 48%`。
- [ ] MUST：三块竖向机器板：`Launch`、`Tuning`、`Unit`。
- [ ] MUST：机器板使用 `docs/ball-machine-physical.md` 的物理球表现，MVP v0 实现假设为真物理落点。
- [ ] MUST：`Launch` 包含 Forge、Pool、Launcher、Route Board、Split、Recycle、Waste、Junk 处理。
- [ ] MUST：`Tuning` 包含 `Gate / Prime / Echo / Surge`，并有可见结果反馈。
- [ ] MUST：`Unit` 包含 4 个 slot、`progress_required = 3 / 5 / 8 / 12`、Exposure Gate 时间、progress、overflow、Queue。
- [ ] MUST：Queue 最多每 0.5s 部署一个 FIFO entry，并读取当前 `Deploy Lane`。
- [ ] MUST：`Deploy Lane` 通过直接点击战场路线选择。不做主要三按钮选路面板。
- [ ] MUST：三路战场，固定 `Left / Mid / Right` 路径，包含 Lane Gate、基地圈、出兵口、Player Guardian、Endpoint Guardian。
- [ ] MUST：玩家单位从当前路线出兵口出生，不从 Guardian 身上出生。
- [ ] MUST：Hive 单位 loadout：`短牙虫`、`盾壳虫`、`酸囊虫`、`碾壳兽`。
- [ ] MUST：敌人模板：`Enemy Grunt`、`Enemy Raider`、`Enemy Brute`。
- [ ] MUST：Battle 3 根据当前最强 / 最暴露的轴，从 `Pool Polluter`、`Echo Breaker`、`Stagger Punisher` 中选择一个反制家族。
- [ ] MUST：Battle 5 使用 1-2 次更强反制，优先复测同家族，也可攻击相邻弱点。
- [ ] MUST：Endpoint 包含 Endpoint Guardian 行为、可预警扫击和 1 个反制家族。
- [ ] MUST：Reward 1 固定为三轴锚点 3 选 1：`Pool Pocket`、`Prime Charge`、`Slot Primer`。
- [ ] MUST：Battle 2 后第一次商店，从 `Front Recycle`、`Junk Sieve`、`Surge Buffer`、`Queue Brace`、`Muster Pair` 中展示 3 个中立修正，至少 1 个补洞项。
- [ ] MUST：第一次商店最多购买 1 个中立修正；Rest 独立，不消耗中立修正购买额度。
- [ ] MUST：Battle 4 后给 Reward 2，免费 2-3 选项，按当前主轴优先，且至少包含一个补洞或转向项。
- [ ] MUST：Gold faucet 为 `0 / +6 / +6 / +8 / +0 / +0 / +0`，无击杀 Gold，无失败 Gold。
- [ ] MUST：结果页记录 6 个 MVP 学习检查点；Final Result 记录主轴、关键选择、反制、Deploy Lane 影响、Guardian HP 压力和 next-run watch tag。
- [ ] SHOULD：用数据资源或等价可编辑配置支持快速战斗脚本调试。
- [ ] SHOULD：包含开发用验证场景或命令，但不出现在 player-facing flow 中。
- [ ] SHOULD：检查当前路线、危险路线、active ball、反制目标在灰阶 / 色盲场景下仍可读。
- [ ] COULD：为部署、命中、反制预警、强制导轨、结果切换加入占位音频族。

### 范围外

- PVP、联网、账号、后端、匹配、Steam 集成。
- 第二种族、Mech、Arcane、Infection Hive baseline。
- 完整遗物池、完整事件池、完整敌人表、完整 Boss 阵容。
- 局外成长、Guardian 装备、Guardian 宝物槽、Guardian 升级树。
- 自由 RTS 地图、复杂寻路、直接单位控制。
- `Overdrive` 作为基础按钮。
- 最终美术、最终 sprite sheet、最终字体、最终混音。
- 任何归档实现结构或旧验证命令作为当前权威。

### 可以占位

- Hive 单位、敌人、Guardian、Endpoint sprite 可以是稳定可读剪影。
- 机器钉子、槽、导轨、Pool 球、Unit slot 可以是几何占位。
- 奖励 / 商店卡可以使用轴 icon + 清晰文字。
- 战场路线可以是简单轻弧形线。
- 波次脚本可以是一版手写 encounter，不需要程序化 encounter pool。
- 结果页可以文字较重，只要 cause tag 和学习字段清楚。
- 音频可以没有或简单占位。视觉可读不能依赖音频。

### 完全延后

- 最终 playtest 平衡。
- 钉子布局、活动块、炮台摆动、球参数、层间随机、同屏球数的最终物理参数。
- `Unit.Slot.Exposure Gate` 从开始暴露到完全暴露之间的插值方式。
- 最终 sprite sheet、pivot、碰撞区、动画 polish。
- 超过 6 战或分支路线图。
- 超过 9 个中立修正效果。
- 深度 save / continue 流程。

## 3. 玩法需求

| 玩家动作 | 预期响应 | 时机 | 体验目标 |
|---|---|---|---|
| 开始新局 | Main Menu 进入 Guardian Contract。 | 立即或短转场。 | 玩家进入短局，不是 debug sandbox。 |
| 选择 Guardian | `巢脉母` 或 `酸冠母` 卡高亮，显示机器倾向、战术防守、风险。 | 同帧 / 下一帧。 | 契约选择，不是英雄控制。 |
| 确认 Guardian | Battle 1 打开，并显示已选 Guardian 身份和契约标记。 | 立即或短转场。 | 机器启动前，玩家知道本局锚点。 |
| 观察 Battle 1 前 30 秒 | 玩家看到 Forge、Pool、Launcher、Tuning result、Unit progress、Queue、选中路线、路线危险。 | 前 30 秒内。 | 不暂停也能学会基础机器链路。 |
| 点击战场路线 | 当前路线高亮、出兵口、queue landing marker、Bridge 连线更新。 | 同帧 / 下一帧。 | 直接选路，没有按钮面板感。 |
| Queue entry 部署 | Queue head 移动 / 闪烁，Bridge 指向当前出兵口，出兵口闪光，单位出生。 | 部署前后 0.3-0.5s 可见确认。 | “机器输出落到这里”。 |
| 球命中 `Gate / Prime / Echo / Surge` | Tuning 槽咬合 / 亮起，Unit progress 或 logic settlement 可见。 | 落槽时立即。 | 调校质量转换，不是随机闪光。 |
| 球打到未暴露 Unit 区域 | 球从实体挡板反弹。 | 立即碰撞反馈。 | “还没开放”，不是“球消失了”。 |
| 选择 Reward 1 | 卡牌显示轴、组件、operation、玩家读法，影响后续战斗反馈。 | 选择立即，Battle 2-3 看到战场兑现。 | 第一次真实机器承诺。 |
| 进入 Shop / Rest | 显示 Gold、购买额度、商品角色、Rest 费用、Rest 可用性和机会成本。 | 立即。 | 购买是机器决策，不是比数字大小。 |
| 看到反制预警 | 目标机器组件在生效前收到预警；只有产生战场威胁时路线危险升高。 | 反制前 3-5s。 | 敌人在攻击组件，不是系统偷偷惩罚。 |
| 反制生效 | Pool Junk、Echo 降级或 Stagger raid 显示被攻击组件和战场后果。 | 活跃窗口内。 | 玩家能说出被攻击的弱点。 |
| 选择 Reward 2 | UI 显示当前主轴，并提供 deepen + patch / pivot 选项。 | 立即。 | 当前构筑形状变清楚。 |
| 打 Endpoint | Endpoint Guardian 扫击有预警，破门后形成基地圈输出窗口。 | 扫击命中前 1.2s 预警。 | 期末考试，不是高 HP 木桩。 |
| 完成或失败 | Final Result 写出主轴、选择、反制、路线影响、Guardian HP 压力、胜负原因、next watch tag。 | 局结束时。 | 一局结束后留下一个清楚教训。 |

## 4. 系统需求

| 系统 | 职责 | 当前是否存在 | 说明 |
|---|---|---|---|
| Godot Project | Fresh Godot 4.6 GDScript Compatibility 工程目标。 | 无当前活动工程 | 不恢复归档 `mvp/` 作为当前源。 |
| Run Flow | 页面和 6 个战斗节点路由。 | 无当前实现 | 必须支持胜利和失败结束。 |
| Guardian Contract | 整局固定选择一个 Guardian。 | 设计已锁 | 需要 UI 和数据。 |
| Machine Simulation | 运行 Forge、Pool、Launcher、三板结果、Machine Contract、反制。 | 设计已锁，暂无实现 | 物理表现必须映射逻辑。 |
| Physical Machine View | 显示三板球运动、结果槽、强制导轨、blocked bounce、counter disruption。 | 暂无实现 | 精确物理参数属于调试项。 |
| Unit Queue | FIFO queue、部署节奏、queue preview、Deploy Bridge。 | 设计已锁 | 核心信号。 |
| Battlefield | 三路固定路线、单位、门、基地圈、Guardian、Endpoint 行为。 | 设计已锁 | 不做自由 RTS 寻路。 |
| Deploy Lane Input | 直接点击战场路线。 | 设计已锁 | 不做主要侧边按钮。 |
| Enemy Waves | 6 战脚本压力曲线。 | 设计已锁，精确脚本待定 | 敌人数量和时间属于调试项。 |
| Counter System | Pool Polluter、Echo Breaker、Stagger Punisher。 | 设计已锁 | 必须预警并留下可见痕迹。 |
| Rewards / Shop / Rest | Reward 1、Battle 2 后 Shop、Rest 窗口、Battle 4 后 Reward 2。 | 设计已锁 | 最终平衡未锁。 |
| Result / Telemetry | 记录学习检查点字段和最终 cause tag。 | 设计已锁 | 玩家结果页不能变 debug dump。 |
| Verification | 定义新的当前验证命令。 | 未定义 | 实现计划阶段创建，不能借用归档脚本。 |

## 5. 资源需求

| 资源 | 真实或占位 | 规格 |
|---|---|---|
| Global base chassis | 必须有真实布局 | Race-neutral 2.5D 战争台，三段 Battle Screen。最终美术可等。 |
| Machine boards | 必须有可读几何 | 三块板标记 `Launch`、`Tuning`、`Unit`，含钉子、槽、active ball、结果反馈。 |
| Active ball | 必须真实 | 支持 active-ball 高亮和因果链读法。 |
| Forced redirect guide | 必须真实 | 短导轨 / 引导槽。纯文字强制结果不可接受。 |
| Blocked bounce | 必须真实 | Unit Exposure 的实体挡板 / 反弹反馈。 |
| Queue Bridge | 必须真实 | Bridge 指向当前出兵口。这是 build 的核心之一。 |
| Spawn ports / Lane Gates | 必须有剪影 / 结构 | 与 Guardian 分离，每路一个。 |
| Lane danger markers | 必须真实 | 形状 + 动效 + 颜色与选中路线分离。 |
| Hive units | 可占位 | 稳定剪影，职责可读。 |
| Guardians | 必须是战场实体 | 大剪影，附着 HP / 战术反馈。 |
| Endpoint Guardian | 必须是战场实体 | 需要可预警扫击反馈。 |
| Reward / shop cards | 可占位 | 轴、组件、operation、玩家读法、价格 / 额度。 |
| Audio | 可占位 | 无音频时视觉仍必须足够。 |

## 6. 战斗与学习序列

| 节点 | 必须教学 / 验证 | 内容 | 通过信号 |
|---|---|---|---|
| Guardian Contract | Guardian 是本局契约，不是可控英雄。 | 选择 `巢脉母` 或 `酸冠母`。 | 玩家能说出契约偏向哪条机器轴。 |
| Battle 1 | 基础机器链路和 Deploy Lane 边界。 | 90-110s，单路轻压，无反制。 | 玩家能解释 ball -> Tuning -> Unit progress -> Queue -> selected lane。 |
| Reward 1 | 第一次轴承诺。 | `Pool Pocket` / `Prime Charge` / `Slot Primer`。 | 玩家能说出所选轴和预期战场兑现。 |
| Battle 2 | 当前机器方向开始成形。 | 100-125s，双路压力，无反制。 | 玩家开始看到持续流 / 高价值命中 / 锚点槽兑现。 |
| Shop / Rest | Gold 是机会成本，商店是机器补洞 / 转向。 | 若 B1+B2 胜利为 12 Gold，一个中立修正额度，可选 Rest。 | 玩家理解为什么不能买完所有中立修正。 |
| Battle 3 | 第一次反制攻击当前机器弱点。 | 115-140s，一个反制家族。 | 玩家能识别 Pool / Echo-Surge / Queue gap 被攻击。 |
| Rest Window | HP 压力能用成本回应。 | 受伤时可选 Rest。 | 玩家看到 Rest 是 HP sink，不是机器修正。 |
| Battle 4 | 商店选择验证补洞或转向。 | 105-130s，无反制，路线压力。 | 玩家能看出商店选择是否帮上忙。 |
| Reward 2 | 当前主轴深化或补暴露出来的洞。 | Battle 4 后免费 2-3 选。 | 玩家能区分 deepen current axis 和 patch / pivot。 |
| Battle 5 | 更强反制复测构筑。 | 125-150s，1-2 次反制触发。 | 玩家能看到构筑是否扛住第二个压力峰。 |
| Endpoint Prep | 终点前最后 HP 决策。 | 可选 Rest，不发新 Gold。 | 玩家看到剩余 Gold 是生存与历史机会成本。 |
| Endpoint | 期末考试。 | 165-195s，Endpoint Guardian，可预警扫击，一个反制家族。 | 玩家能用机器轴、反制、路线或 Guardian HP 压力解释胜负。 |
| Final Result | 整局学习。 | 总结页。 | 玩家离开时有一个 `next_run_watch_tag`。 |

## 7. 验收标准

### Engineering Done

- [ ] 新 Godot 工程只在明确实现批准后创建。
- [ ] 当前验证命令已记录，且不依赖归档脚本。
- [ ] Main Menu 可以开始新局。
- [ ] Guardian Contract 可以选择任一 Guardian 并进入 Battle 1。
- [ ] 6 个战斗都可以按顺序进入。
- [ ] 每场战斗都可以胜利和失败。
- [ ] 机器模拟通过 `Launch / Tuning / Unit` 产生 queue entries。
- [ ] Queue 将 entry 部署到当前 `Deploy Lane`。
- [ ] 三路战场支持单位、门、基地圈、Player Guardian、Endpoint Guardian。
- [ ] Reward 1、Shop / Rest、Reward 2、Endpoint Prep、Final Result 可达。
- [ ] Gold faucet 和第一次商店购买额度符合正式文档。
- [ ] 反制生效前有预警，并攻击正确机器组件。
- [ ] Player-facing screen 不暴露 dev slider、telemetry dump、旧 debug route 或 implementation-state text。

### Design Done

- [ ] Battle 1 中，测试者能用自己的话解释基础机器链路。
- [ ] 点击路线后，测试者理解它改变的是未来部署位置，不是机器产出。
- [ ] Reward 1 后，测试者能说出所选轴和预期战场兑现。
- [ ] Battle 3 中，测试者能识别反制攻击了哪个机器组件。
- [ ] 第一次商店后，测试者能解释为什么买一个中立修正是取舍，不是比价格。
- [ ] Reward 2 后，测试者能区分 deepen 与 patch / pivot。
- [ ] Endpoint 中，测试者能在伤害前看到扫击预警。
- [ ] Final Result 能用机器轴、奖励 / 商店、反制、Deploy Lane、Guardian HP cause tag 解释本局。
- [ ] build 保留核心：机器原因变成战场结果，Deploy Lane 不取代机器承诺。

### Not Done Until

- [ ] 非实现者从 Main Menu 玩到至少 Battle 3。
- [ ] 非实现者玩到或观看模拟完整 run 到 Final Result。
- [ ] 至少检查一条胜利路径和一条失败路径。
- [ ] 测试者能回答：“我的第一次奖励改了机器的什么？”
- [ ] 测试者能回答：“我是因为机器弱点、路线落点、反制压力还是 Guardian HP 输的？”
- [ ] Battle Screen 截图无文字重叠、无 debug UI。

## 8. 已知风险

| 风险 | 影响 | 诱人的捷径 | 为什么会毁掉体验 |
|---|---|---|---|
| 完整 6 战范围过宽 | Critical | 浅做所有屏幕，机器因果含混 | 因果弱的完整流程测不到东西。 |
| 物理机器变成假 RNG 动画 | Critical | 先 roll 结果，再播球动画 | 破坏已确认的 MVP v0 真物理假设。 |
| 物理调参吃掉整个 milestone | Critical | 在 run loop 存在前调钉子到完美分布 | MVP 先需要会话学习，精确分布是 playtest 调参。 |
| Queue Bridge 只有文字 | Critical | 只显示 `Current lane: Mid`，跳过可视 Bridge | 玩家看不到机器到战场的因果。 |
| Deploy Lane 变成主要玩法 | Critical | 危险提示太强，奖励最优点灯救火 | 玩家忽略机器，MVP 失败。 |
| 反制像随机事件 | High | 没有组件预警就直接生效 | 玩家读成惩罚，不读成机器弱点。 |
| 奖励 / 商店卡变成泛用 buff | High | 只显示名字和数值变化 | 玩家学不到 `warehouse -> component -> operation`。 |
| Guardian 变成英雄单位 | High | 让 Guardian 可控或从 Guardian 出兵 | 破坏 Guardian 系统和战场拓扑。 |
| 结果页变成 debug telemetry | High | 倾倒所有 tracking 字段 | 玩家看到数据，但看不到原因。 |
| Unit slot 3 或 4 过早统治 | Medium | 为了爽感调强，而不是遵守 exposure timing | Unit 变成默认最优轴。 |

不要走这些捷径：

1. 不要恢复归档 `mvp/` 作为当前实现。
2. 不要用归档验证脚本作为当前验证。
3. 除非用户改变设计，不要用隐藏 RNG 替代真物理球落点。
4. 不要从 Guardian 身上出兵。
5. 不要新增主要三按钮选路面板。
6. 不要让反制静默或无预警。
7. 不要把所有奖励读法都做成“更多兵”。

## 9. 实现里程碑

这些是执行顺序，不是单独的设计批准。

### M0：Fresh Godot Project And Validation Contract

目标：创建新的当前 Godot 工程目标和当前验证命令。

MUST：

- Godot 4.6、GDScript、Compatibility / `gl_compatibility`。
- Fresh project directory，不从归档恢复。
- 记录新的当前验证命令。
- Minimal Main Menu 可打开。

实现前 GodotPrompter skills：

- `godot-prompter:godot-project-setup`
- `godot-prompter:scene-organization`
- `godot-prompter:godot-testing`

### M1：Machine-To-Queue-To-Lane Core

目标：Battle Screen 在一场战斗内证明核心因果。

MUST：

- 三板机器显示。
- Ball result -> Unit progress -> Queue。
- Queue Bridge -> selected spawn port。
- 直接点击路线。
- Battle 1 胜 / 败路径。

GodotPrompter skills：

- `godot-prompter:physics-system`
- `godot-prompter:resource-pattern`
- `godot-prompter:godot-ui`
- `godot-prompter:input-handling`

### M2：Full Run Flow And Economy Skeleton

目标：从 Guardian Contract 到 Final Result 的完整节点序列存在。

MUST：

- Guardian Contract。
- Reward 1。
- Battle 2。
- First Shop / Rest。
- Battle 3。
- Rest window。
- Result routing。

GodotPrompter skills：

- `godot-prompter:resource-pattern`
- `godot-prompter:godot-ui`
- `godot-prompter:hud-system`

### M3：Counters, Reward 2, Battle 4-5

目标：反制学习和 patch / deepen 循环可运行。

MUST：

- Pool Polluter、Echo Breaker、Stagger Punisher。
- Battle 4 商店验证。
- Reward 2 current-axis pool。
- Battle 5 更强压力。

GodotPrompter skills：

- 如需要解耦，使用 `godot-prompter:event-bus` 或等价 signal 指导。
- `godot-prompter:component-system`
- `godot-prompter:tween-animation`

### M4：Endpoint And Final Result

目标：完整 6 战 MVP 可以胜利或失败。

MUST：

- Endpoint Guardian。
- Telegraphed Sweep。
- Endpoint Prep Rest window。
- Final Result，包含 run-level cause tag 和 next-run watch tag。

GodotPrompter skills：

- `godot-prompter:animation-system`
- 只有当 VFX polish 影响可读性时才用 `godot-prompter:particles-vfx`。
- 实现后使用 `godot-prompter:godot-code-review`。

## 10. 测试钩子

| 测什么 | 怎么测 | 通过标准 |
|---|---|---|
| 工程健康 | 运行新的当前验证命令。 | 通过，且不使用归档脚本。 |
| Battle 1 学习 | 观察前 30 秒。 | 测试者能解释 machine -> Queue -> Deploy Lane。 |
| 点路边界 | Queue 有 entry 时点击路线。 | 测试者说未来部署会变，当前单位不会变。 |
| Reward 1 读法 | 分别选择每个 Reward 1，或用脚本状态测试。 | 测试者能说出轴和战场预期。 |
| 第一次商店经济 | 以 12 Gold 进入第一次商店。 | 测试者理解一个中立修正额度和 Rest 分离。 |
| 反制预警 | 强制触发每个反制家族。 | 测试者能在或前后说出被攻击组件。 |
| Battle 4 验证 | 对比商店选择和下一战。 | 结果页能把 patch / pivot 连接到观察到的压力。 |
| Reward 2 读法 | 用不同主轴进入 Reward 2。 | UI 提供 deepen + patch / pivot，并说明原因。 |
| Endpoint sweep | 强制基地圈入侵。 | 扫击在伤害前预警，且不跨路。 |
| 完整 run | 实跑或模拟胜利和失败路径。 | Final Result 写出主轴、关键选择、反制压力、路线影响、Guardian HP 压力、next watch tag。 |
| 无 debug UI | 检查所有 player-facing screens。 | 无 debug panel、slider、telemetry dump、旧 route label。 |
| 灰阶可读 | Battle Screen 截图转灰阶。 | 当前路线、最高危险、active ball、反制目标仍可区分。 |

## 11. 未定项

这些不是写实现计划的 blocker，但必须保持可见。

- 最终钉子布局、活动块、炮台摆动、球参数、层间随机、同屏球数。
- `Unit.Slot.Exposure Gate` 从开始暴露到完全暴露之间的插值方式。
- 每场战斗的精确敌人数量、出生时间和路线分配。
- 中立修正、Hive 单位、Guardian 战术 / 战略技能的最终平衡。
- 最终 sprite sheet、动画帧、pivot、碰撞区、UI 响应式细节。
- 最终音频族和混音。

## 完成摘要

```text
/implementation-handoff complete

Game: PlanB
Build target: Full MVP v0 6-battle reset handoff
Hypothesis: 15-20 分钟 run 能教学机器轴承诺、反制压力、Deploy Lane 边界和 Endpoint 兑现。
Soul: physical machine cause -> Queue -> selected spawn port -> battlefield result；奖励 / 商店 / 反制保持机器组件可读。
MUST items: 33

Status: DONE_WITH_CONCERNS

Top concern:
  完整 6 战范围只有在 implementation milestones 保持 M1 聚焦 machine-to-frontline causality 时才成立。如果 M0-M1 试图同时解决所有物理、资源、经济和 Endpoint，build 会在核心读法可测试前卡住。

Next Step:
  PRIMARY: 确认这份 handoff，然后只写 M0-M1 的实现计划。
  IF physical behavior becomes the active blocker: 在写 Godot 代码前使用 GodotPrompter physics-system 和 scene-organization。
  IF design scope changes: 重新跑 /implementation-handoff 或回退到 /prototype-slice-plan。
```
