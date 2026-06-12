# 进度与决策日志

**最后更新：** 2026-06-12
**仓库状态：** 文档主导；原 `mvp/` Godot MVP v0 实现已归档到 `docs/archive/implementations/godot-mvp-v0-20260611/`，当前活动 Godot 实现目录为 `godot/`，M0-M4 已进入活动实现。本文记录设计状态和决策日志，不作为代码状态证明。

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
- `docs/mvp-learning-checkpoints.md`
- `docs/mvp-scope.md`
- `docs/mvp-hive-loadout.md`
- `docs/rewards-economy.md`
- `docs/DESIGN.md`
- `docs/PROGRESS.md`

当前美术与资源生产基线：

- `docs/DESIGN.md`：已确认的 MVP v0 美术风格、资源生产约束和视觉反馈规范。全局风格为 `Modular 2.5D Readable War-Table Sprites / 模块化 2.5D 可读战争台资源风格`；采用 race-neutral base chassis + race skin layer + unit / Guardian sprite layer。它锁定生产方向，不锁最终资产清单、最终色值、最终字体、最终音频或最终混音。

当前候选与实现输入：

- `docs/ball-machine-physical.md`：MVP v0 实现输入。记录球机物理表现层候选草案（模型 A 真物理、三仓三块串联钉板结构，`Peglin` 仅作为结构参考、摆动炮台、override 物理化、左右分屏、同屏信息层级、物理反馈语法和灰阶可读规则）；已确认作为 MVP v0 实现假设进入 `/implementation-handoff`，但不等于最终 canon，具体物理参数和各效果物理表现未定，未 playtest，未最终锁定。

旧方向、过时计划、历史 artifacts 和旧 prototype 已归档到 `docs/archive/`，不作为当前正式规则。

## 当前总状态

- 仓库当前处于“文档主导 + MVP v0 M0-M4 活动实现”阶段；原 `mvp/` Godot MVP v0 实现已归档，当前活动实现目录为 `godot/`。
- M0-M4 之外的新里程碑、范围扩展或玩法 canon 变更，必须从当前正式文档重新写有范围约束的实现计划，并等待用户明确确认后再开始。
- 当前可运行的 Godot MVP 主验证命令是 `bash tools/verify_godot.sh`；归档目录里的旧验证脚本只作历史背景，不作为当前验收入口。
- 旧 Web MVP、旧脚本、旧验证命令和旧实现假设都不再作为当前设计依据。
- 旧 Godot prototype 已归档到 `docs/archive/prototypes/`，完全过期，不再作为 build、验证、评审或路由信号。
- 当前正在从基础机制整理转入 Hive 第一种族设计；`Caste Hive` 方向已确认，单位工作名、占位剪影、轻行为和第一版攻击几何已定，两个 Guardian 的身份、轴倾向、技能结构、技能方向、战术技能目标优先级和第一版战术技能范围已定，最终美术资源和最终数值仍未定。
- 球机主系统是 `Launch / Tuning / Unit`。
- Tuning 基础槽是 `Gate / Prime / Echo / Surge`。
- 球机主题采用“通用规则 + 种族化球机表现”，不做每个种族一套隐藏核心规则。
- Unit 基础规则已改为 4 个独立单位槽，左到右低需求到高需求，并使用 `Unit.Slot.Exposure Gate` 从左到右逐步暴露槽位。
- `Unit.Slot.Exposure Gate` 的 baseline 暴露节奏跨种族通用；种族只能通过可见命名规则改写闸门参数，不能默认拥有隐藏专属时间表。
- `Unit.Slot.Exposure Gate` 第一版 baseline 已确认：Slot 1-4 的 `progress_required = 3 / 5 / 8 / 12`，暴露开始时间为 `0s / 12s / 36s / 72s`，完全暴露时间为 `0s / 24s / 54s / 96s`。
- 战场方向是两端基地圈、三条固定路径、自动单位接战。
- 战中基础输入是 `Deploy Lane`。
- MVP 学习检查点已拆成 6 个节点：Battle 1 前 30 秒、第一次奖励、第一次商店、第一次反制、第二次奖励、终点战。
- MVP 第一轮 playtest 软阈值护栏已确认：10-20 局后观察 Guardian 选择率和成功率差距、Unit slot 关键队列贡献占比、以及连续空窗战斗。
- Hive 第一种族数值采用职责带口径：先保住 4 个 Unit slot 和 2 个 `Player Guardian` 的战场职责，再用战斗时长、失败率和软阈值护栏修正强度。
- 第一批中立机器修正已经完成 MVP 文档态口径收束：第一次奖励三轴锚点、第一次商店候选池、`Echo Latch` 位置、第二次奖励生成规则、Gold faucet、价格带、职责带平衡口径和休整结果页口径已确认；精确 playtest 后最终平衡仍未定。
- 球机物理表现层已吸收 2026-06-08 `/plan-design-review` 的候选收口内容：战中 1 秒扫视信息层级、物理反馈状态语法、灰阶 / 色盲可读规则、`Peglin` 仅作为结构参考的视觉身份约束，以及 5 个候选决策。该文已确认作为 MVP v0 handoff 实现假设，属于当前 MVP v0 实现输入，但不参与长期 canon 的正式文档权威顺序。
- `docs/DESIGN.md` 已确认当前美术与资源生产基线：全局底盘保持中性可换皮，Hive 只是第一种族 skin layer；后续 AI 资产必须按 sprite sheet / VFX 帧 / Godot 可拆分资源约束生产。
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
  - 具体身份、名称、技能和数值在 2026-06-04 当时延后到第一种族设计阶段；后续 2026-06-05 / 2026-06-08 已确认身份、轴倾向、技能结构、first-pass 参数和职责带口径，最终美术资源和 playtest 后最终数值仍未定。
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

## 2026-06-11

