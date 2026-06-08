# MVP v0 视觉与反馈设计前置

**最后更新：** 2026-06-08
**仓库状态：** 纯文档态，无当前正式实现。
**文档状态：** MVP v0 `/implementation-handoff` 前置设计系统。本文提供实现假设，不等于最终美术 canon、最终 UI 规范或最终音频资产表。

本文只定义第一版实现不能临场发明的视觉和反馈语言。玩法规则以 `docs/gdd.md`、`docs/machine-warehouses.md`、`docs/battlefield-rules.md`、`docs/deploy-lane-ui.md`、`docs/guardian-system.md`、`docs/mvp-scope.md`、`docs/mvp-learning-checkpoints.md` 和 `docs/neutral-modifiers.md` 为准。球机物理表现以 `docs/ball-machine-physical.md` 为 MVP v0 实现假设。

## 1. Art Direction

MVP v0 的画面目标是“可读的物理战争机器”，不是华丽插画，也不是抽象数值面板。

方向：

- 左侧是三块串联球机，必须读成一台会造兵的机器。
- 右侧是三路自动战场，必须读成真实单位在推进、僵持、漏兵和破门。
- Hive 包装使用虫壳、酸液、巢脉和硬质甲片质感，但不能遮住通用标签。
- `Peglin` 只作为钉板结构参考，不作为 UI 外观目标。
- 机器标签保持 `Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Unit slot`、`Queue`、`Deploy Lane`。
- 关键反馈优先于装饰。背景细节不能压过 active ball、当前 Deploy Lane、最高危险路线、被反制组件和 Queue head。

不做：

- 不使用旧 Web MVP 或旧 Battle Lab 的视觉假设。
- 不把球机做成纯概率表。
- 不把三路战场做成三条抽象进度条。
- 不用颜色单独承载规则含义。

## 2. Color / Shape Tokens

颜色是辅助识别，规则含义必须同时由 shape 和 motion 支撑。以下 token 是 MVP v0 实现起点，后续可因对比度和 playtest 调整。

| Token | 候选颜色 | Shape / Motion 配对 | 用途 |
|---|---|---|---|
| `bg.machine` | `#171A18` | 暗金属底板，低对比纹理 | 左侧球机背景。 |
| `bg.battlefield` | `#20211D` | 路径线和基地圈保持清晰边缘 | 右侧战场背景。 |
| `text.primary` | `#E8E1D2` | 无额外动效 | 主要标签和数值。 |
| `player.primary` | `#56B4E9` | 双轨边框 + 入口 / 出口箭头 + 稳定慢流动 | 当前 `Deploy Lane`。 |
| `enemy.warning` | `#E84B4B` | 三角、锯齿、裂纹 + 脉冲 | 路线危险和敌人预警。 |
| `launch.axis` | `#7BCB6B` | 管道、回流箭头、Pool 槽 | `Launch` 组件和持续流反馈。 |
| `tuning.axis` | `#E6B450` | 充能槽、双影槽、脉冲槽 | `Tuning` 组件和高价值命中反馈。 |
| `unit.axis` | `#C58BE8` | 四个实体仓位、进度吃入、批量队列标记 | `Unit` 槽、Queue 和批量部署反馈。 |
| `hive.acid` | `#B7F25C` | 酸液边缘、短喷口、溅射痕 | Hive 酸液表现。 |
| `hive.shell` | `#8A5A44` | 虫壳甲片、硬边槽口 | Hive 外壳和单位剪影。 |
| `counter.pollution` | `#7C5A8A` | 污染覆盖、Junk 槽占用 | Pool Polluter 和 Junk。 |
| `neutral.flash` | `#F4F0D8` | 短闪，不常驻 | 命中确认和短时强调。 |

Shape tokens：

| Token | 形状 | 规则读法 |
|---|---|---|
| `lane.selected` | 双轨边框 + 两端箭头 | 我当前会从这里出兵。 |
| `lane.danger.1` | 小三角预告点 | 这路即将有压力。 |
| `lane.danger.2` | Gate 外框锯齿 | 这路有破门风险。 |
| `lane.danger.3` | 基地圈裂纹 | 漏兵或入侵已经发生。 |
| `ball.active` | 球外环 + 短轨迹尾 | 当前要读的 active ball。 |
| `machine.counter` | 裂纹 / 污染覆盖 / 断线符号 | 敌人正在攻击机器组件。 |
| `redirect.guide` | 短导轨 / 引导槽 | 指定球被命名规则强制改道。 |
| `tuning.gate` | 宽出口 | 普通进入 Unit。 |
| `tuning.prime` | 充能槽 / 菱形电容 | 高价值命中。 |
| `tuning.echo` | 双影槽 / 双层口 | 重复结算。 |
| `tuning.surge` | 折线脉冲槽 | 加速部署节奏。 |
| `unit.exposure` | 实体挡板 | 高需求槽尚未完全开放。 |

## 3. HUD Components

HUD 只服务 1 秒扫视，不展示完整未来模拟。

