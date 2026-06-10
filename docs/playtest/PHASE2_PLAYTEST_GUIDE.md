# Phase 2 Playtest Guide

**目的：** 验证玩家是否能读懂机器轴承诺如何改变队列、`Deploy Lane` 和战场结果。本文不是公开 demo 指南，也不评估完整 MVP 内容量。

## 测试范围

- 使用现有 playable session，不使用单独 tutorial、debug scene 或归档 prototype。
- 只观察第一层可读性：机器 -> 队列 -> `Deploy Lane` -> 战场结果 -> 结果页 recap。
- 不评估长期平衡、内容丰富度、商业化、美术完成度或公开试玩质量。

## 开始前

1. 从仓库根目录运行：

```bash
bash mvp/tools/verify_all.sh
```

2. 如果验证失败，先记录失败输出，不进入外部 playtest。
3. 测试者不应先阅读 `docs/`，只按 playable session 的玩家侧反馈理解游戏。

## 观察脚本

1. 让玩家选择 Guardian 并开始 Battle 1。
2. 观察玩家能否说出当前机器输出了什么队列条目。
3. 观察玩家能否指出当前 `Deploy Lane` 和队列头将去的路线。
4. Battle 1 结束后，让玩家解释机器、队列、路线和战场结果的关系。
5. 让玩家选择 First Reward，并追问它属于 `Launch / Tuning / Unit` 哪条轴。
6. 进入下一场战斗，观察玩家是否知道 First Reward 后应该看什么战场信号。
7. 到结果页后，让玩家解释 6 个 recap 字段：Main Axis、Most Impactful Reward、Key Battlefield Turn、Weakest Link、Enemy Counter Impact、Next Run Suggestion。

## 通过信号

- 玩家能用自己的话说出：我选择了哪条轴，它改了哪个机器组件，改变了什么队列效果，影响了哪条路线或战场结果。
- 玩家不会把 `Deploy Lane` 误解成直接指挥已部署单位。
- 玩家能从结果页说出下一局想观察或修正什么。

## 失败信号

- 玩家只说“我造了更多兵”。
- 玩家只说“我点对了路线”。
- 玩家不知道 First Reward 属于哪条轴。
- 玩家不知道队列为什么进某条路。
- 玩家看完结果页仍不知道为什么赢或输。