- 将原 `mvp/` Godot MVP v0 实现整体归档到 `docs/archive/implementations/godot-mvp-v0-20260611/`。
- 归档当时确认没有活动 Godot 实现目录；归档实现不再作为当前 build artifact、验证命令来源或新实现结构依据。
- 重新实现必须从当前正式文档重新创建有范围约束的实现计划，并等待用户明确确认；M0-M1 已按该流程确认后改走新的 `godot/` 活动工程。
- 确认该旧 prototype 完全过期，后续不再读取它来判断当前状态、设计方向或实现计划。
- 确认游戏内玩家可见文字默认中文，除非用户明确指定其他语言；正式机器术语可以保留英文标签，解释性 UI、按钮、提示、状态、结果页和教程文案默认中文。
- 经用户确认后，MVP v0 M0-M1 重新实现从新的 `godot/` 活动工程开始，不从归档 `mvp/` 恢复。
- M0 当前验证入口为 `bash tools/verify_godot.sh`，工程目标为 Godot 4.6、GDScript、Compatibility / `gl_compatibility`。
- M1 当前范围为 Battle 1 vertical：三板机器显示、Ball result -> Unit progress -> Queue、Queue Bridge -> selected spawn port、直接点击路线、Battle 1 胜 / 败路径。
- 经用户确认后，M2 已在新的 `godot/` 活动工程内实现：Guardian Contract、Battle 1 -> Reward 1 -> Battle 2 -> First Shop / Rest -> Battle 3 -> Result Routing 的短局骨架，Gold faucet，第一次奖励三轴锚点，第一次商店补洞项，休息消耗，以及 M2 verifier。当前验证入口仍为 `bash tools/verify_godot.sh`。

## 2026-06-12

- 经用户确认后，M3 已在新的 `godot/` 活动工程内实现并提交：Battle 3 反制侦测、三类反制家族、可见预警 / 触发效果、第一商店补洞优先项、`counter1.*` 结果记录，以及 M3 verifier。
- M3 follow-up 修正已完成：`counter1.visible_effect` 只记录真实触发过的可见效果，未触发时结果页显示“未触发”；`Stagger Punisher` 改为惩罚真正的 Queue 部署空档，而不是惩罚未部署到左路；M3 verifier 新增未触发反制、持续中路部署不触发 Stagger、以及机器板反制目标传递检查。
- 经用户确认后，M4 已在新的 `godot/` 活动工程内实现：Battle 3 休整后进入 Battle 4，Battle 4 胜利后进入第二次免费奖励，Battle 4 失败进入结果页，Battle 4 胜利不产生 Gold。
- M4 第二次奖励按当前主轴生成 2-3 个候选：`Launch` 主轴含 `Front Recycle` / `Junk Sieve`，`Tuning` 主轴含第二次奖励专属 `Echo Latch` / `Surge Buffer`，`Unit` 主轴含 `Muster Pair` / `Queue Brace`；内部角色记录为 `deepen_current_axis` / `patch` / `pivot`，玩家可见标签为 `深化当前主轴` / `补洞` / `转向`。
- M4 结果记录已包含 `second_offer.current_axis`、`second_offer.candidates`、`second_offer.choice_id` 和 `second_offer.choice_role`；M4 不包含 Battle 5、Endpoint Prep、Endpoint、第二商店、Battle 4 Gold 或完整实体战场。

## 2026-06-05

- 新增 `docs/rewards-economy.md` 作为候选草案。
- 撤回“第一批中立奖励 / 商店机器修正已整体锁定”的表述，改为只记录候选并等待 gstack-game 逐项确认：
  - `Launch`：`Pool Pocket`、`Front Recycle`、`Junk Sieve`。
  - `Tuning`：`Prime Charge`、`Echo Latch`、`Surge Buffer`。
  - `Unit`：`Queue Brace`、`Muster Pair`、`Slot Primer`。
- 确认候选阶段只服务 MVP 三轴读法，不展开具体 Hive 内容。
- 确认第一批中立修正采用“轴锚点 + 补洞分层”结构：
  - 第一次奖励教玩家识别 `Launch / Tuning / Unit` 三条机器轴。
  - 商店优先提供对已公开危险和反制的补洞项。
  - Battle 4 后的第二次奖励再根据玩家主轴提供加强项或补洞项。
- 确认奖励池和商店池采用软分池：
  - 每个修正有主来源。
  - 少数修正可以同时进入奖励池和商店池。
  - 第一次奖励必须保留三轴教学，商店必须保留补洞职责。
- 确认第一次奖励三轴锚点：
  - `Pool Pocket`：`Launch`，Pool 容量 `+1`。
  - `Prime Charge`：`Tuning`，Prime 的 Unit hit 从 `value + 1` 改为 `value + 2`。
  - `Slot Primer`：`Unit`，选择 1 个 Unit slot，整局 progress 下限为 `1`。
- 确认 `Slot Primer` 不是每场战斗只触发一次，而是选定槽位整局始终领先一步；它不降低 `progress_required`，不允许多个 slot 同时获得 progress floor，也不能单独触发出兵。
- 确认第一次奖励采用战场结果模型，而不是先做精确机器数学等价：
  - `Pool Pocket` 观察 `Launch sustained flow`：Battle 2-3 主压路线是否减少可见断档。
  - `Prime Charge` 观察 `Tuning high-value hit`：Prime 命中后 4-6s 内是否造成路线状态变化或关键队列结果。
  - `Slot Primer` 观察 `Unit anchor slot`：被选 Unit slot 是否在 Battle 2-5 中形成可见战场锚点。
  - 如果三项都只被玩家读成“兵更多”，第一次奖励失败。
