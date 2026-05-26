# Codex Goal Prompt：三段弹球出兵 UI 与机制重构

> 使用方式：把本文件放到当前项目根目录，例如 `CODEX_GOAL_THREE_STAGE_PINBALL_UI_REWORK.md`。  
> 在 Codex 里上传/附上我提供的 UI 参考图，然后执行本文中的 `/goal`。  
> 当前项目是 Vite + TypeScript + Phaser 的 Web 原型，不要切换引擎。

---

## 0. 直接给 Codex 执行的 `/goal`

```text
/goal

Read CODEX_GOAL_THREE_STAGE_PINBALL_UI_REWORK.md first.
Use the attached UI reference image as the visual source of truth.

Rework the current Phaser prototype into a three-stage horizontal pinball pipeline UI:

1. Top control strip must be ONE horizontal row, split left-to-right into:
   - compact 发球区 / Launch Zone
   - medium 抉择区 / Decision Zone
   - largest 出兵区 / Unit Spawn Zone

2. The battlefield must be the visual main body of the screen.
   It must remain a constrained fake 2D 3/4 auto-battle field, not a flat side-view lane and not a free RTS map.

3. 发球区 is small. It only preprocesses balls:
   - 分裂
   - 发射
   - 落空
   It must not dominate the screen.

4. 抉择区 must also be a pinball area with balls bouncing/falling, not static cards.
   Its outcomes are:
   - 出兵
   - 金币
   - 法术
   - 升级
   - 特殊
   Only 出兵 sends the ball into the 出兵区. Other outcomes resolve immediately.

5. 出兵区 must also be a pinball area with balls bouncing/falling.
   Do not render it as only static unit cards.
   A ball entering the 出兵区 falls through pegs/bumper-like obstacles and lands into one of five unit slots.
   Each unit slot accumulates progress before spawning:
   - 兵种1: 0/1
   - 兵种2: 0/3
   - 兵种3: 0/5
   - 兵种4: 0/7
   - 兵种5: 0/9
   When progress reaches the requirement, spawn that specific unit and keep overflow progress.

6. Implement one continuous overall gate/挡板 in the 出兵区, not separate gates per unit.
   The gate covers the high-tier right side at the start.
   At battle start, only 兵种1 is open.
   As time passes, the single gate shrinks from left to right, gradually exposing 兵种2, 兵种3, 兵种4, and 兵种5.
   At about 50% of the expected battle/phase duration, the gate is fully open.
   If a ball hits the covered high-tier area early, it must bounce back into the currently open lower-tier area.
   Do not award high-tier progress while it is covered.

7. Preserve the existing non-PVP direction.
   Do not implement PVP, networking, backend, accounts, matchmaking, Steam integration, buildings, relics, or complex manual RTS controls.

8. Keep the current continuous phase/battle work if present.
   Do not reintroduce hard wave resets that clear all player units.

9. Use readable art.
   Do not use plain rectangles as the only unit/slot representation.
   Use existing SVG/generated assets where possible, and create additional SVG fallback assets if new unit slots need them.

10. Update tests, README, and docs/PROGRESS.md.
    Run npm test, npm run typecheck, and npm run build.
    Stop only when the acceptance criteria in this file pass.
```

---

## 1. 当前项目背景

当前仓库已经是一个 Web / Phaser / TypeScript 原型，核心方向是：

- 物理弹球机器驱动出兵和收益。
- 下方/主体区域是自动战斗战场。
- 玩家不微操单位。
- 当前不考虑 PVP。
- 当前不考虑建筑系统。
- 当前不考虑遗物系统。
- 当前目标是快速做出可玩、可看、能验证机制的原型。

当前技术栈应该保持：

```text
Vite
TypeScript
Phaser 3
Matter physics for pinball-style ball areas
Custom deterministic logic for the auto-battle field
SVG or generated image assets
```

不要迁移到 Godot。不要上 Three.js。不要做真 3D。

