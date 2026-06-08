# /plan-design-review - 球机同屏可读性与物理反馈

Date: 2026-06-08  
Branch: `mvp`  
Plan file: `docs/ball-machine-physical.md`  
Review scope: 同屏可读性、物理反馈、战中 HUD 信息层级、物理状态覆盖。  
Design system: not found.

## Scope Check

Intent: review `docs/ball-machine-physical.md` for same-screen readability and physical feedback before implementation planning.

Delivered: reviewed the candidate physical-machine plan against `docs/gdd.md`, `docs/machine-warehouses.md`, `docs/deploy-lane-ui.md`, `docs/mvp-learning-checkpoints.md`, and current `/game-review` failure modes.

Not in scope:

- Full production art direction. No `docs/DESIGN.md` exists yet.
- Code, engine choice, physics implementation, collision tuning.
- Re-promoting `docs/ball-machine-physical.md` into canon.
- Archived prototype behavior. Current docs say it is expired.

Review staleness: reviewed working tree docs, not HEAD-only. `docs/ball-machine-physical.md` and several current design docs are uncommitted/new in this checkout, so HEAD is not the source of truth for this review.

## Step 0 - Scope And Initial Rating

UI scope exists. The plan defines a constant left machine strip, right battlefield, direct lane click, and visible machine rewrites.

Initial design completeness: 4.1/10.

Why 4.1: the plan defines physical topology and rule boundary, but does not yet define combat-screen attention priority, physical feedback state vocabulary, grayscale-safe visual grammar, or the exact one-second read the player should get during pressure.

What a 10 looks like for this plan:

- A combat screen hierarchy that says what wins attention first, second, third.
- A physical feedback grammar for natural hits, forced redirects, blocked bounces, recycle, split, waste, Junk, counter disruption, and logic-only settlement.
- A state matrix for each visible machine feature.
- A color + shape + motion rule so selected lane, danger lane, and machine counter warnings cannot collapse into the same visual cue.
- A validation script: 1-second glance test, Battle 1 30-second test, Prime 4-6s consequence test, and counter attribution test.

## What Already Exists

- `docs/gdd.md` establishes the main risk: players must see how `Launch / Tuning / Unit` changes the battlefield, and `Deploy Lane` must not become the main gameplay.
- `docs/machine-warehouses.md` defines the chain from `Forge -> Pool -> Launcher -> Launch Route Board -> Tuning -> Unit -> Queue -> Deploy Lane`.
- `docs/deploy-lane-ui.md` already separates selected lane from danger lane in wording: selected is player color, stable, persistent; danger is enemy color, pulsing, short-lived.
- `docs/mvp-learning-checkpoints.md` defines Battle 1 UI minimums and failure signals.
- Prior `/game-review` flags red behavior: player follows danger hints and ignores machine output, player describes all outputs as "more units", player cannot tell Pool pollution from enemy pressure.

## High Finding 1 - Same-Screen Hierarchy Is Underspecified

Severity: HIGH  
Confidence: MEDIUM. Based on current docs. Needs playtest to confirm.

Evidence:

- `docs/ball-machine-physical.md` puts three physical boards in a left strip and a three-lane battlefield on the right, all always visible.
- `docs/mvp-learning-checkpoints.md` requires Battle 1 to show Pool, Forge, Launcher, Tuning, Unit slots, Exposure Gate, Queue, Deploy Lane, and lane danger.
- `docs/deploy-lane-ui.md` warns that the UI fails if route danger becomes hidden recommendation or if players only stare at lanes.
- Prior `/game-review` red flags include "Player follows danger hints and ignores machine output."

Comparison context: the 1-second combat test asks what the player can read during pressure. This plan currently asks the player to read at least 9 UI elements in Battle 1. That is too much unless the hierarchy is explicit.

Player impact: players will follow the brightest lane warning and miss the machine cause. The game becomes route whack-a-mole.

PROPOSED ADDITION:

```markdown
## 同屏信息层级

战中 1 秒扫视只服务 3 个问题：

1. 下一次部署会去哪一路？
2. 这次部署来自哪条机器原因链？
3. 当前最危险的断裂是机器问题还是路线问题？

战中 HUD 优先级：

| Priority | 信息 | 屏幕位置 / 视觉处理 | 失败信号 |
|---|---|---|---|
| P0 | 当前 Deploy Lane + 下一次队列部署时间 + 最高危险路线 | 右侧战场上直接显示，稳定选中标记与短时危险标记分层 | 玩家以为点路会立刻造兵，或只跟危险提示点路 |
| P1 | 当前 active ball 的机器因果链 | 左侧球机只高亮当前球所在板和刚触发的结果槽，其他球降到背景层 | 玩家看不出 Unit progress 来自哪个球 |
| P2 | Queue head + Unit slot 即将填满状态 | 左右连接处显示队列首项和目标路线标记 | 玩家不知道下一批兵去哪一路 |
| P3 | Pool / Forge / 炮台节奏 / 其他球 | 左侧常驻但低对比，只有变化时短闪 | 玩家被所有运动分散注意 |

默认不让三块球机板同等抢眼。当前 ball 所在板、被反制攻击的组件、和刚发生的结算结果可以短时抢 P1，其余物理运动保持背景可见。
```