- 确认第一次商店候选池：
  - `Front Recycle`：`Launch` 转向项，让 miss 回流更快进入 Pool 前半段。
  - `Junk Sieve`：`Launch` 补洞项，处理 Pool 头部 Junk。
  - `Surge Buffer`：`Tuning` 补洞 / 节奏项，让未立刻转成队列的 Surge 留下 slot charge。
  - `Queue Brace`：`Unit` 补洞项，队列断档时补最低进度 slot。
  - `Muster Pair`：`Unit` 转向 / 爆发项，同 slot 连续队列条目合并成双单位部署。
- 确认第一次商店展示 3 个，其中至少 1 个是当前危险或已公开反制的补洞项。
- 确认 `Echo Latch` 保留为第二次奖励的 Tuning 深化项，不进第一次商店，也不作为商店补洞项。
- 确认第二次奖励采用主轴优先池：
  - 展示 2-3 个候选。
  - 至少 1 个强化当前主轴。
  - 至少 1 个补洞或转向。
  - `Launch` 主轴优先 `Front Recycle`，外加 `Junk Sieve` 或跨轴补洞 / 转向项。
  - `Tuning` 主轴优先 `Echo Latch`，外加 `Surge Buffer` 或跨轴补洞 / 转向项。
  - `Unit` 主轴优先 `Muster Pair`，外加 `Queue Brace` 或跨轴补洞 / 转向项。
- 确认第二次奖励固定在 Battle 4 后出现，不开第二次商店，不消耗 Gold。
- 确认 Gold faucet：
  - 起始 Gold 为 0。
  - MVP 第一版逐战斗 Gold faucet 为 `6 / 6 / 8 / 0 / 0 / 0`。
  - Battle 1 胜利给 6 Gold。
  - Battle 2 胜利给 6 Gold。
  - Battle 3 强反制胜利给 8 Gold。
  - Battle 4 / Battle 5 / Endpoint 不给 Gold。
  - MVP 第一版不做失败后继续，因此不定义失败 Gold；失败不返还 Gold，不续关，不给下一局资源补偿。
  - 不做击杀、破门、快胜、剩余 HP 或战中 Gold 槽奖励。
- 确认商店价格带：
  - 休整 3 Gold，只在 `Player Guardian` HP 受损后出现，MVP 第一版恢复 20 当前 HP，不提高最大 HP。
  - 补洞项 4 Gold。
  - 转向项 5 Gold。
  - 主轴深化项 6 Gold。
  - 每个商店项只卖 1 次，MVP 第一版不做同列重复购买涨价。
- 确认第一次商店时机和 Gold 口径：
  - Battle 1 后只给第一次奖励。
  - Battle 2 后进入第一次商店。
  - 若 Battle 1 和 Battle 2 都是普通胜利，第一次商店通常是 12 Gold。
  - 第一次商店最多购买 1 个中立修正；剩余 Gold 用于休整或保留到后续节点。
- 确认休整窗口：
  - 第一次商店中，如果 `Player Guardian` HP 受损，可以休整 1 次。
  - Battle 3 反制战胜利后，如果 `Player Guardian` HP 受损，可以休整 1 次。
  - Battle 5 反制战胜利后进入 Endpoint 前整备窗口；如果 `Player Guardian` HP 受损，可以休整最多 2 次。
  - 普通 Battle 1 / Battle 2 / Battle 4 后不单独开放休整窗口，Endpoint 后不开放休整窗口。
  - Endpoint 前整备窗口不卖中立机器修正，不提供第二次商店，只允许休整和进入终点战。
  - 失败直接结束本局，不进入休整窗口。
- 新增 `docs/mvp-learning-checkpoints.md`。
- 确认 MVP 6 个学习检查点：
  - Battle 1 前 30 秒：读懂造球、调校、Unit progress 和 `Deploy Lane` 的边界。
  - 第一次奖励：读懂 `Pool Pocket` / `Prime Charge` / `Slot Primer` 对应三条机器轴。
  - 第一次商店：读懂商店是补洞或转向，不是买泛用强度。
  - 第一次反制：读懂敌人在攻击某个机器弱点。
  - 第二次奖励：读懂主轴深化和补洞的差别。
  - 终点战：复盘胜负来自机器轴兑现或断裂，而不是只来自点路。
- 确认每个检查点的 UI 最小反馈：
  - Battle 1 前 30 秒：Pool、Forge、Launcher、Tuning、Unit slots、Queue、Deploy Lane 和 lane danger。
  - 第一次奖励：奖励卡显示机器轴、目标组件、operation、玩家读法，选择后 HUD 持续标记。
  - 第一次商店：Gold、价格、机器轴、补洞 / 转向标签、不足 Gold 状态、Sold 状态和休整项。
  - 第一次反制：预警、被攻击组件、反制生效结果和补洞标签对应关系。
  - 第二次奖励：当前主轴、内部 `deepen_current_axis` / `patch` / `pivot` 角色，以及玩家可见的 `深化当前主轴` / `补洞` / `转向` 标签和候选来源说明。
  - 终点战：Telegraphed Sweep 预警、三路状态、机器兑现标签、Guardian HP 和结果页入口。
- 确认每个检查点的结果页记录字段：
  - Battle 1 前 30 秒：完整机器链路样例、Deploy Lane 选择、三路危险快照。
  - 第一次奖励：选择项、机器轴、目标组件和操作。
  - 第一次商店：购买前 Gold、购买项、购买角色、购买后 Gold。
  - 第一次反制：反制家族、目标组件、可见效果、对应回应链路。
  - 第二次奖励：当前主轴、候选列表、选择项、选择角色。
  - 终点战：胜负、主轴兑现、主要断裂原因、Deploy Lane 影响、双方 Guardian 结束 HP。
- 确认 MVP 信息恢复口径：
  - 失败后本局结束。
  - 失败恢复只通过结果页信息完成，不通过 Gold、续关或下局资源补偿完成。
  - 结果页必须显示 `main_break_reason`，并在失败时显示 1 个 `next_run_watch_tag`。
  - `next_run_watch_tag` 只提示下一局该观察什么，不保证下一局刷出对应奖励或商店项，也不隐藏提高候选权重。
