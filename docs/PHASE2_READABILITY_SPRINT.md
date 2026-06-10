# Phase 2 Readability Sprint

**最后更新：** 2026-06-09
**仓库状态：** 文档主导，`mvp/` 是当前 Godot MVP v0 实现目录。
**权威范围：** Phase 2 MVP Readability Sprint 的实现合同和验收口径。

本文只定义 Phase 2 要验证的可读性目标、非目标、验收标准和 playtest handoff。它不是完整 MVP 开发计划，不是公开 demo 打磨计划，也不扩展内容表。

相关依据：

- `docs/gdd.md`：总设计和硬边界。
- `docs/mvp-scope.md`：第一版完整 MVP 内容上限。
- `docs/mvp-learning-checkpoints.md`：MVP 学习目标、验收信号和失败信号。
- `docs/machine-warehouses.md`：`Launch / Tuning / Unit` 三仓机器规则。
- `docs/battlefield-rules.md`：基础战场、单位接战、基地圈和 Guardian。
- `docs/deploy-lane-ui.md`：`Deploy Lane` 直接选路和路线危险提示。
- `docs/enemy-rules.md`：敌人波次和既有反制家族。
- `docs/rewards-economy.md`：第一次奖励、商店、Gold 和休整结果页口径。
- `mvp/docs/agent/`：Godot MVP 工程实现和验证规则。

## 1. Phase Goal

Phase 2 的目标是在现有 playable session 内验证第一层可读性：玩家能否看懂“机器变化造成队列变化，队列通过 `Deploy Lane` 进入战场，战场结果再反馈机器构筑方向”。

Phase 2 成功时，玩家在不看 debug UI 的情况下，应能回答：

- 我刚才主要承诺了 `Launch / Tuning / Unit` 哪条轴？
- 第一次奖励改变了哪个机器组件？
- 这个改变怎样影响队列、部署节奏或单位质量？
- 下一场战斗我应该观察哪条战场结果？
- 结果页为什么说我赢、输、推线、漏兵或被反制？

Phase 2 只做可读性闭环，不追求内容量、长期平衡、完整美术表现或公开试玩质量。

## 2. Non-Goals

以下内容明确不属于 Phase 2：

- 不做完整 MVP 开发，不要求补齐 `docs/mvp-scope.md` 的全部短局内容。
- 不做公开 demo polish，不以商店页、宣传截图、完整 onboarding 或发布质量为目标。
- 不扩内容：不新增种族、单位、Guardian、敌人、反制家族、奖励系统、商店系统、事件、遗物或终点战内容。
- 不改平衡目标：可以让现有数值更可读，但不做长期强度定版。
- 不重写 playable session，不创建独立 3-step demo 来替代现有 session。
- 不改变正式术语：`Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Deploy Lane`、`Guardian`、`Gold` 保持不变。
- 不引入直接操作已部署单位、自由 RTS 寻路、PVP、联网、账号、后端、匹配或 Steam 集成。
- 不把 `Overdrive` 做成 MVP 基础按钮。
- 不使用 `docs/archive/` 或归档 prototype 作为当前实现依据。

## 3. Player Understanding Target

Phase 2 的玩家理解目标不是“玩家知道所有规则”，而是“玩家能把第一轮机器承诺和战场结果连起来”。

最低理解目标：

1. 玩家能在 Battle 1 后指出当前最明显的机器轴倾向。
2. 玩家能理解第一次奖励是在选择一个 `Launch / Tuning / Unit` 承诺，而不是随机加成。
3. 玩家能说出第一次奖励改变的机器组件和队列效果。
4. 玩家能在下一场战斗前知道应该观察的 battlefield outcome。
5. 玩家能在结果页读出主轴、关键奖励、关键战场回合、弱点、敌人反制影响和下一局建议。

失败信号：

- 玩家只说“我造了更多兵”。
- 玩家只说“我点对了路线”。
- 玩家不知道第一次奖励属于 `Launch / Tuning / Unit` 哪条轴。
- 玩家看不出队列条目为什么进入某条路。
- 玩家看完结果页仍不知道下一场应该观察什么。

## 4. Battle 1 Readability Requirements

Battle 1 必须发生在现有 playable session 内。不要把它缩成独立 tutorial、单独 demo 或 debug-only 场景。

Battle 1 必须让玩家看到：

- 当前机器输出了什么队列条目。
- 队列条目来自哪类机器变化或当前机器状态。
- 当前 `Deploy Lane` 是哪一路。
- 队列头会部署到哪一路。
- 单位部署后不会因为玩家切换 `Deploy Lane` 而改路。
- 战斗结果至少能读出推进、僵持、漏兵、Gate 受压或胜负原因中的一个主信号。

Battle 1 不要求展示所有系统。它只需要建立第一条因果链：机器输出 -> 队列 -> 路线 -> 战场结果。

## 5. Player-Facing Machine Causality Feedback Requirements

机器因果反馈必须出现在 playable session 的玩家视野内。Debug scenes 可以用于验证，但不能作为 Phase 2 的交付物。

玩家侧反馈必须说明：

- 当前主要机器轴：`Launch`、`Tuning` 或 `Unit`。
- 当前触发或变化的机器组件。
- 该组件如何影响队列条目、部署节奏、单位质量或路线压力。
- 当前队列头与下一次部署的关系。
- 哪个 battlefield outcome 可以证明这次机器变化有用或没用。

反馈应短、明确、可扫视。不要用大段教学文本掩盖规则不可读。

## 6. First Reward Axis Commitment Requirements