Re-rate after addition: Information Architecture 4/10 -> 8/10.

## High Finding 2 - Physical Feedback States Are Not Complete

Severity: HIGH  
Confidence: MEDIUM. The plan lists many unknowns and some examples, but no reusable state grammar.

Evidence:

- `docs/ball-machine-physical.md` marks pin/block layout, inter-board randomness, ball physics, return channels, Exposure barrier form, and every Guardian/modifier/counter physical expression as undecided.
- It defines forced slot override with "吸入口 / 导轨 / 磁吸" examples, but does not choose a common visual rule.
- `docs/machine-warehouses.md` says one physical ball can only gain one base Tuning result, one Unit hit, and one queue entry, while Echo is logic-only duplication.
- `docs/mvp-learning-checkpoints.md` flags failure when players think blocked balls disappear, or read `Prime / Echo / Surge` as random flashes.

Comparison context: Peglin-style boards work because the player watches the ball and reads contact. This plan needs three boards plus auto-battle. The feedback has to be more explicit than a normal pachinko board.

Player impact: players will not know whether a ball naturally hit, got forced, got blocked, got recycled, or produced logic-only value. That breaks cause and effect.

PROPOSED ADDITION:

```markdown
## 物理反馈状态语法

每次球机事件必须落入一种可见状态，不允许只闪一下。

| State | 触发 | 玩家看到 | 玩家读法 |
|---|---|---|---|
| Natural Hit | 球自然落入结果槽 | 槽口压下 / 咬合，球颜色保持自然，槽名短亮 | 这是物理落点决定的结果 |
| Forced Redirect | 命名规则强制改单颗落点 | 目标槽伸出导轨或吸入口，球出现短暂牵引线，源规则标记贴在槽边 | 这一颗被规则掰进去了 |
| Distribution Shift | 构筑改概率分布 | 钉子 / 活动块 / 槽宽发生永久或持续期形变，组件边缘保留来源小标记 | 以后更容易往这里走 |
| Blocked Bounce | Unit 未暴露区挡住球 | 挡板实体碰撞 + 反弹轨迹，不显示失败文字 | 球没消失，只是高级槽还没开 |
| Valid Unit Hit | 球进入已暴露 slot | slot 进度条吃入球，显示 `+value`，队列若生成则连线到 Queue head | 这个球推进了哪个单位槽 |
| Split Return | Launch Split | 球进入分裂回流通道，Pool 增加球时有回流路径动线 | 这是回流压力，不是直接出兵 |
| Recycle Return | Miss + Recycle | 球走回收通道，Pool 前/后位置按规则落位 | miss 但保住了输入流 |
| Waste | 无有效结算 | 球进入废弃口，短灰化，不弹错误弹窗 | 这颗没有产生有效机器结果 |
| Logic Settlement | Prime / Echo / Surge 等落定后效果 | 物理球已结束后，用槽位/队列的小标签展示数值或延迟变化 | 这是结算效果，不是第二颗物理球 |
| Counter Disruption | Pool Polluter / Echo Breaker / Stagger Punisher | 被攻击组件先预警，再显示生效结果，再留短暂痕迹 | 敌人打的是机器组件，不是随机加压 |
```

Re-rate after addition: Interaction State Coverage 3/10 -> 8/10.

## Medium Finding 3 - "Peglin Board" Is A Reference, Not A Visual Identity

Severity: MEDIUM  
Confidence: MEDIUM.

Evidence:

- `docs/ball-machine-physical.md` repeatedly frames the boards as "缩小版 Peglin 钉板".
- `docs/gdd.md` forbids copying existing games' rules, UI, names, or assets.
- `docs/gdd.md` says Hive uses insect shell, acid, hive-vein material, icon style, component appearance, motion feedback, and named effects.

Comparison context: a reference is useful in planning. A plan that reaches implementation with only "Peglin board" will produce a generic mini-pachinko strip.

Player impact: the machine may read as borrowed pachinko UI, not as this game's war-machine identity.

PROPOSED ADDITION:

```markdown
## 物理机器视觉身份约束

`Peglin 钉板` 只作为结构参考，不作为 UI 外观目标。

通用标签保持 `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`。视觉身份来自组件形态：

- `Launch`：读成供给和回流。Pool 口、回流管、废弃口和炮台必须比普通钉子更像机器组件。
- `Tuning`：读成转换质量。`Gate` 是宽出口；`Prime` 是充能槽；`Echo` 是双影 / 复写槽；`Surge` 是脉冲槽。四槽用形状区分，不只靠颜色。
- `Unit`：读成单位槽进度。四个 slot 是机器仓位，不是抽象 UI 条；Exposure Gate 是实体挡板。
- Hive 包装只改变材质、外壳、运动反馈和命名效果，不遮挡通用标签。
```

Re-rate after addition: AI Slop Risk 5/10 -> 8/10.

## Medium Finding 4 - Color-Only Separation Is Too Fragile

Severity: MEDIUM  
Confidence: MEDIUM.

Evidence:

- `docs/deploy-lane-ui.md` uses player color for selected lane and enemy color for danger.
- Route danger grades 1-3 rely on enemy-color warning points, pulses, Gate flash, and base-circle flash.
- `docs/mvp-learning-checkpoints.md` expects Battle 1 to include lane danger and current Deploy Lane at the same time.

Comparison context: the grayscale test asks whether the player can distinguish key states without color. Current text depends too much on color categories.

Player impact: selected lane and danger lane can collapse into "the glowing lane", especially in high pressure.

PROPOSED ADDITION:

```markdown
## 色盲 / 灰阶可读规则

所有战中关键信息必须使用 color + shape + motion 三重编码。

| 信息 | Color | Shape | Motion |
|---|---|---|---|
| 当前 Deploy Lane | 玩家色 | 双轨边框 + 入口/出口箭头 | 稳定慢流动 |
| 路线危险等级 1 | 敌方色 | 小三角预告点 | 短脉冲 |
| 路线危险等级 2 | 敌方色 | Gate 外框锯齿 / 破门符号 | 快脉冲 |
| 路线危险等级 3 | 敌方色 | 基地圈裂纹 / 入侵符号 | 一次强闪 + 短音效 |
| 机器组件被反制 | 反制色或敌方色 | 组件局部裂纹 / 污染覆盖 / 断线符号 | 预警倒计时 + 生效残留 |
| 当前 active ball | 中性色高亮 | 球外环 | 连续轨迹短尾 |
```

Re-rate after addition: Input/A11y 4/10 -> 7/10.

## Interaction State Matrix

| Feature | Normal | Success | Blocked / Failed | Forced / Override | Counter | Full / Capacity | Tutorial Read |
|---|---|---|---|---|---|---|---|
| Pool | 5-slot FIFO visible | ball enters/leaves with direction | Pool full rejects Recycle with clear lost-return feedback | N/A | Junk occupies visible slot | `current / capacity` and full outline | Player can point to supply buffer |
| Launcher | automatic 1.3s cadence | fired ball visibly leaves Pool | Pool empty shows dry-fire wait, no panic warning | N/A | counter can affect input only if named | N/A | Player sees launch rhythm |
| Launch Board | ball bounces through pins | Tuning/Split/Recycle/Waste slot bite | Waste greys out as no valid result | forced route uses guide/ingress if named | Pool Polluter marks input layer | N/A | Player sees supply vs miss vs return |
| Tuning Board | ball enters four-slot board | Gate/Prime/Echo/Surge label lights | Echo Breaker downgrades copy, not ball | Acid Crown forced Prime uses visible guide | Echo area cracks during warning | N/A | Player sees quality conversion |
| Unit Board | ball approaches slot bays | progress rises on exposed slot | blocked bounce off unexposed gate | Slot-target rules mark target bay | Stagger warns Queue, not slot itself | slot progress overflow obeys machine rules | Player sees low-to-high slots open over time |
| Queue | next 3 entries visible | entry moves to selected lane on deploy tick | empty queue shows gap timer only when relevant | Surge marks accelerated entry | Stagger gap warning attaches here | N/A | Player sees deployment is delayed |
| Deploy Lane | selected lane stable | birth flash confirms lane | clicking current lane no-op, no spam effect | named batch lock rules must mark lock | danger uses separate shape/motion | N/A | Player sees click changes route, not output |
| Lane Danger | 0-3 visible state | pressure resolves by deployed units | danger persists if unresolved | N/A | Stagger can raise route to 2 | N/A | Player sees warning, not recommendation |

## Pass Scores