- 确认每个检查点的失败观察方式：
  - 观察者只记录玩家行为、结果页字段和玩家原话，不能先解释规则再问。
  - 每个检查点只问一个短复盘问题，避免把 playtest 变成口试。
  - Battle 1 观察机器链路和 `Deploy Lane` 边界。
  - 第一次奖励观察玩家是否能说出机器轴和预期战场表现。
  - 第一次商店观察玩家是否理解 Gold 机会成本和购买角色。
  - 第一次反制观察玩家是否能指出被攻击的机器组件和对应补洞。
  - 第二次奖励观察玩家是否能区分主轴深化、补洞和转向。
  - 终点战观察玩家是否能把胜负复盘到机器兑现或断裂，而不是只归因于点路。
- 确认 MVP 第一轮 playtest 使用软阈值护栏，不作为最终平衡：
  - 10-20 局后，任一 Guardian 选择率低于 30%，或另一个高于 70%，需要回查选择 UI、名称、剪影、轴倾向读法和实际强度。
  - 两个 Guardian 的到达 Endpoint 率或通关率差距超过 15 个百分点，视为软平衡问题，但先查失败原因，不直接削弱。
  - 非 `Slot Primer / Unit` 构筑下，单一 Unit slot 不应长期占据 60% 以上关键 queue entry。
  - 每个 Unit slot 至少要在一种正常构筑或命名 Unit 构筑中产生可见贡献。
  - 不允许连续 2 场战斗只有自动播放，没有新选择、反制、兑现提示或结果页复盘点。
- 当时中立修正精确最终平衡仍未定；休整已确认使用 3 Gold 恢复 20 `Player Guardian` 当前 HP，不称为修理；Hive MVP 机器包装方向已定为视觉区分。2026-06-08 已补中立修正职责带平衡口径和休整结果页口径。
- 确认游戏设计、GDD、玩法规则、经济、平衡、UI 手感、种族、Guardian、奖励、商店、敌人、战场规则相关工作必须优先使用 gstack-game 技能链路；未经用户确认，不得把候选内容写成正式规则。
- 确认球机主题边界：
  - 采用“通用规则 + 种族化球机表现”。
  - `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Unit slot`、`Queue`、`Deploy Lane` 保持通用标签和通用语义。
  - 种族必须通过球机的可见表现、反馈语言和明确的 Machine Contract 改写表达特色。
  - 种族可以改变外壳、颜色、材质、图标风格、组件表现、反馈语言和必要的效果命名。
  - 种族不能替换整台球机，不能拥有独立核心规则。
  - 每个 `Unit slot` 是独立单位模板槽，不是部件槽、配方槽或跨槽合成槽。
- 确认 `Unit.Slot.Exposure Gate` 节奏归属：
  - 采用“通用 baseline + 命名改写”。
  - baseline 暴露节奏跨种族通用，不做 Hive 或未来种族的隐藏默认时间表。
  - 种族、Guardian、奖励、商店、遗物、事件或敌人若要改变闸门，必须作为命名规则通过 Machine Contract 声明。
  - 可改写参数包括初始遮挡、缩短速度、特定 slot 暴露优先级或短时暴露窗口。
- 确认第一版 MVP 第一种族方向为 Hive。
- 确认 MVP Hive 采用 `Caste Hive` 方向：
  - 巢群分工阶级，用 4 个 `Unit slot` 表达从低承诺到高承诺的单位职责梯度。
  - `Infection Hive` / 感染、孵化、寄生方向不进入 MVP 第一种族 baseline，保留给未来其他种族或后续大内容。
- 确认 Hive MVP 机器包装采用视觉区分：
  - 不为 `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Unit slot`、`Queue` 或 `Deploy Lane` 设置 Hive 副名。
  - 通用机器标签在主显示中保持通用。
  - Hive 特色通过虫壳、酸液、巢脉材质、图标风格、组件外观、运动反馈和命名效果表达。
- 确认 Hive 4 个 `Unit slot` 的 MVP 单位原型：
  - Hive MVP 单位采用轻技能深度：每个单位只保留 1 个可见行为特征，不做主动技能、单位成长线、复杂状态或独立种族资源。
  - Hive MVP 单位属性采用职责优先属性表，并使用中对比职责表作为第一版数值口径：每个单位只锁第一版核心属性起点，包括 HP、伤害、攻击间隔、移动速度、攻击范围和一个特殊行为参数；当前不做完整战斗数值表。
  - Slot 1：`短牙虫`，稳定补线，`progress_required = 3`，快速接线，近战轻咬，不抗线、不爆发。可见行为特征为快速进入接战点，无额外状态；占位剪影为小体型、低伏身体、短牙前突。
  - Slot 2：`盾壳虫`，守线抗压，`progress_required = 5`，较慢但更硬，近战稳定攻击，减少漏兵，不快速推进。可见行为特征为接敌后更能站住，承受第一轮接触压力；占位剪影为宽壳、低重心、前盾状甲壳。
  - Slot 3：`酸囊虫`，破僵持，`progress_required = 8`，短程酸液弹道，命中点小范围溅射，负责打破一路持续接战或门前卡住的局面。占位剪影为背部或腹部酸囊、短喷口、短程喷射弧线。
  - Slot 4：`碾壳兽`，高承诺翻线，`progress_required = 12`，慢到场的重单位，用同一路线接战点横扫重击压制并推回战线，不频繁出现。占位剪影为大型厚壳、重前肢或重头部、明显压线体量。
  - Hive 4 个 `Unit slot` 的第一版属性起点已确认：`短牙虫` hp 6 / damage 1 / 0.7s / range 1.5 / speed 10；`盾壳虫` hp 18 / damage 2 / 1.4s / range 1.5 / speed 6；`酸囊虫` hp 8 / damage 3 / 1.8s / range 7 / speed 7；`碾壳兽` hp 26 / damage 6 / 2.6s / range 2 / speed 5。
  - Hive 4 个 `Unit slot` 的第一版攻击几何已确认：`短牙虫` 和 `盾壳虫` 都是同路最近目标单体近战，不带隐藏行为；`酸囊虫` 弹道速度 14 路径单位/s，命中点同路溅射半径 2.5，最多命中主目标 + 2 个附近目标，目标死亡时打到目标死亡位置；`碾壳兽` 同路接战点横扫 3.5 路径单位，最多命中 3 个目标，不击退、不跨路。
  - Slot 3 的半远程单位是 MVP 初期验证目标，用来测试短程远程单位能否在 Hive 前线分工中被玩家读懂。
  - Slot 3 不做持续炮台，不留酸池或 DoT，不替代 `Tuning` 的重复重击读法。
  - Slot 4 的横扫只作用于同一路线接战点附近，不跨路线，不做持续控场。
