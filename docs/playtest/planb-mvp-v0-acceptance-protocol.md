# PlanB MVP v0 M0-M4 验收协议

**状态：** 当前 `godot/` 活动实现的人工验收协议。它用于验证玩家理解，不替代自动验证，也不扩展 M0-M4 范围。

**当前自动验证入口：**

```bash
bash tools/verify_godot.sh
```

旧 Phase 2 playtest 文件仍可作历史参考，但不作为当前 M0-M4 gate；凡是提到 `mvp/tools/verify_all.sh` 的旧路径，都不适用于当前 `godot/` 活动工程。

## 进入条件

- 自动验证 `bash tools/verify_godot.sh` 必须通过。
- 测试者不能是本次实现者。
- 测试者不应提前阅读 `docs/`、verifier 输出或实现计划。
- 使用默认启动场景，从 Main Menu 开始，不打开归档 prototype，不使用旧 `mvp/`。
- 观察者可以记录问题，但不要在测试过程中解释设计意图。

## 跑法

至少跑一条完整短局：

```text
Main Menu -> Guardian Contract -> Battle 1 -> Reward 1 -> Battle 2 -> Shop / Rest -> Battle 3 -> Rest -> Battle 4 -> Reward 2 -> Battle 5 -> Endpoint Prep -> Endpoint -> Final Result
```

必须覆盖：

- 至少一次胜利路径。
- 至少一次失败路径。
- 至少一次 Battle 3 反制可见预警或可见未触发结果。
- 至少一次 Endpoint 结算到 Final Result。

## 必留截图

- Battle 1 前 30 秒。
- 第一次反制出现或侦测后的战斗画面。
- 第二次奖励页。
- Endpoint 扫击预警或 Endpoint 战斗进行中。
- Final Result。

## 测试者问题

测试者必须用自己的话回答：

1. 你这一局主要在构筑哪条机器轴：`Launch`、`Tuning` 还是 `Unit`？
2. 第一次奖励改了哪个机器组件？你预期它在战场上带来什么变化？
3. 第一次商店买了什么？它是在深化、补洞还是转向？
4. 第一次反制攻击了哪个组件或节奏？你看到了什么预警或后果？
5. `Deploy Lane` 改变了什么？它有没有直接控制已经部署出去的单位？
6. Endpoint 为什么赢或输？主要原因来自机器轴兑现、路线选择、守护者压力，还是反制？
7. 守护者 HP 压力在这一局是否重要？你从哪里看出来？

## 观察记录格式

每个问题记录一个状态：

- `clear`：测试者能指向屏幕证据，并用自己的话说清楚。
- `confused`：测试者说出部分关键词，但原因或屏幕证据不清楚。
- `absent`：测试者答不上来，或答案与屏幕反馈相反。

记录时保留原话摘要：

```text
问题 1：clear / confused / absent
玩家原话：
观察者备注：
对应截图：
```

## 通过门槛

可以说“玩家理解路径初步成立”的最低条件：

- `Launch / Tuning / Unit` 主轴问题为 `clear`。
- 第一次奖励组件问题为 `clear`。
- 第一次商店定位问题不低于 `confused`。
- 第一次反制目标问题不低于 `confused`。
- `Deploy Lane` 问题为 `clear`，且没有误解为直接操作已部署单位。
- Endpoint 胜负原因问题不低于 `confused`。

如果任一核心问题为 `absent`，不能把玩家理解 claim 记为通过，只能记录为实现可运行、自动 gate 通过、但可读性需要下一轮修正。

## 非验收范围

- 不评估最终美术完成度。
- 不锁最终数值平衡。
- 不新增种族、敌人、奖励、事件、遗物、商店池或 M0-M4 之外系统。
- 不用测试者反馈即时改 canon；玩法 canon 变更仍必须回到正式设计流程。