---

## 2. 本次设计结论总览

### 2.1 核心画面结构

画面应分成两大块：

```text
┌──────────────────────────────────────────────────────────┐
│ 顶部控制条：发球区 | 抉择区 | 出兵区                         │
├──────────────────────────────────────────────────────────┤
│                                                          │
│                    主体：2D 3/4 自动战场                   │
│                                                          │
├──────────────────────────────────────────────────────────┤
│ 底部小 HUD：时间、阶段、速度、金币、日志/小地图，可很薄       │
└──────────────────────────────────────────────────────────┘
```

顶部控制条必须是一排，不是多排纵向堆叠。

推荐 1280x720 下的比例：

```text
顶部控制条高度：约 210 到 240 px
底部 HUD 高度：约 60 到 80 px
战场区域高度：剩余大部分，约 400 到 450 px
```

顶部宽度比例：

```text
发球区：15% - 22% 宽度
抉择区：25% - 32% 宽度
出兵区：46% - 58% 宽度
```

发球区必须明显比出兵区小。出兵区是顶部控制条里的重点。

### 2.2 战场视觉

战场必须是画面主体。

要求：

- 采用 2D / 3/4 视角。
- 保留受控兵线逻辑。
- 不要做自由 RTS 大地图。
- 不要做复杂寻路。
- 单位自动推进、自动索敌、自动攻击。
- 可以用现有 fake 2D 3/4 投影逻辑，但要让战场占屏幕主体。

战场不是平面横版小条。不要把战场压成底部一条。

---

## 3. 三段发球流程

整个发球流程是三段流水线：

```text
发球区
处理球本身：分裂 / 发射 / 落空
        ↓
抉择区
决定本次收益类型：出兵 / 金币 / 法术 / 升级 / 特殊
        ↓
出兵区
只有“出兵”结果进入此区；决定具体兵种并累计进度
        ↓
战场区
满足进度需求后，具体单位进入自动战场
```

一颗球可能经历 2 到 3 次判定：

```text
普通球 → 发球区 → 抉择区 → 如果是出兵 → 出兵区 → 兵种进度 → 战场
```

---

## 4. 发球区 / Launch Zone

### 4.1 职责

发球区只负责处理球本身，不直接决定最终收益。

它的结果只有：

```text
分裂
发射
落空
```

### 4.2 视觉要求

发球区应是紧凑的小弹球盒。

必须包含：

- 发球器 / 投球口。
- 少量 peg / bumper。
- 三个底部或出口槽：分裂、发射、落空。
- 球在里面可见地弹跳/下落。

不要把发球区做成整个顶部的主区域。它只是第一道预处理器。

### 4.3 结果规则

#### 分裂

```text
1 颗球进入分裂槽
→ 生成 2 颗球进入抉择区
```

第一版可以让分裂球仍然算普通球。后续再做轻球/重球。

#### 发射

```text
球进入发射槽
→ 生成 1 颗球进入抉择区
```

#### 落空

```text
球进入落空槽
→ 不进入抉择区
→ 显示“落空”反馈
```

第一版可以只做文字反馈。也可以给少量保底值，但不是本次优先。

---

## 5. 抉择区 / Decision Zone

### 5.1 职责

抉择区决定这颗球转化成什么类型的收益。

### 5.2 视觉要求

抉择区也必须是弹球区域。

不要把它做成静态按钮或卡片。它应该有：

- 球从顶部进入。
- 少量 peg / bumper / 分流板。
- 底部五个结果槽。
- 球落入对应槽位后触发结果。

### 5.3 结果槽

第一版使用 5 个结果：

```text
出兵
金币
法术
升级
特殊
```

注意：当前不要重新引入 CHARGE / 蓄力系统。以后再说。

### 5.4 结果规则

#### 出兵

```text
球落入 出兵
→ 不直接生成单位
→ 生成 1 颗球进入 出兵区
```