- 确认 Hive 两个 `Player Guardian` 的身份和轴倾向：
  - `巢脉母`：偏 `Launch`，让玩家更容易读到稳定补线和持续压线；软倾向，不锁死本局主轴，不直接生成更多单位。
  - `酸冠母`：偏 `Tuning`，让玩家更容易读到高价值命中、酸囊弹道和小范围破点；软倾向，不替代奖励、商店和反制决策，不让酸囊虫变成持续炮台。
- 确认 Hive Guardian 技能结构：
  - 每个 Guardian 有 1 个低强度自动守家战术技能，让 Guardian 在战场上可见，但不能独自解决漏兵或让玩家忽略三路稳线。
  - Player Guardian 有基础普通攻击作为防偷家手段，独立于战术技能存在；普通攻击可以清理少量入侵单位，但不能替玩家稳住持续漏线。
  - 单位进入玩家基地圈后，Guardian 基础攻击和战术技能按基地圈内空间关系选目标，不再按路线筛选；`entered_from = Left / Mid / Right` 只能作为危险来源、日志或结果页字段。
  - 两个 Guardian 的战术技能采用完全不同的自动守家规则，而不是同结构换表现；英雄特色需要在战术技能上可见。
  - Guardian 战术技能效果已确认：`巢脉母` 使用 `巢脉牵缚`，敌人进入玩家基地圈后，低频牵缚 / 减速最接近 Player Guardian 的入侵者并造成低伤害，距离并列时选最低 HP；`酸冠母` 使用 `酸冠反喷`，玩家 Guardian 受到实际 HP 伤害后，低频向攻击者反喷酸液并造成小范围低伤害。
  - Guardian 战术技能第一版参数起点已确认：`巢脉牵缚` 为 8s 冷却、单目标、短暂停顿 / 减速、低伤害；`酸冠反喷` 为 6s 冷却、受到实际 HP 伤害后触发、一次受击最多触发一次、冷却中受击不储存额外触发次数。
  - Guardian 战术技能伤害 / 范围采用中数值起点：`巢脉牵缚` 造成 4 damage，停顿 0.5s，并使目标减速 40% 持续 1.2s；`酸冠反喷` 以攻击者位置为中心，在 Player base circle 内半径 3.0，对攻击者造成 4 damage，并对最多 2 个附近入侵者各造成 1 damage。
  - `酸冠反喷` 允许有限卖血打法：玩家可以接受少量漏线，用 Guardian HP 换一次反击清理机会；它不治疗、不返还资源、不提高最大 HP、不降低本次受击伤害，也不能让玩家长期忽略三路稳线。
  - 每个 Guardian 有 1 个轻量战略技能，必须走 Machine Contract，服务其轴倾向，并保持为开局软倾向。
  - Hive Guardian 采用单一 `Guardian Contract` 表记录战略和战术效果；表内用 `contract_layer=strategic_machine / tactical_battle` 区分结算层。`strategic_machine` 行进入机器结算，`tactical_battle` 行只进入战场 / Guardian 结算。
  - Guardian 技能方向采用轴内种族化表现改写：`巢脉母` 的战略技能只在 `Launch` 内表达 Hive 回流 / 巢脉输送，`酸冠母` 的战略技能只在 `Tuning` 内表达酸液弹道 / 命中反馈；两者都不跨轴直接补 `Unit`。
  - Guardian 战略技能目标采用折中方案：`巢脉母` 规则目标为 `Launch.Recycle / Launch.Pool`，表现包装使用 `Route Board / Recycle path` 的巢脉回流；`酸冠母` 规则目标为 `Tuning.Prime`，表现包装使用 `Gate -> Prime ingress` 的酸冠入槽和 Prime 命中反馈。
  - Guardian 战略技能 operation 已确认：`巢脉母` 采用隐藏 pity 伪随机的 Recycle 强化，合法 Recycle 未触发强化时推进隐藏保底，触发时该次 Recycle 额外返回 1 个 clean ball，触发后重置；`酸冠母` 采用 Gate miss 计数，只有 `Tuning.Gate` 计数，计数满后下一次本应进入 `Gate` 的结果改为 `Prime`，触发后重置。
  - 两个 Guardian 的战略计数都在每场战斗开始时重置为 0，不跨战斗保留。
  - `酸冠母` 不把 `Echo / Surge` 计入 Prime miss，也不统计 `Launch` 的 Split / Recycle / Waste；`巢脉母` 不改变 Route Board 概率、Pool 容量、Recycle 标签继承规则，也不绕过 Pool 满时的 Recycle 回流失败规则。
  - Guardian 战略技能强度采用保守起点：`巢脉母` 的 Recycle 强化基础触发概率为 15%，第 6 次合法 Recycle 保底触发；`酸冠母` 第一版调参起点为 6 次 `Tuning.Gate` miss 后，下次本应进入 `Gate` 的结果改为 `Prime`。
  - Hive 的 MVP 工作名、占位剪影、轻技能深度、第一版攻击几何和机器视觉包装方向已确认；两个 `Player Guardian` 的身份、轴倾向、技能结构、技能方向、差异化战术技能效果、战术技能冷却和中数值起点、战术技能目标优先级、`酸冠反喷` 第一版范围、战略技能目标、战略技能 operation、保守强度起点、战略计数重置口径和 `Guardian Contract` 第一版表已确认；最终美术资源和最终数值仍未定。
