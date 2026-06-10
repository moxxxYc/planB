# PlanB Battle UI Flow 1.0 Draft

**Date:** 2026-06-10  
**Status:** Draft artifact, not canonical design  
**Scope:** Formal player-facing UI flow for MVP v0 screens.  
**Do not use as:** implementation approval, code state proof, final GDD canon, or debug UI spec.

## 0. Source And Authority

This draft continues from:

- `docs/gstack-artifacts/planb-battle-ui-flow-session-20260610.md`

It is constrained by the current formal docs:

- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `docs/battlefield-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/mvp-scope.md`
- `docs/mvp-hive-loadout.md`
- `docs/rewards-economy.md`
- `docs/DESIGN.md`

This document records a confirmed page-flow direction and Battle Screen layout direction. It does not update the formal design docs by itself.

## 1. Hard Constraints

- This is formal player-facing UI design.
- Debug UI is out of scope unless explicitly requested.
- Do not include debug overlays, sliders, development panels, test-only controls, implementation-state messages, or hidden-state readouts.
- Do not restore old Web MVP, old Battle Lab, archived prototype assumptions, or old visual layout assumptions.
- Guardian is an in-world attacking base entity, not a HUD panel.
- Player Guardian is not directly controlled.
- Deployed units are not directly controlled.
- `Deploy Lane` is selected by clicking the battlefield lane itself.
- Battle UI must preserve the machine-to-frontline causal chain: machine result -> queue -> selected lane -> battlefield result.

## 2. Confirmed Page Flow

```text
Main Menu
-> Guardian Contract
-> Battle Screen
-> Battle Result
-> Reward Choice / Shop / Rest
-> repeat battle loop as needed
-> Final Result
-> Main Menu / New Run
```

Pages not in the first pass:

- Complex save / continue page.
- Codex / glossary page.
- Standalone enemy preview page.
- Multi-Guardian team editor.
- Long-term progression page.
- Debug UI.

## 3. Page 1: Main Menu

Purpose:

- Cold-start entry into a short run.
- Do not teach the machine, Guardian, or Deploy Lane systems here.
- Do not show battle UI here.

Recommended structure:

```text
PlanB

[开始新短局]

设置
退出
```

Suggested tagline:

```text
把一台不稳定的出兵机器，推成前线优势。
```

Confirmed behavior:

- `开始新短局` enters `Guardian Contract`.
- `设置` opens settings.
- `退出` exits the game.
- Do not show disabled `继续游戏` unless save / continue exists.

## 4. Page 2: Guardian Contract

Purpose:

- Let the player choose the current run's Guardian.
- Frame the choice as machine bias plus base fallback.
- Avoid implying direct hero control.

Recommended title:

```text
选择守护者契约
```

Recommended subtitle:

```text
选择本局机器偏向与基地兜底方式
```

Recommended structure:

```text
选择守护者契约
选择本局机器偏向与基地兜底方式

[巢脉母 契约卡]        [酸冠母 契约卡]

所选契约预览
- 影响机器轴
- 战场触发方式
- 适合打法
- 风险提醒

[签订契约，开始 Battle 1]
[返回主菜单]
```

Guardian cards should include:

- Guardian name.
- Portrait / silhouette.
- Machine contract.
- Battlefield contract.
- Suitable play tendency.
- What this Guardian will not solve.

Confirmed Guardian framing:

- `巢脉母`: biased toward `Launch / Recycle`, stabilizes machine cycling through recycle return.
- `酸冠母`: biased toward `Tuning / Gate -> Prime`, converts repeated Gate misses into Prime opportunity.
- Prefer `守护者契约` over `选择 Player Guardian`.

## 5. Page 3: Battle Screen

Battle Screen is the core page. It must show the machine, queue bridge, and battlefield as one causal chain.

### 5.1 Overall Layout

Confirmed direction:

```text
三仓机器 38% | Queue / Deploy Bridge 14% | 战场 48%
```

Rationale:

- The three warehouses need vertical clarity more than extreme width.
- The battlefield needs enough width for in-world Guardian entities, three lanes, lane gates, and base-circle pressure.
- The bridge must remain visible because it explains queue -> selected lane deployment.

### 5.2 Battlefield Layout

Confirmed direction: Candidate B, lightly curved three-lane battlefield.