| Component | 位置 | MVP v0 必须显示 | Placeholder OK |
|---|---|---|---|
| Machine Strip | 左侧竖条 | `Launch / Tuning / Unit` 三板、active ball、刚触发结果槽。 | 钉子和活动块可以是几何占位。 |
| Forge / Pool / Launcher | 左上到 Launch 顶部 | Forge 进度、Pool `current / capacity`、Launcher 发射节拍。 | Pool 球可用简单圆点。 |
| Tuning Result | Tuning 板底部 | `Gate / Prime / Echo / Surge` 命中标签和短反馈。 | 具体槽材质可占位。 |
| Unit Slots | Unit 板底部 | 4 个 slot、progress / required、Exposure Gate、blocked bounce。 | 单位图标可用剪影。 |
| Queue Bridge | 左右连接处 | 下一个 queue entry、部署节拍、当前路线标记。 | 只预览 3 个条目。 |
| Deploy Lane Overlay | 战场路线本体 | 当前选中路线、出生口短闪、点击反馈。 | 路线可以是简单路径线。 |
| Lane Danger | 战场路线和 Gate / base | 0-3 档危险，shape + motion 分层。 | 敌人出生预告可用几何标记。 |
| Guardian HUD | 两端基地圈附近 | Player Guardian HP、Endpoint Guardian HP、战术技能触发反馈。 | Guardian 可用大剪影。 |
| Reward Cards | 战后界面 | 机器轴、目标组件、operation、玩家读法。 | 卡面插图可空缺。 |
| Shop Cards | 商店界面 | Gold、价格、`Patch / Pivot / Deepen / Rest`、购买额度。 | 商品图标可用轴 icon。 |
| Result Page | 战后结果 | 主轴兑现、关键奖励 / 商店、反制、Deploy Lane 影响、失败观察标签。 | 第一版可以文字较重。 |

HUD 优先级：

1. P0：当前 `Deploy Lane`、下一次部署、最高危险路线。
2. P1：active ball 的机器因果链、刚触发槽、被反制组件。
3. P2：Queue head、即将填满的 Unit slot。
4. P3：Forge、Pool、炮台节奏和背景球。

## 4. Animation / Audio Vocabulary

第一版可以使用占位音频和简单动效，但每类状态必须有不同反馈族。音频不能替代视觉可读。

| State | Animation | Audio | 验收读法 |
|---|---|---|---|
| Natural Hit | 槽口压下 / 咬合 80-140ms，槽名短亮。 | 轻扣。 | 这是自然物理落点。 |
| Forced Redirect | 短导轨伸出并接住指定球，来源标记贴在槽边。 | 导轨咔哒 + 轻微上扬。 | 这颗被规则掰进目标槽。 |
| Distribution Shift | 钉子、活动块或槽宽在 300-500ms 内形变，来源标记常驻。 | 低频机械位移。 | 之后分布被改变。 |
| Blocked Bounce | 球撞到 Exposure 挡板后明确反弹，轨迹尾保留短帧。 | 硬挡。 | 球没消失，高级槽还没开。 |
| Valid Unit Hit | slot 吃入球，progress 跳数，若成队列则连线到 Queue head。 | 短促确认音。 | 这个球推进了哪个单位槽。 |
| Split Return | 球进入回流通道，Pool 增加时显示方向动线。 | 回流管声。 | 这是输入流回流，不是直接出兵。 |
| Recycle Return | miss 后沿回收通道返回 Pool 前 / 后位置。 | 更短的回流管声。 | miss 被回收，输入流保住。 |
| Waste | 球进入废弃口，短灰化，快速退出注意层。 | 闷落。 | 这颗没有有效结算。 |
| Logic Settlement | 物理球落定后，用槽位或 Queue 小标签显示数值 / 延迟变化。 | 轻电子短音。 | 这是结算效果，不是第二颗物理球。 |
| Counter Disruption | 先预警倒计时，再显示生效结果，最后留 1-2s 残留痕迹。 | 预警三连 + 生效残响。 | 敌人打的是机器组件。 |
| Deploy Birth | 出生口短闪，单位从当前路线入口出现。 | 低音确认。 | 队列条目部署到当前选路。 |
| Lane Danger Up | danger shape 出现或升级，脉冲频率提高。 | 短警示，不循环轰炸。 | 这路风险升高，但不是自动推荐。 |

Timing baseline：

- 点击路线到选中高亮更新：同帧或下一帧。
- 队列部署前 0.3-0.5s，Queue head 和当前路线要同时可读。
- 反制预警必须保留倒计时或持续时间，不只闪一下。
- Prime / Echo / Surge 的战场结果标签只短暂出现，不常驻遮挡战场。

## 5. Open Items

以下内容不在本文锁定：

1. 最终字体、图标、插画、材质和音频资产。
2. 精确色值是否满足最终无障碍对比。
3. 球物理参数、钉子布局、活动块形态和同屏球数。
4. 每个 Guardian、中立修正和反制的最终物理表现。
5. 最终战斗画面布局比例和分辨率适配。

实现 handoff 可以引用本文作为 MVP v0 视觉和反馈输入；实现后必须通过 playtest 和视觉 QA 判断是否提升、修改或回退。