- 确认 `Unit.Slot.Exposure Gate` 进入 Unit 基础规则：
  - 撤回“槽位本身不代表低级兵 / 高级兵”的旧规则。
  - 4 个 Unit slot 从左到右是低需求到高需求，通常对应低承诺到高承诺单位模板。
  - 每个 slot 仍然是独立出兵源，不做跨 slot 合成、部件装配或配方结算。
  - 基础每场战斗开始时最左侧 slot 完整暴露，其余 slot 被闸门挡住未暴露区域。
  - 闸门随战斗时间从左到右缩短，逐步暴露更高需求 slot。
  - 球打到未暴露区域会像碰到其他物理障碍一样弹开，不直接消失，也不立即转成 Waste。
  - 构筑可以影响初始闸门长度、缩短速度、特定 slot 暴露优先级或短时暴露窗口。
  - 构筑不能无代价让所有高需求 slot 开局全开。
- 确认 `Unit.Slot.Exposure Gate` 第一版 baseline：
  - Slot 1：0s 开始暴露，0s 完全暴露，`progress_required = 3`。
  - Slot 2：12s 开始暴露，24s 完全暴露，`progress_required = 5`。
  - Slot 3：36s 开始暴露，54s 完全暴露，`progress_required = 8`。
  - Slot 4：72s 开始暴露，96s 完全暴露，`progress_required = 12`。
  - 该 baseline 目标是 Battle 1 前 30 秒看到 Slot 2 完整开放，35-70s 看到 Slot 3 进入舞台，70s 后看到 Slot 4 参与构筑兑现。
  - 暴露开始到完全暴露之间的插值方式仍属于实现调试项；当前只锁定开始时间、完全暴露时间和 `progress_required` 起点。
- 确认第一版逐战斗难度指标：
  - Battle 1：90-110s，0 次反制，单路轻压，首次游玩失败率目标 0-5%。
  - Battle 2：100-125s，0 次反制，双路基础压力，首次游玩失败率目标 5-10%。
  - Battle 3：115-140s，1 次反制，主压路线 + 反制预警，首次游玩失败率目标 10-15%。
  - Battle 4：105-130s，0 次反制，商店补洞验证，首次游玩失败率目标 8-12%。
  - Battle 5：125-150s，1-2 次反制，主压 + 副压，首次游玩失败率目标 15-20%。
  - Endpoint：165-195s，1 次反制，Endpoint Guardian + 基地圈输出，首次游玩失败率目标 20-25%。
  - 这些指标是后续波次、模拟和 playtest 的目标曲线，不是刷怪脚本。

## 2026-06-08

- 确认 Hive 第一种族数值采用职责带口径，不采用一次性精确终局表：
  - 第一版调参先保住 4 个 Unit slot 和 2 个 `Player Guardian` 的战场职责，再用战斗时长、失败率和软阈值护栏修正强度。
  - `短牙虫` 快速接线，制造持续前线存在，但不能单独抗住持续压力。
  - `盾壳虫` 守线抗压，减少漏兵，但不能变成主要推进输出。
  - `酸囊虫` 短程半远程破僵，命中点小范围溅射，但不能变成持续炮台或吃掉 `Tuning` 的高价值命中读法。
  - `碾壳兽` 高承诺晚到翻线，横扫制造路线翻转，但不能频繁出现或常驻清场。
  - Player Guardian 基础攻击只是普通防偷家手段；`巢脉母` 和 `酸冠母` 只能提供软轴倾向和弱守家，不能替代奖励、商店、反制或持续稳线。
  - 如果某个数值修改能提高胜率但破坏职责带，不能作为 MVP 正式调参方向，只能作为临时沙盒参数。
- 确认 Hive 第一种族的 MVP 数值职责带口径已满足文档态实现前硬门槛；精确最终平衡仍需模拟和 playtest。
- 确认中立修正采用职责带平衡口径，不采用一次性精确终局表：
  - 价格带保持 `休整 3 / 补洞 4 / 转向 5 / 主轴深化 6`。
  - 补洞项只回应一个已公开风险或反制目标，不能抹掉整个反制家族。
  - 转向项改变构筑形状，不能同时解决当前风险并强化主轴成默认最优。
  - 主轴深化项强化已形成主轴，不能不看当前主轴也总是最优。
  - 第一次奖励仍按战场结果模型验收，不要求三轴锚点产生相同单位数或胜率。
  - 如果一个修正提高胜率但只被玩家读成“兵更多”或“数字更大”，不能作为 MVP 正式平衡方向。
- 确认 `休整` 结果页口径：
  - `休整` 是 Gold sink 和 HP 压力回应，不是中立机器修正。
  - 结果页记录 `rest.total_purchases`、`rest.total_gold_spent`、`rest.total_hp_restored`、`rest.windows_used`、`rest.endpoint_relevance` 和 `rest.opportunity_cost`。
  - `rest.endpoint_relevance` 使用 `none`、`helped_survive_to_endpoint`、`changed_endpoint_margin`、`insufficient`。
  - 如果高额休整导致玩家放弃补洞项，结果页必须显示机会成本。