| Pass | Initial | After Proposed Additions | Note |
|---|---:|---:|---|
| Scope | 5/10 | 8/10 | UI scope is real, but candidate status must remain clear. |
| Information Architecture | 4/10 | 8/10 | Adds explicit one-second combat hierarchy. |
| Interaction States | 3/10 | 8/10 | Adds state grammar and state matrix for physical feedback. |
| Player Journey | 6/10 | 7/10 | MVP checkpoints exist, but first death/result-page emotional handling is outside this scoped review. |
| AI Slop Risk | 5/10 | 8/10 | Converts "Peglin board" from visual target into structure reference. |
| Design System | 2/10 | 5/10 | No `docs/DESIGN.md`; physical grammar helps but is not a full design system. |
| Input / Accessibility | 4/10 | 7/10 | Adds grayscale-safe shape and motion pairings. |
| Unresolved Decisions | 4/10 | 7/10 | Lists the choices implementation must not guess. |

Weighted overall: 4.1/10 -> 7.3/10 if proposed additions are accepted.

## Unresolved Decisions

1. Same-screen focus rule:
   - Recommendation: active-ball board gets P1 focus, inactive boards remain visible but lower contrast.
   - If deferred: implementation may make all three boards equally bright, causing motion noise.

2. Exact distribution visibility:
   - Recommendation: do not show exact percentages in battle. Show physical slot shape and post-battle / debug sample summaries only.
   - If deferred: players may treat physical machine as a hidden probability table and argue with variance.

3. Forced redirect form:
   - Recommendation: choose one shared language, either guide rail or suction mouth. Do not mix magnetic pull, rail, and mouth per effect unless each family has a reason.
   - If deferred: forced outcomes will feel like bugs or hidden RNG correction.

4. Audio language:
   - Recommendation: every physical state above gets a small sound family: natural hit, forced redirect, blocked bounce, recycle, waste, counter hit.
   - If deferred: visual-only feedback will not survive screen overload.

5. Design system:
   - Recommendation: create `docs/DESIGN.md` before implementation planning, at least art direction, color/shape tokens, typography, HUD components, animation vocabulary.
   - If deferred: the first build will decide visual language accidentally.

## Potential Design Debt

Not written to `TODOS.md` because the skill asks for user disposition per item. Candidates:

- Create `docs/DESIGN.md` minimum viable UI design system.
- Define exact physical feedback animation/audio timings.
- Define same-screen playtest script for 1-second glance and Battle 1 30-second learning.
- Decide forced redirect form: guide rail vs suction mouth.
- Decide whether battle UI ever shows live distribution statistics.

## Design Review Status

| Review | Date | Score | Status |
|---|---|---:|---|
| /plan-design-review | 2026-06-08 | 4.1 -> 7.3 proposed | DONE_WITH_CONCERNS |

### Decisions Made

None. This review proposes additions only. The plan remains a candidate draft.

### Decisions Deferred

Five unresolved decisions listed above.

### Outside Voices

Not run. No separate reviewer tool was available in this session.

### Next Review

Run `/plan-design-review` again if the proposed additions are accepted and written into `docs/ball-machine-physical.md`. Run `/prototype-slice-plan` only after physical feedback grammar and one-screen hierarchy are accepted.

```text
+====================================================================+
|         GAME DESIGN PLAN REVIEW - COMPLETION SUMMARY               |
+====================================================================+
| Game:                | planB                                      |
| Branch:              | mvp                                        |
| Plan file:           | docs/ball-machine-physical.md              |
| Design system:       | not found                                  |
+--------------------------------------------------------------------+
| Step 0  (Scope)      | 5/10, scoped to same-screen readability    |
| Pass 1  (Info Arch)  | 4/10 -> 8/10 proposed                      |
| Pass 2  (States)     | 3/10 -> 8/10 proposed                      |
| Pass 3  (Journey)    | 6/10 -> 7/10 proposed                      |
| Pass 4  (AI Slop)    | 5/10 -> 8/10 proposed                      |
| Pass 5  (Design Sys) | 2/10 -> 5/10 proposed                      |
| Pass 6  (Input/A11y) | 4/10 -> 7/10 proposed                      |
| Pass 7  (Decisions)  | 0 resolved, 5 deferred                     |
+--------------------------------------------------------------------+
| NOT in scope         | written, 4 items                           |
| What already exists  | written                                    |
| Decisions made       | 0                                          |
| Decisions deferred   | 5                                          |
| Overall score        | 4.1/10 -> 7.3/10 proposed                  |
+====================================================================+
| Status: DONE_WITH_CONCERNS                                         |
+====================================================================+

Next Step:
  PRIMARY: /plan-design-review - accept/reject the proposed additions, then write them into the plan
  if accepted: /prototype-slice-plan - scope the first readability build around one-screen hierarchy and physical feedback
  if visual identity remains open: /game-ux-review - after implementation exists, validate the built screen against the plan
```