```text
玩家基地圈                                      敌方基地圈
┌────────────┐                            ┌────────────┐
│ Player     │╲── Left Gate ───────────╱│ Enemy      │
│ Guardian   │─── Mid Gate  ────────────│ Guardian   │
│ HP / skill │╱── Right Gate───────────╲│ HP / sweep │
└────────────┘                            └────────────┘
```

Rules:

- The underlying battle model remains three fixed one-dimensional paths.
- Curves are visual layout, not free-map pathing.
- `Left / Mid / Right` lanes remain directly clickable.
- `Mid` is the default selected lane at battle start.
- Selected lane uses player-color double rail / edge highlight and entry / exit markers.
- Lane danger uses enemy-color shapes and pulses, separate from selected-lane highlight.

### 5.3 Guardian And Spawn Ports

Important correction:

- Guardian and spawn ports are separate in-world objects.
- Units do not spawn from the Guardian.
- Units spawn from the selected lane's player-side spawn port / lane gate.

Recommended player-side base structure:

```text
玩家基地圈内部
┌────────────────┐
│  Player        │
│  Guardian      │
│        ○ ○ ○   │  three spawn ports / lane gates
└────────┼─┼─┼───┘
         L M R
```

Rules:

- Player Guardian sits inside the base circle, toward the inner / rear side.
- Three spawn ports sit on the lane-facing edge of the player base circle.
- There is visible base buffer space between Guardian and the three spawn ports.
- Enemy units break through the lane gate, enter the base buffer, then pressure the Guardian.
- Guardian basic attack and tactical skill can operate inside this base buffer.
- Guardian range should not cover the full lane.
- Enemy Guardian / Endpoint follows the same battlefield-entity principle on the enemy side.

Why the buffer matters:

- Without buffer, `Gate breached`, `base invaded`, and `Guardian hit` collapse into one unreadable moment.
- With buffer, the player can read the sequence: lane pressure -> gate danger -> breach -> base invasion -> Guardian pressure.

### 5.4 Guardian Information Display

Guardian information attaches to the in-world entity, not to a bottom HUD panel.

Recommended display:

- HP bar above the Guardian or along the base circle edge.
- Cooldown / tactical readiness as a small ring, crest, or entity-attached marker.
- Guardian range shown only on pressure, attack, hover, or skill preview. Do not keep it always visible if it clutters lanes.
- Tactical skill feedback plays around the Guardian or affected invaders.

Do not use:

- Bottom Guardian card.
- Guardian selection list inside battle.
- Detached Guardian dashboard.
- Text-only Guardian combat logs.

### 5.5 Queue / Deploy Bridge

Purpose:

- Show what the machine has produced and where the next deployment will go.

Recommended structure:

```text
Queue
[Head] [Next] [Next]
Deploy beat
Current Lane: Mid
```

Rules:

- Show the queue head and at most two upcoming entries.
- Show current `Deploy Lane`.
- Show deployment beat / timing.
- On deploy, animate a short connection from Queue Bridge to the selected spawn port.
- The bridge points to the selected spawn port, not to Guardian and not to lane center.
- It does not simulate the full future.
- It does not recommend an optimal route.

### 5.6 Three-Warehouse Machine Area

The battle screen should show the minimum readable machine state:

- `Launch / Tuning / Unit` stacked vertically.
- `Forge / Pool / Launcher`.
- Active ball / recent ball path.
- `Gate / Prime / Echo / Surge`.
- Four Unit slots with progress / required.
- Unit exposure gate state.
- Queue output.

The machine area should not become a debug panel. Exact implementation metrics and temporary controls are out of scope.

### 5.7 Top Bar

Recommended minimal top bar:

- Battle number.
- Gold, only if relevant in battle.
- Small selected Guardian identity marker.

Do not turn the top bar into a full resource dashboard unless later formal docs require it.

### 5.8 Bottom Event Strip

Optional. If used, it should show only high-value player-facing events:

- A major machine result.
- A lane danger escalation.
- A Guardian tactical trigger.
- An enemy counter warning that has already been publicly revealed.

Do not show implementation logs, hidden pressure values, debug state, or tutorial paragraphs.

### 5.9 Battle Screen Reference Image

Generated reference images from this session:

- First rough candidate B mockup:
  `/Users/yang/.codex/generated_images/019eb0eb-028d-7a63-8332-5346c23bde29/ig_0508a1552f80d24d016a29326a6614819480ecbefcf9f6f416.png`