- 确认中立修正职责带平衡口径和休整结果页口径已满足文档态实现前硬门槛；精确最终平衡仍需模拟和 playtest。
- 新增 `docs/ball-machine-physical.md` 作为候选草案，记录球机物理表现层的根决策（当时尚未经过 `/plan-design-review`，未 playtest，未最终锁定，不参与文档权威顺序）：
  - 球机结算采用模型 A 真物理：命中由物理落点决定，`docs/machine-warehouses.md` 的百分比作为物理布局要逼近的目标分布，不是 RNG roll；强制落槽类 override 例外。
  - 三仓 = 三块串联的缩小版钉板结构（`Launch` / `Tuning` / `Unit`），左侧竖条垂直堆叠，球自上而下穿过；`Peglin` 仅作为结构参考，不作为 UI 外观目标；层间落点在一定范围内随机（折中弱打散）。
  - 每块板为顶部进球、钉子 + 活动块弹跳、底部结果槽；底槽映射 `Launch`=进 Tuning / Split / Recycle / Waste，`Tuning`=Gate / Prime / Echo / Surge，`Unit`=slot 1-4 + Exposure 挡板。
  - 发射为 `Launch` 顶部自动摆动炮台，按 `Launcher` 节奏发球，玩家不瞄准；球机全自动，玩家只通过构筑改钉子 / 活动块 / 槽宽和 `Deploy Lane` 间接影响。
  - override 物理化采用 A1：倾向类改钉子 / 活动块 / 槽宽；强制落槽类用槽位强制导入表现；结算类（Prime value、Echo 复制、Surge 延迟、Slot Primer floor 等）保持逻辑。
  - 同屏采用左右分屏：球机竖条在左，三路战场在右。`Forge` / `Pool` / `Queue` / `Loop Safety` 保持离散层。
  - 本草案不改动 `docs/machine-warehouses.md` 的任何逻辑数值与规则。
- 根据 2026-06-08 `/plan-design-review` 收口 `docs/ball-machine-physical.md`：
  - 写入战中 1 秒扫视信息层级：P0 当前 `Deploy Lane` / 下一次部署 / 最高危险路线，P1 active ball 机器因果链，P2 Queue head / 即将填满 slot，P3 Pool / Forge / 炮台和背景球。
  - 写入物理反馈状态语法：Natural Hit、Forced Redirect、Distribution Shift、Blocked Bounce、Valid Unit Hit、Split Return、Recycle Return、Waste、Logic Settlement、Counter Disruption。
  - 写入灰阶 / 色盲可读规则：当前选路、路线危险、机器反制和 active ball 必须使用 color + shape + motion 三重编码。
  - 明确 `Peglin` 只作为结构参考，不作为 UI 外观目标；视觉身份来自通用机器标签、组件形态和 Hive 材质 / 运动反馈。
  - 将五个 deferred decisions 整理为候选决策：active ball 板获得 P1 焦点、战中不显示精确百分比、强制落槽统一候选为导轨 / 引导槽、物理状态使用小型音频族、实现 handoff 前创建最小 `docs/DESIGN.md`。当时仍需用户确认后才能进入 handoff；随后已按下方记录确认进入 MVP v0 handoff，但仍不提升为最终 canon。
- 用户确认 `docs/ball-machine-physical.md` 作为 MVP v0 实现假设进入 `/implementation-handoff`，但不等于最终 canon。
- 用户确认 `docs/ball-machine-physical.md` 第 17 节五个候选决策按当前写法进入 handoff：
  - active ball 所在板获得 P1 焦点，inactive boards 降低对比但保持可见。
  - 战中不显示精确百分比，只显示物理槽形、组件变化和当前样本反馈；debug / 结果页可显示样本摘要。
  - 强制落槽统一使用导轨 / 引导槽语言，Hive 可包装为虫壳轨 / 酸液导槽。
  - 每个物理状态有小型音频族，音频辅助视觉但不能替代视觉可读。
  - 实现 handoff 前创建最小 `docs/DESIGN.md`。
- 新增 `docs/DESIGN.md` 作为 MVP v0 `/implementation-handoff` 前置设计系统：
  - 包含 art direction：可读的物理战争机器、左侧球机、右侧三路战场、Hive 虫壳 / 酸液 / 巢脉包装、通用标签保持可见。
  - 包含 color / shape tokens：当前选路、路线危险、机器反制、active ball、Tuning 槽、Unit Exposure 和强制导轨均有颜色、形状和运动配对。
  - 包含 HUD components：Machine Strip、Forge / Pool / Launcher、Tuning Result、Unit Slots、Queue Bridge、Deploy Lane Overlay、Lane Danger、Guardian 状态（当时称 Guardian HUD，现已收束为实体附着状态）、Reward Cards、Shop Cards、Result Page。
  - 包含 animation / audio vocabulary：Natural Hit、Forced Redirect、Distribution Shift、Blocked Bounce、Valid Unit Hit、Split Return、Recycle Return、Waste、Logic Settlement、Counter Disruption、Deploy Birth 和 Lane Danger Up。
- MVP v0 可以进入 `/implementation-handoff`。handoff 应引用当前正式 canon、MVP v0 实现输入、候选草案中已确认可进入 MVP 的部分、`docs/DESIGN.md` 和 `/plan-design-review` artifact；handoff 只写构建目标、体验要求、占位边界和验收标准，不写游戏代码。

## 2026-06-09

- 确认当前美术风格为 `Modular 2.5D Readable War-Table Sprites / 模块化 2.5D 可读战争台资源风格`。
- 确认全局美术不绑定 Hive：
  - 全局固定的是 race-neutral `Global Base Chassis`：中性 2.5D / 正交战争台、左侧三板球机、右侧三路战场、Queue bridge、`Deploy Lane`、路线危险和机器反馈语义。
  - Hive 是 `Race Skin Layer`：虫壳 trim、酸液导轨、巢脉回流、Hive 单位和 Guardian sprite、局部 VFX。它不能替换三板球机、三路战场、通用标签或基础 UI 语义。
  - 后续其他种族必须通过 skin kit 替换材质、单位剪影、Guardian、局部 VFX 和命名效果，不新增隐藏核心球机规则。