这是唯一会进入第三阶段的结果。

#### 金币

```text
球落入 金币
→ 立即增加金币
→ 球销毁
```

可以复用现有 `triggerGold` 或等价逻辑。

#### 法术

```text
球落入 法术
→ 触发现有法术效果
→ 球销毁
```

可以复用现有 `triggerMagic` 或等价逻辑。

#### 升级

```text
球落入 升级
→ 触发现有升级逻辑
→ 球销毁
```

可以复用现有 `triggerUpgrade` 或等价逻辑。

#### 特殊

```text
球落入 特殊
→ 触发一个简单特殊效果
```

第一版特殊可以非常简单：

- 随机触发金币 / 升级 / 法术之一。
- 或下一次进入出兵区的球 +1 价值。
- 或立即额外投一颗球进入发球区。

不要因为特殊槽引入大系统。

---

## 6. 出兵区 / Unit Spawn Zone

### 6.1 职责

出兵区决定具体出什么兵。

它不是静态兵种卡展示区。它也是弹球区域。

流程：

```text
抉择区中的“出兵”结果
→ 生成一个出兵球
→ 出兵球进入出兵区
→ 出兵球弹跳/下落
→ 落入具体兵种槽
→ 该兵种进度 + 球值
→ 满足需求后生成该兵种
```

### 6.2 视觉要求

出兵区应是顶部控制条中最大的区域。

必须显示：

- 球从顶部进入。
- 出兵区内有 peg / bumper / 弹跳路径。
- 下方有 5 个兵种槽。
- 每个兵种槽有单位图标/剪影、名字、进度条、进度文本。
- 整体挡板/闸门覆盖未开放的高阶区域。
- 挡板随时间缩短，逐步开放更高阶兵种。

示意：

```text
┌─────────────────────────────────────────────┐
│ 出兵区                                       │
│    ●  ·   ·   ·   ·   ·   ·   ·             │
│  ·    ●    ·    ●    ·    ●                 │
│                                             │
│ [整体挡板覆盖高阶区域，随时间缩短]           │
├────────┬────────┬────────┬────────┬────────┤
│ 兵种1  │ 兵种2  │ 兵种3  │ 兵种4  │ 兵种5  │
│ 0/1    │ 0/3    │ 0/5    │ 0/7    │ 0/9    │
└────────┴────────┴────────┴────────┴────────┘
```

### 6.3 兵种进度

第一版固定 5 个兵种槽：

```text
兵种1：需求 1
兵种2：需求 3
兵种3：需求 5
兵种4：需求 7
兵种5：需求 9
```

球值：

```text
普通球 = 1 点进度
```

落入兵种槽后：

```text
unitProgress[slot] += ball.value
while unitProgress[slot] >= requirement:
    unitProgress[slot] -= requirement
    spawn that specific unit
```

必须保留溢出进度。

例子：

```text
兵种3 当前 4/5
普通球落入兵种3
→ 5/5
→ 生成兵种3
→ 进度回到 0/5
```

如果后续有重球：

```text
兵种3 当前 4/5
重球值为 2
→ 6/5
→ 生成兵种3
→ 剩余 1/5
```

### 6.4 替换当前随机出兵逻辑

当前原型中，SPAWN 可能直接从种族池里随机挑单位。

本次重构后：

```text
抉择区的 出兵 不应直接随机生成单位。
出兵只负责把球送入出兵区。
具体单位由出兵区的具体兵种槽决定。
```

如果保留 debug 按钮“触发出兵”，它应该：

```text
生成一个球进入出兵区
```

或者直接调用一个测试函数给当前开放兵种槽加进度。不要再绕过出兵区成为主要玩法。

---

## 7. 出兵区整体挡板 / 总体闸门

### 7.1 关键结论

出兵区的遮挡不是每个槽单独挡板。

必须是：

> 一整块连续挡板，从右向左覆盖高阶兵区域。随着时间推进，这块整体挡板逐渐缩短，开放范围从兵种1逐步扩展到兵种5。