第一次奖励必须被呈现为玩家的第一条机器轴承诺，而不是普通数值奖励。

第一次奖励界面或选择反馈必须清楚说明：

- 该奖励属于 `Launch / Tuning / Unit` 哪条轴。
- 它改变的机器组件是什么。
- 它改变的 queue effect 是什么，例如队列产生频率、队列条目质量、队列批量、部署间隔或特定槽位贡献。
- 玩家下一场战斗应该观察什么 battlefield outcome，例如持续补兵、重复重击、批量冲锋、推线、守门、减少漏兵或抵抗某个既有反制。

关键检查 1：First Reward 必须被下一场战斗的 causality feedback 接住。玩家选择奖励后，下一场战斗必须提示或展示“刚才的奖励正在改变什么，以及应该观察什么结果”。

## 7. Next-Battle Causality Feedback After First Reward

第一次奖励后的下一场战斗是 Phase 2 的核心验证点。

下一场战斗必须展示：

- 玩家刚承诺的主轴。
- 上一场选择的 Most Impactful Reward 候选。
- 该奖励导致的当前机器或队列变化。
- 应观察的 next watch target。
- 结果发生后，是否能在战场上看到对应信号。

如果下一场战斗没有让玩家看到 First Reward 的后果，Phase 2 视为未通过，即使 Battle 1 本身可读。

## 8. Queue-to-Lane Bridge Requirements

`Deploy Lane` 必须读成“队列部署目的地”，不能读成“直接控制已部署单位”。

关键检查 2：Queue-to-Lane bridge 必须可读。

最低要求：

- 当前选中路线必须高亮。
- 队列头必须显示或暗示将部署到当前 `Deploy Lane`。
- 玩家切换 `Deploy Lane` 后，后续队列条目使用新路线。
- 已经部署的单位保留原路线，不随新的 `Deploy Lane` 点击改路。
- 路线危险提示只能辅助判断，不应盖过机器因果。

如果玩家以为 `Deploy Lane` 是直接指挥战场单位，Phase 2 视为未通过。

## 9. Result Page Machine-Cause Recap Fields

结果页必须把战斗结果回接到机器原因，而不是只显示胜负、奖励或统计。

结果页至少包含以下字段：

| 字段 | 必须回答的问题 |
|---|---|
| Main Axis | 这一局当前最明显的 `Launch / Tuning / Unit` 倾向是什么？ |
| Most Impactful Reward | 哪个奖励最明显改变了机器、队列或战场结果？ |
| Key Battlefield Turn | 哪个战场节点最能证明机器选择产生了结果？ |
| Weakest Link | 当前构筑最明显的断点是什么，例如断兵、低质量、漏路、Gate 受压或被反制？ |
| Enemy Counter Impact | 既有敌人反制对机器轴、队列或战场结果造成了什么影响？ |
| Next Run Suggestion | 下一局或下一次选择应该观察或修正什么？ |

字段可以先用稳定、明确的短文本，不要求最终视觉设计。不要为了填字段发明新系统或隐藏规则。

## 10. Minimal Existing Counter Clarity Constraints

Phase 2 可以澄清既有反制，但只能在核心可读性闭环完成后做。

允许范围：

- 解释 `Pool Polluter`、`Echo Breaker`、`Stagger Punisher` 等既有反制正在影响什么。
- 让 warning、active effect、allowed response 和结果页说明更清楚。
- 把反制影响接回 `Launch / Tuning / Unit`、queue effect 和 battlefield outcome。

禁止范围：

- 不新增反制家族。
- 不新增敌人。
- 不新增平衡层。
- 不新增内容池。
- 不把反制变成隐藏税或全局惩罚。
- 不让反制提示盖过 First Reward 和 Queue-to-Lane 的核心因果。

## 11. Verification

标准验证命令从仓库根目录运行：

```bash
bash mvp/tools/verify_all.sh
```

Phase 2 每个实现边界完成后都应运行该命令，除非是本文件这样的 docs-only 变更。docs-only 变更可以不运行 Godot，但汇报时必须写明未运行原因。

实现阶段的验证应覆盖：

- Battle 1 是否在现有 playable session 内可读。
- playable session 内是否有玩家侧机器因果反馈。
- First Reward 是否表达 `Launch / Tuning / Unit` 承诺、机器组件变化、queue effect 和 next watch target。
- First Reward 后的下一场战斗是否出现 causality feedback。
- Queue-to-Lane bridge 是否可读。
- 结果页是否包含 6 个 machine-cause recap 字段。
- 既有 counter clarity 是否没有扩内容或新增系统。

GoPeak MCP 可作为运行时检查、LSP 诊断和截图自检的补充；它不替代标准命令。

## 12. Controlled External Playtest Readiness Criteria

Phase 2 结束后可以进入小范围外部 playtest 的最低条件：

- 玩家可以从现有 playable session 开始，不需要开发者解释 debug UI。
- Battle 1 能建立机器输出、队列、`Deploy Lane` 和战场结果的第一条因果链。
- 第一次奖励能被读成 `Launch / Tuning / Unit` 的承诺。
- 第一次奖励后的下一场战斗能展示该承诺的后果。
- Queue-to-Lane bridge 可读，不会被误解为直接指挥已部署单位。
- 结果页 6 个 recap 字段都有稳定文案或稳定占位，不依赖口头解释。
- 既有 counter 提示不会制造新规则误解。
- 运行 `bash mvp/tools/verify_all.sh` 通过，或明确记录阻塞原因。

外部 playtest 目的只验证可读性，不验证商业化吸引力、公开 demo 质量、长期留存、完整平衡或内容规模。