- 确认后续资源生产必须考虑 AI 生成序列帧和 Godot 拼动作：
  - 单位和 Guardian 使用稳定 2.5D 剪影，低到中等细节，2-3 个主材质区，减少细碎花纹、半透明丝线和跨帧易漂移结构。
  - 推荐帧数起点：小型单位 idle 4-6、move 6-8、attack 4-6、hit 2-3、death 4-6；Guardian 和大型单位可略高。
  - UI、球机底盘、路线、选路、危险提示、active ball、反制警示优先拆成 Godot 可复用模块、9-slice 面板、独立 sprite、shader 或 tween，不把整屏烘成一张图。
- 生成并保留当前风格参考图：
  - `docs/gstack-artifacts/planb-production-style-global-base-chassis-20260609.png`
  - `docs/gstack-artifacts/planb-production-style-hive-skin-applied-20260609.png`
  - `docs/gstack-artifacts/planb-production-style-sprite-sheet-feasibility-20260609.png`
- 明确上一轮 `planb-artstyle-a/b/c-20260609.png` 只作为错误边界参考：它们过度偏 Hive，不作为全局风格依据。
- 整理策划文档信息架构：
  - 新增 `docs/mvp-hive-loadout.md`，从 `docs/mvp-scope.md` 拆出 Hive 单位、Guardian、Guardian Contract 和职责带调参口径。
  - 将原中立修正候选文档改名为 `docs/rewards-economy.md`，作为 MVP v0 奖励、商店、Gold、休整和中立修正候选输入。
  - 将 `docs/mvp-scope.md` 收束为 MVP 范围合同，只保留目标、硬上限、必须包含、明确不做和成功标准。
  - 将 `docs/ball-machine-physical.md` 标题调整为“球机物理表现 MVP v0 输入”，明确它是当前实现输入但不是最终 canon。

## 2026-06-10

- 确认正式玩家 UI flow 第一版方向：
  - `Main Menu -> Guardian Contract -> Battle Screen -> Battle Result -> Reward Choice / Shop / Rest -> Final Result`。
  - `Guardian Contract` 发生在 Battle 1 前，使用“守护者契约”口径，不暗示玩家直接控制英雄。
  - Battle 1 胜利后进入 `Reward Choice`；Battle 2 胜利后按当前经济方向进入第一次 `Shop / Rest`。
  - `Final Result` 总结整局构筑、主要机器轴、关键奖励 / 商店、最大反制压力和下一局观察目标，不只是最后一场战斗结算。
- 确认 Battle Screen 正式布局方向：
  - 战斗主画面采用 `三仓机器 38% | Queue / Deploy Bridge 14% | 战场 48%` 的三段结构。
  - 右侧战场采用轻弧形三路；视觉可弯曲，但规则仍是 `Left / Mid / Right` 三条固定一维路径。
  - `Queue / Deploy Bridge` 只显示机器队列到当前选中路线出兵口的连接，不是第四机器仓，也不是推荐路线面板。
  - Debug UI、开发滑条、测试面板和实现状态文本不属于正式 Battle Screen，除非用户以后明确要求。
- 确认 Guardian 的主战场表现边界：
  - `Player Guardian` 和 Enemy Guardian / Endpoint 都是场内攻击型基地实体，不是底部 HUD 面板。
  - Guardian 状态信息附着在实体或基地圈附近，例如 HP、战术技能触发反馈和短时冷却标记。
  - `Player Guardian` 位于玩家基地圈内侧，三条玩家侧出兵口 / Lane Gate 位于基地圈连接路径的一侧。
  - Guardian 与三条出兵口之间必须留有基地缓冲区，用于读出 `破门 -> 入侵 -> Guardian 防守 / 受压`。
  - 单位从当前选中路线的玩家侧出兵口出生，不从 Guardian 身上出生。
- 新增并提交 UI flow artifact：
  - `docs/gstack-artifacts/planb-battle-ui-flow-session-20260610.md`
  - `docs/gstack-artifacts/planb-battle-ui-flow-1.0-draft-20260610.md`
  - 这些 artifact 是本次 UI flow 讨论记录和草案来源；正式规则仍以当前正式文档为准。

## 当前未定

- 中立修正的精确 playtest 后最终平衡。
- Hive 4 个 Unit slot 的最终 sprite sheet、攻击频率和 playtest 后最终平衡。
- 两个 Guardian 的 playtest 后最终数值。MVP 实现输入使用已确认的职责带口径和 first-pass 参数。
- `Unit.Slot.Exposure Gate` 暴露开始到完全暴露之间的插值方式。
- 球机物理层的层间随机范围、钉子 / 活动块布局、炮台摆动参数、球物理参数与同屏球数、回流与 Exposure 挡板物理形态、各 Guardian / 修正 / 反制的具体物理表现（见 `docs/ball-machine-physical.md`），以及是否提升为正式规则。
- `docs/DESIGN.md` 已确认生产风格基线和 Battle Screen 三段布局方向；最终字体、图标、具体种族 skin kit、sprite sheet 尺寸、pivot、碰撞区域、音频资产、精确色值、布局响应式细节和无障碍对比仍需实现后验证。

## 下一步

下一步如果继续扩展 M4 之外的运行流程，应先写并确认新的 M5 实现计划。Battle 5、Endpoint Prep、Endpoint、终局复盘字段和完整实体战场仍未进入当前活动实现。
3. 如实现需要，再收束 `Unit.Slot.Exposure Gate` 暴露插值方式。