### 7.2 初始状态

开局只开放兵种1。

```text
可用：兵种1
被挡板覆盖：兵种2、兵种3、兵种4、兵种5
```

### 7.3 完全开放时间

设：

```text
D = 当前战斗/阶段的预计持续时间
```

本版本中可以使用当前 `phaseDef.durationMs` 作为 D。

规则：

```text
在 0.5 * D 时，挡板完全缩短，兵种1~5 全部开放。
```

### 7.4 开放边界

用一个 `openBoundaryX` 表示当前开放到哪里。

```text
startBoundary = 兵种1右边界
endBoundary = 兵种5右边界
progress = clamp(elapsedMs / (D * 0.5), 0, 1)
openBoundaryX = lerp(startBoundary, endBoundary, progress)
```

被开放区域：

```text
x <= openBoundaryX
```

被挡板覆盖区域：

```text
x > openBoundaryX
```

视觉上挡板应覆盖：

```text
[openBoundaryX, 出兵区右边界]
```

### 7.5 撞挡板弹回

如果球试图进入当前未开放区域：

```text
不增加该兵种进度
不销毁球
不消耗球
保留球属性
球被挡板弹回开放区域
显示“未开放 / 弹回”反馈
```

第一版实现可以采用以下任意方式：

1. 真 Matter 碰撞体：挡板区域是动态/可重建的静态碰撞体。
2. Sensor + velocity nudge：当球进入 covered area 时，立即给它一个朝开放区的速度并显示反馈。
3. Hybrid：视觉上画连续挡板，逻辑上用 boundary sensor 判断是否弹回。

优先保证玩法和可读性，不要在物理完美度上浪费太久。

### 7.6 防卡死规则

每颗出兵区球记录 `blockedGateHits`。

```text
每撞一次未开放挡板：blockedGateHits += 1
如果 blockedGateHits >= 3：强制把球导向当前开放范围内的某个可用兵种槽
```

这不是直接结算，而是给球一个明显的引导速度，避免无限弹跳。

---

## 8. 多种族与 5 个兵种槽

### 8.1 当前要求

每个种族必须在 UI 上显示 5 个兵种槽。

如果当前代码只有 3 个单位，请扩展到 5 个单位。

第一版可以用简单但可读的 SVG fallback 资产，不要用纯方块。

### 8.2 推荐单位结构

#### Hive / 虫群

```text
兵种1：Grub / 小虫，需求 1，基础近战
兵种2：Spitter / 喷吐虫，需求 3，远程
兵种3：Carapace / 甲壳虫，需求 5，前排
兵种4：Brood Guard / 巢群卫士，需求 7，高阶前排或精英虫
兵种5：Behemoth / 巨虫，需求 9，巨型单位
```

#### Mech / 机械

```text
兵种1：Drone / 无人机，需求 1，基础单位
兵种2：Gunner / 机枪手，需求 3，远程
兵种3：Walker / 步行机甲，需求 5，前排
兵种4：Siege Crawler / 攻城履带，需求 7，攻城
兵种5：Titan / 泰坦机甲，需求 9，巨型单位
```

不需要最终平衡，但需要看出层级。

### 8.3 数据结构建议

可以增加：

```ts
export type UnitSlotDef = {
  index: number;           // 0..4
  unitId: string;
  label: string;
  requirement: number;     // 1,3,5,7,9
};
```

RaceDef 可扩展：

```ts
export interface RaceDef {
  id: RaceId;
  name: string;
  color: number;
  unitSlots: UnitSlotDef[];
  unitPool?: string[]; // 兼容旧逻辑时可保留
}
```

GameState 可增加：

```ts
unitSlotProgress: Record<string, number>; // key 可以是 unitId
```

或者：

```ts
unitSlotProgress: Record<RaceId, number[]>;
```