- Revised candidate B mockup with Guardian / spawn-port buffer:
  `/Users/yang/.codex/generated_images/019eb0eb-028d-7a63-8332-5346c23bde29/ig_0508a1552f80d24d016a29344c2ddc819480503c5c2fba78c2.png`

The revised mockup is the better structure reference. Text, labels, and unit names inside the generated image are placeholders, not canon.

## 6. Page 4: Battle Result

Purpose:

1. Tell the player whether they won or lost.
2. Explain the main reason in terms of machine, lane, and Guardian pressure.
3. Route the player to the next loop step.

Do not turn this into a full battle log or DPS spreadsheet.

### 6.1 Victory Structure

```text
战斗胜利

Battle 1
敌方 Guardian 已击破

核心回放
- 主推进路线：Mid
- 关键机器兑现：Tuning.Prime 命中酸囊虫，打破 Mid 僵持
- 最高危险路线：Left
- Guardian 介入：巢脉牵缚触发 2 次，延缓入侵

本场获得
Gold +6

[继续：选择奖励]
```

### 6.2 Failure Structure

```text
战斗失败

Player Guardian 被击破

主要断裂
- Left Gate 过早被破
- Queue 出兵断档 4.8s
- 当前 Deploy Lane 长时间停在 Mid，未补 Left

下局观察
- 注意路线危险 2 级提示
- 观察 Queue 是否断档
- 不要等敌人进基地圈后才切路

[返回主菜单]
[重新开始短局]
```

### 6.3 Recommended Visual Layout

```text
┌────────────────────────────────────────┐
│ 战斗胜利                               │
│ Battle 1                               │
├────────────────────────────────────────┤
│ 左：结果摘要                           │
│ - Enemy Guardian defeated              │
│ - Player Guardian HP remaining         │
│                                        │
│ 右：小型三路回放图                     │
│ - 主推进路线高亮                       │
│ - 最高危险路线标红                     │
├────────────────────────────────────────┤
│ 关键原因                               │
│ [机器兑现] [路线选择] [Guardian 介入]  │
├────────────────────────────────────────┤
│ Gold +6                                │
│                         [继续]         │
└────────────────────────────────────────┘
```

Battle Result should preserve the three-lane mental model. A small three-lane recap is better than pure text.

Do not show:

- DPS table.
- Full unit damage ranking.
- Hidden pressure values.
- Debug log.
- AI recommended route.
- Every internal machine event.

## 7. Page 5: Reward Choice / Shop / Rest

This page group covers post-battle upgrades and recovery windows. Battle 1 reward and Battle 2 shop are not the same state.

### 7.1 Reward Choice

Purpose:

- Let the player select one machine modifier that deepens, pivots, or patches the current build.

Recommended structure:

```text
选择本场奖励

上一场结果
Battle 1 Victory
主推进路线：Mid
最高危险路线：Left

选择 1 个机器修正

[Launch 奖励] [Tuning 奖励] [Unit 奖励]

所选预览
- 改了哪个机器组件
- 下一场应该看哪里
- 可能补了什么洞 / 强化了什么轴

[确认奖励，进入下一战]
```

Reward cards must show:

- Axis: `Launch / Tuning / Unit`.
- Target component, for example `Launch.Pool.capacity`.
- Operation, for example `+1 capacity`.
- Player read, for example "更容易维持连续发射".
- Risk, for example "不会直接提高单位战斗力".

Do not use generic rewards like:

- "All damage +15%".
- "All units gain HP".
- "Global output up".

### 7.2 Shop / Rest Window

Battle 2 after a normal victory is the first shop / rest window under the current economy direction.

Recommended structure:

```text
商店 / 休整

Gold: 12

中立修正
本次最多购买 1 个

[商品卡 A] [商品卡 B] [商品卡 C]

休整
Player Guardian HP: 54 / 100
[花费 3 Gold，恢复 20 HP]
本窗口剩余休整次数：1

所选购买预览
- 花费
- 剩余 Gold
- 改了哪个机器组件
- 下一场看哪里

[确认，进入下一战]
```

Shop rules:

- Gold is a post-battle resource, not a kill resource.
- Neutral modifiers have a purchase limit.
- Rest is not a neutral machine modifier.
- Rest does not consume the neutral modifier purchase quota.

Rest button text should be explicit:

```text
花费 3 Gold，恢复 Player Guardian 20 HP
```

Disabled states:

- Gold insufficient.
- Guardian HP full.
- Rest uses exhausted for this window.

## 8. Page 6: Final Result

Purpose:

- Summarize the whole short run, not just the final fight.
- Tell the player what build actually formed.
- Show what almost broke.
- Give a next-run observation target.

Recommended structure:

```text
短局胜利 / 短局失败

本局契约
巢脉母 / 酸冠母

本局机器主轴
Launch / Tuning / Unit

构筑摘要
- 核心奖励：
- 商店修正：
- 关键补洞：
- 最高风险：

战斗路径
Battle 1  胜利  Mid 推进
Battle 2  胜利  Left 高压守住
Battle 3  胜利  Pool Polluter 反制解除
Battle 4  胜利  Tuning 兑现
Battle 5  胜利  Endpoint 前整备
Endpoint  胜利  Mid 破门终结

本局观察
- 什么生效了
- 什么差点断
- 下一局可以尝试什么

[返回主菜单]
[再次开始短局]
```

### 8.1 Victory Copy Direction

```text
短局胜利

Endpoint Guardian 已击破

本局主轴：Tuning
Prime 命中多次转化为酸囊虫破点，Mid 路成为主要推进路线。

关键选择
- 契约：酸冠母
- 奖励：Prime 命中强化
- 商店：Gate 偏移修正
- 休整：Endpoint 前恢复 20 HP

最大压力
Left 路在 Battle 3 和 Battle 5 多次进入破门风险。

下一局观察
如果继续走 Tuning，注意 Pool 污染会拖慢有效命中。
```

### 8.2 Failure Copy Direction

```text
短局失败

Player Guardian 被击破

本局主轴未成型：Launch
Pool 回流变强，但 Unit 队列仍多次断档，未能转化为稳定前线。

主要断裂
- Battle 3 开始 Left 路持续漏兵
- Queue 出兵空档多次超过 4s
- Guardian 触发守家，但无法独自稳线

下一局观察
- 不要只补 Launch 输入量
- 观察 Unit slot 是否真的形成队列
- 路线危险 2 级出现时提前切 Deploy Lane
```

Do not show:

- Hidden grade like `S`, `SS`, or `A+`.
- Total damage ranking as the main read.
- Full battle log.
- "Guardian carried this run" style framing.
- Vague blame like "操作不佳".
- AI recommendation button.

## 9. Current Confirmed Decisions

- Page flow is a short-run loop from Main Menu through Final Result.
- Guardian Contract happens before Battle 1.
- Battle Screen uses three major zones: machine, bridge, battlefield.
- Battle Screen ratio target is `38 / 14 / 48`.
- Battlefield uses lightly curved three-lane layout.
- Guardian is an in-world attacking base entity.
- Player Guardian and spawn ports are separated by a visible base buffer.
- Units spawn from lane spawn ports / gates, not from Guardian.
- Queue Bridge points to the selected spawn port.
- `Deploy Lane` is selected by clicking lane bodies.
- Battle Result uses small three-lane recap and key causes.
- Battle 1 after victory routes to Reward Choice.
- Battle 2 after victory routes to Shop / Rest under current economy direction.
- Final Result summarizes the whole run, not only Endpoint.

## 10. Still Unresolved

These remain design tasks, not implementation tasks:

1. Exact Guardian sprite size relative to units and base circle.
2. Exact base buffer width and Guardian attack range display rule.
3. Exact spawn portal visual shape and animation.
4. Exact lane curve degree and click target thickness.
5. Exact Battle Screen top bar contents.
6. Whether bottom event strip is needed in the first playable implementation.
7. Final wording for reward cards, shop cards, and result pages.
8. Whether Battle Result should show Guardian tactical triggers as count, icon, or short replay marker.
9. Exact page transition timing between Battle Result and Reward / Shop / Rest.
10. Controller / keyboard navigation for lane selection and card selection.

## 11. Next Recommended Step

Use this draft as the basis for either:

1. A `game-ux-review` pass focused only on screen-to-screen clarity and HUD scan burden.
2. A `prototype-slice-plan` pass for a non-canon Fast Prototype Lane, if the user explicitly confirms implementation.
3. A formal docs update, if the user wants these UI decisions promoted from draft artifact into canonical design docs.

Do not start implementation from this file without explicit user confirmation.
