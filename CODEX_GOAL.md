/goal
在 mvp 分支上修正当前挡板以外的 P0 问题。注意：这是作者自测版本，不是玩家发布版本，所以不要隐藏 debug 控件；保留底部“投球 / 进抉择 / 进出兵 / 切种族 / 继续阶段 / 跳过阶段”等测试按钮。

本次目标只做 4 件事：
1. 让抉择区槽宽奖励真实生效。
2. 让开局能稳定看到一次完整出兵闭环。
3. 给金币一个最小可用消费点。
4. 让升级收益和预备队状态更可见。

不要处理挡板。
不要重做战场。
不要新增建筑、遗物、PVP、自由 RTS 寻路、复杂商店、复杂科技树。
不要把出兵逻辑改回 unitPool weighted random 直接抽兵。
不要破坏三段弹球流程：launch -> decision -> unit。
不要破坏 Unit Zone 5 个兵种槽累计进度逻辑。

---

## 当前问题

### 问题 1：槽宽奖励目前像“假改造”

当前奖励里有类似：
- 出兵槽宽度 +20%
- 金币槽宽度 +20%
- 出兵槽宽度 -10%
- 修改 state.slots[slotId].widthWeight

但抉择区 createOutcomeSlots / slot layout 仍然按等宽计算：
- 金币 / 法术 / 出兵 / 升级的 sensor 和视觉 plate 都是固定等宽
- widthWeight 没有真正影响物理命中面积
- 玩家选了槽宽奖励后，机器结构没有真实改变

这必须修。

### 实现要求

1. 抉择区槽位宽度必须基于 `state.slots[slotId].widthWeight` 做加权布局。
2. 每个 decision slot 的：
   - sensor body 宽度
   - sensor body x 坐标
   - plate 视觉宽度
   - label / count 文本位置
   都必须跟随权重变化。
3. 奖励修改 widthWeight 后，必须重新 layout 或重建抉择区槽位。
4. 不要只改视觉；物理 sensor 必须真实变宽/变窄。
5. 不要改发球区和出兵区的核心流程。
6. 可以在槽位 label 或 HUD 上显示当前权重，例如：
   - 出兵 x1.2
   - 金币 x1.3
   但不是必须；优先保证物理和视觉一致。

### 验收标准

- 选择“出兵槽宽度 +20%”后，抉择区出兵槽肉眼变宽。
- 球更容易落入出兵槽。
- 选择“金币槽宽度 +20%”后，金币槽肉眼变宽。
- 选择降低出兵槽宽的奖励后，出兵槽肉眼变窄。
- sensor 命中区域和视觉槽位一致。
- 不允许出现“视觉变了但球仍按旧区域判定”的情况。

---

## 问题 2：开局缺少稳定的完整出兵闭环

当前随机情况下，开局可能连续命中金币 / 法术 / 升级，导致很久看不到：
decision 命中出兵 -> unit ball 进入出兵区 -> 落入兵种槽 -> 累计进度 -> 满进度生成单位 -> 单位进入战场

这会影响作者测试核心玩法，不是因为要照顾玩家，而是因为每次测试都需要快速验证主链路。

### 实现要求

做一个轻量的“开局闭环保底”，只用于原型测试，不要做复杂教程系统。

推荐实现：

1. 在 GameState 或 Scene 状态里增加一个简单标记，例如：
   - `hasSeenFirstSpawnLoop`
   - `firstLoopAssistActive`
   - `firstSpawnOutcomeForced`
   - `firstUnitSlotForced`
2. 在第一阶段开始后的前 10 秒内，如果还没有产生过任何我方单位，则保证触发一次完整出兵闭环。
3. 保底方式可以采用以下之一：
   - 第一颗或第二颗 decision ball 强制/引导命中 `spawn` 槽；
   - 第一次进入出兵区的 unit ball 优先导向兵种 1 槽；
   - 或在物理上给球一个轻微导向速度，而不是直接凭空加单位。
4. 不要直接跳过 unit zone 进度逻辑。
5. 不要直接调用随机单位池出兵。
6. 必须仍然经过：
   - decision outcome = spawn
   - 创建 unit ball
   - unit ball 落入 unit slot
   - slot progress 增加
   - 满足 requirement 后 queueSpecificUnit
   - updateSpawnQueue 部署到战场
7. 这套保底只需要保证首次闭环，不要长期接管随机物理。

### 验收标准

- 新开一局后，不用点 debug 按钮，前 10 秒内至少能看到一次完整出兵闭环。
- 兵种 1 的进度至少被 unit ball 正常增加。
- 第一个单位必须来自 Unit Zone 槽位进度满，而不是直接从 unitPool 抽出来。
- HUD 的“出”统计会增加。
- 我方单位数会从 0 变成 1 或更多。
- 后续流程恢复正常随机，不要每次都强制出兵。

---

## 问题 3：金币现在缺少最小用途

当前金币可以获得和显示，但没有明确消费点。这样金币槽会显得像空收益。

不要做完整商店。
不要加建筑。
不要加复杂经济系统。

本次只做一个最小用途：阶段奖励界面允许花金币 reroll 一次奖励。

### 实现要求

1. 在阶段奖励选择界面增加一个 reroll 按钮。
2. reroll 消耗金币，建议第一版成本固定：
   - 10 金币
   或如果当前金币产出偏低，可以先用：
   - 5 金币