推荐 `Record<string, number>`，便于切换种族后保留各单位进度。

---

## 9. 物理球阶段状态

### 9.1 球的阶段

每颗球需要知道自己在哪个阶段：

```ts
type BallStage = 'launch' | 'decision' | 'unit';
```

每颗球至少携带：

```ts
type BallData = {
  id: string;
  stage: BallStage;
  value: number; // first version: 1
  blockedGateHits?: number;
};
```

### 9.2 阶段转移

#### 发球区 → 抉择区

```text
分裂：destroy launch ball, create 2 decision balls
发射：destroy launch ball, create 1 decision ball
落空：destroy launch ball, show miss feedback
```

#### 抉择区 → 出兵区

```text
出兵：destroy decision ball, create 1 unit ball
金币/法术/升级/特殊：resolve immediately, destroy decision ball
```

#### 出兵区 → 战场

```text
unit ball lands in an open unit slot
→ add progress
→ spawn concrete unit when requirement is met
→ destroy unit ball
```

---

## 10. Phaser / Matter 实现建议

### 10.1 推荐布局常量

可以用类似下面的常量。可根据实际画面微调。

```ts
const GAME_W = 1280;
const GAME_H = 720;

const TOP_Y = 12;
const TOP_H = 225;
const HUD_H = 68;
const BATTLE_Y = TOP_Y + TOP_H + 8;
const BATTLE_H = GAME_H - BATTLE_Y - HUD_H - 8;

const LAUNCH_X = 14;
const LAUNCH_W = 250;
const DECISION_X = LAUNCH_X + LAUNCH_W + 10;
const DECISION_W = 350;
const UNIT_X = DECISION_X + DECISION_W + 10;
const UNIT_W = GAME_W - UNIT_X - 14;
```

重点不是具体数值，而是：

```text
发球区小
抉择区中等
出兵区最大
战场是主体
```

### 10.2 Matter 世界

当前代码可能只有一个左侧球道区域。需要改成三个顶部区域都能运行球。

可以选择：

- 一个 Matter world，所有顶部 pinball 区共享。
- 每个区分别创建自己的静态边框、peg、sensor。

建议仍用一个 Matter world，但所有 ball 通过 `stage` 数据和 sensor label 区分。

Sensor label 建议：

```text
launch:split
launch:fire
launch:miss

decision:spawn
decision:gold
decision:magic
decision:upgrade
decision:special

unit:0
unit:1
unit:2
unit:3
unit:4
unit:coveredGate
```

### 10.3 生成球函数

建议拆成：

```ts
spawnLaunchBall(value = 1)
spawnDecisionBall(value = 1)
spawnUnitBall(value = 1)
```

不要继续只有一个 `dropBall()`。

`dropBall()` 可以作为 debug 函数调用 `spawnLaunchBall()`。

### 10.4 处理碰撞

建议拆成：

```ts
handleLaunchZoneHit(ball, outcome)
handleDecisionZoneHit(ball, outcome)
handleUnitZoneHit(ball, unitSlotIndex)
handleUnitGateBlocked(ball)
```

不要把所有逻辑塞在一个巨大 collision 函数里。

---

## 11. SlotTriggerSystem 改造建议

当前可能有：

```ts
triggerSlot(state, 'spawn')
triggerSlot(state, 'upgrade')
triggerSlot(state, 'gold')
triggerSlot(state, 'magic')
```

本次改造后：

- `gold`、`upgrade`、`magic` 可以继续复用。
- `spawn` 不应再直接随机选择单位进入队列。
- `spawn` 可以改成“进入出兵区”的事件，但实际单位生成要由出兵区进度系统完成。

建议新增一个系统：

```text
UnitSpawnProgressSystem.ts
```

包含：

```ts
addUnitSlotProgress(state, unitId, amount)
getCurrentUnitGateOpenBoundary(state)
getUnlockedUnitSlotCount(state)
resolveUnitBallToSlot(state, unitSlotIndex, ballValue)
```

或者按现有风格命名即可。

---

## 12. 测试要求

必须更新/新增测试。

### 12.1 单元测试：单位进度

测试：

```text
兵种2需求为3。
连续给兵种2增加 1、1、1 点进度后，生成 1 个兵种2。
溢出进度保留。
```

### 12.2 单元测试：整体挡板开放

测试：

```text
elapsed = 0 时，只开放兵种1。
elapsed = 0.25D 时，开放边界在中段。
elapsed = 0.5D 时，全部开放。
elapsed > 0.5D 时，仍全部开放。
```

### 12.3 单元测试：covered area 不加高阶进度

测试：

```text
在开局状态，兵种5被挡板覆盖。
尝试让球进入兵种5。
不增加兵种5进度。
球应被标记为 bounced/redirected，或逻辑返回 blocked。
```

### 12.4 旧测试更新

如果当前测试断言 slotDefs 只有 4 个：

```ts
['spawn', 'upgrade', 'gold', 'magic']
```

需要更新为当前设计：

```ts
['spawn', 'gold', 'magic', 'upgrade', 'special']
```

实际顺序可按 UI 使用，但要保证测试与数据一致。

不要加入 CHARGE。

---

## 13. 视觉验收标准

最终运行时必须满足：

1. 顶部三块在同一排：发球区、抉择区、出兵区。
2. 发球区明显较小。
3. 抉择区有球弹来弹去。
4. 出兵区也有球弹来弹去。
5. 出兵区不是静态卡片区。
6. 出兵区有一整条连续挡板/闸门。
7. 挡板随着时间缩短。
8. 开局只有兵种1可稳定吃球。
9. 时间推进到约阶段/战斗时长一半时，兵种1~5全部开放。
10. 球撞到未开放高阶区域会弹回开放区域。
11. 每个兵种显示进度，例如 0/1、1/3、2/5、0/7、0/9。
12. 满进度后，具体单位进入战场。
13. 战场是画面主体，采用 2D 3/4 视角。
14. 战场不是自由 RTS 地图。
15. 没有 PVP、建筑、遗物、联网。

---

## 14. 交互与调试按钮

可以保留调试按钮，但要对应新流程。

推荐按钮：

```text
投球：生成一颗发球区球
进抉择：生成一颗抉择区球
进出兵：生成一颗出兵区球
切种族
继续阶段
跳过阶段
```

旧按钮“触发出兵”不要直接随机生成单位。它可以改成：

```text
生成一颗出兵区球
```

这样调试也不会绕过核心机制。

---

## 15. 美术资源要求

不要只用纯色方块作为单位。

如果缺少 5 个兵种的美术资源：

- 优先用 Codex 图片生成工具生成统一风格 PNG/SVG。
- 如果图片生成不可用，创建干净的 SVG fallback。
- 每个单位至少有明确剪影。
- 每个槽位至少有图标。
- 出兵区的挡板要清楚，最好是金属板或能量遮罩。

视觉风格：

```text
2D / 3/4 strategy prototype
dark fantasy or sci-fi fantasy UI
clean silhouettes
readable icons
strong faction colors
no copyrighted IP
no direct Z-Arcade / Warcraft / Castle Fight asset copying
```

---

## 16. 不要做的事

本次不要做：

1. PVP。
2. 联网。
3. 建筑系统。
4. 遗物系统。
5. Steam 接入。
6. 真 3D。
7. 复杂 RTS 寻路。
8. 手动微操单位。
9. 把战场改成横版小条。
10. 把发球区做成最大区域。
11. 把抉择区做成静态卡牌。
12. 把出兵区做成静态单位卡牌。
13. 给每个兵种单独做独立挡板。
14. 在未开放高阶区命中时偷偷加高阶进度。
15. 引入 CHARGE / 蓄力槽。

---

## 17. 推荐实现步骤

### Step 1：审计当前结构