3. 每个阶段奖励界面最多 reroll 一次，避免无限刷。
4. 金币不足时：
   - reroll 按钮置灰
   - 或显示“金币不足”
5. reroll 后：
   - 扣除金币
   - 当前 3 个奖励重新生成
   - 尽量避免和 reroll 前完全相同的 3 个奖励
6. 不要让 reroll 自动选择奖励。
7. 不要改变奖励三选一的基本结构。

### 验收标准

- 命中金币槽后，金币数增加。
- 阶段结束出现奖励选择时，可以用金币 reroll 一次。
- reroll 会扣除金币。
- reroll 后奖励列表刷新。
- 同一个奖励界面不能无限 reroll。
- 金币不足时不能 reroll。
- 不新增商店页面，不新增建筑，不新增外围系统。

---

## 问题 4：升级收益和预备队状态不够可见

当前升级可能影响：
- pendingSpawnLevelBonus
- 机械种族的单位等级
- 后续出兵强度

但界面上不够清楚。玩家/作者测试时很难快速判断“升级槽命中后具体发生了什么”。

预备队也不够清楚。当前单位从 slot progress 满 -> queue -> spawn 到战场，中间层在 HUD 上表达不足。

### 实现要求 A：升级可见

1. HUD 增加一项显示：
   - `下次出兵 Lv+X`
   或：
   - `出兵加成 Lv+X`
2. 如果 `pendingSpawnLevelBonus > 0`，必须显示出来。
3. 如果机械种族某个单位槽被升级，该单位槽上显示当前等级，例如：
   - Lv1
   - Lv2
   - Lv3
4. 单位实际入队或部署时，floating text 需要带等级：
   - `Lv2 幼虫兵 入队`
   - `Lv3 无人机 部署`
5. 不要只在 console log 里显示。

### 实现要求 B：预备队可见

1. HUD 或出兵区附近增加一个轻量“预备队”显示。
2. 显示即将部署的前 3～5 个单位即可。
3. 每个预备队 item 至少显示：
   - 单位短名或 icon
   - 等级
   - 是否精英，如果已有该状态
4. 当 unit slot 满进度并 queueSpecificUnit 后，预备队显示应立即更新。
5. 当 updateSpawnQueue 把单位释放到战场后，预备队显示应减少。
6. 不需要做复杂动画；第一版文字/小 icon 列表即可。

### 验收标准

- 命中升级槽后，HUD 能看到 `下次出兵 Lv+X` 变化。
- 机械种族升级单位后，对应槽位能看到 Lv 变化。
- 出兵入队/部署时，反馈文字带等级。
- 单位进入预备队后，界面能看到预备队列表。
- 单位部署到战场后，预备队列表同步减少。
- 不改变出兵队列的底层释放逻辑，只增强可见性。

---

## 明确不要做

- 不要隐藏 debug 控件；这是作者自测版本。
- 不要处理挡板开放节奏、挡板视觉、挡板碰撞反馈。
- 不要改成正式玩家教程。
- 不要新增建筑系统。
- 不要新增遗物系统。
- 不要新增 PVP。
- 不要做自由 RTS 寻路。
- 不要做正式美术。
- 不要做完整商店。
- 不要把金币用途扩成复杂经济。
- 不要把单位生成改成“命中出兵后随机抽单位”。
- 不要绕过 Unit Zone 的 5 槽进度。
- 不要破坏当前虫群 / 机械的 5 槽结构。

---

## 建议修改位置

优先搜索和修改这些相关点：

1. 抉择区槽位布局：
   - `createOutcomeSlots`
   - `decisionSlotDefs`
   - decision slot sensor / plate 创建逻辑
   - `state.slots[slotId].widthWeight`

2. 奖励应用：
   - `applyReward`
   - 所有修改 `widthWeight` 的 reward
   - 奖励应用后触发 decision slot relayout

3. 开局闭环保底：
   - decision ball 命中 outcome 的处理
   - spawn outcome 创建 unit ball 的处理
   - unit ball 落入 slot 的处理
   - `resolveUnitBallToSlot`
   - `queueSpecificUnit`
   - `updateSpawnQueue`

4. 金币 reroll：
   - 阶段奖励 UI
   - reward option generation
   - gold state
   - reward select / apply flow

5. 升级和预备队显示：
   - HUD update
   - unit slot UI update
   - floating text / combat text
   - spawn queue state display

---

## 完成后的自测流程

请按这个顺序手动验证：

1. 启动项目。
2. 不点 debug 按钮，观察开局 10 秒。
3. 确认至少出现一次：
   - decision 命中出兵
   - unit ball 进入出兵区
   - 兵种 1 槽进度增加
   - 单位入队
   - 单位部署到战场
4. 用 debug 按钮或正常流程进入奖励选择。
5. 选择“出兵槽宽度 +20%”。
6. 确认抉择区出兵槽视觉宽度变大，sensor 命中区域也变大。
7. 选择或触发金币收益。
8. 阶段奖励界面用金币 reroll 一次，确认扣钱和刷新奖励。
9. 触发升级槽。
10. 确认 HUD 显示 `下次出兵 Lv+X`。
11. 切到机械种族测试升级，确认单位槽显示 Lv 变化。
12. 产生多个单位，确认预备队列表显示并随部署减少。

---

## 构建检查

完成后必须运行：

- npm install 如果依赖缺失
- npm run typecheck
- npm run build

如果项目没有 typecheck script，则运行可用的 TypeScript 检查或 build。
修复所有 TypeScript / build 报错后再结束。