先看这些文件：

```text
src/scenes/PrototypeScene.ts
src/types/game.ts
src/data/slots.ts
src/data/races.ts
src/data/units.ts
src/systems/SlotTriggerSystem.ts
src/systems/SpawnQueueSystem.ts
src/systems/BattleSystem.ts
src/systems/PhaseSystem.ts
src/systems/prototypeRules.test.ts
src/rendering/assets.ts
```

不要直接大改，先理解当前球道、槽位、战场和奖励逻辑。

### Step 2：扩展类型与数据

新增/修改：

```text
BallStage
DecisionSlotId
UnitSlotDef
unitSlotProgress
special slot
5-unit race definitions
```

### Step 3：创建三段顶部 UI 布局

把现有左侧大球道改成顶部一排三块：

```text
发球区 | 抉择区 | 出兵区
```

重排战场，让战场成为主体。

### Step 4：实现三段球流转

实现：

```text
launch ball → decision ball → unit ball
```

### Step 5：实现出兵区进度与具体单位生成

`出兵` 结果不再直接随机生成单位。

具体单位由出兵区命中槽位决定。

### Step 6：实现整体挡板

- 单个连续挡板。
- 随时间缩短。
- 被覆盖区域弹回。
- D/2 完全开放。

### Step 7：更新视觉反馈

包括：

- 球轨迹。
- 槽位闪光。
- 进度条。
- 挡板状态。
- “弹回 / 未开放”提示。
- 单位生成提示。

### Step 8：更新测试与文档

必须跑：

```bash
npm test
npm run typecheck
npm run build
```

更新：

```text
README.md
docs/PROGRESS.md
```

---

## 18. 最低可接受版本

如果完整物理实现耗时过高，最低可接受版本是：

- 三个顶部区域都可见。
- 三个区域都有可见球运动。
- 抉择区和出兵区可以使用简化物理或 tween 模拟弹跳。
- 出兵区必须有可见的整体挡板。
- 出兵区必须有球落入兵种槽并累计进度。
- 战场必须仍为 2D 3/4 主体。
- npm test / typecheck / build 通过。

不接受：

- 只有发球区有球，抉择区/出兵区没有球。
- 出兵区只是单位卡牌。
- 每个兵种单独挡板。
- 战场被压到很小。

---

## 19. 验收清单

实现完成后逐项确认：

```text
[ ] npm test 通过
[ ] npm run typecheck 通过
[ ] npm run build 通过
[ ] 顶部三块在同一排
[ ] 发球区小于抉择区和出兵区
[ ] 出兵区是顶部最大区域
[ ] 战场是画面主体
[ ] 战场是 2D / 3/4 视角
[ ] 发球区有 分裂 / 发射 / 落空
[ ] 抉择区有 出兵 / 金币 / 法术 / 升级 / 特殊
[ ] 抉择区有球弹跳/下落
[ ] 出兵区有球弹跳/下落
[ ] 出兵区有五个兵种槽
[ ] 兵种需求为 1 / 3 / 5 / 7 / 9
[ ] 兵种进度可见
[ ] 满进度会生成具体单位
[ ] 出兵区有一个连续整体挡板
[ ] 挡板随时间缩短
[ ] D/2 时所有兵种开放
[ ] 未开放高阶区命中会弹回，不加进度
[ ] 当前没有 PVP
[ ] 当前没有建筑系统
[ ] 当前没有遗物系统
[ ] README 已更新
[ ] docs/PROGRESS.md 已更新
```

---

## 20. 一句话目标

最终目标不是做一个复杂弹珠机，而是：

> 用顶部一排三段弹球流水线，驱动下方 2D / 3/4 自动战场；玩家看到球先被预处理，再决定收益类型，最后如果是出兵，就进入出兵区累计具体兵种进度。出兵区通过一个随时间缩短的整体挡板，保证前期低阶兵稳定，中后期逐步开放高阶兵。

