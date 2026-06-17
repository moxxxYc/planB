# 05 — 玩法实现模式：球机物理 / 三路自动战斗 / Deploy Lane

> 本章是工程实现模式，不是设计 canon。玩法规则以仓库根 `docs/machine-warehouses.md`、`docs/battlefield-rules.md`、`docs/enemy-rules.md`、`docs/deploy-lane-ui.md`、`docs/guardian-system.md` 为准；球机物理表现层参考候选草案 `docs/ball-machine-physical.md`（物理参数未锁定）。本章只给 Godot 4.6 落地方式，不新增规则、不锁定数值。

## 0. 核心数据流（按设计 canon）

```text
球机（左）                                          战场（右）
Forge → Pool → Launcher → Launch Route Board
   → Tuning(Gate/Prime/Echo/Surge) → Unit slots
   → Unit slot 暴露检查 → Unit progress → Queue
                                   │
                                   ▼
                            Deploy Lane 选路（Left/Mid/Right）
                                   │
                                   ▼
                    三路自动接战（单位自动行军/索敌/接战）
                                   │
                                   ▼
                            Endpoint 结算 / 奖励·商店 / 敌人反制
```

实现时不要把这条链压扁成“点按钮直接出兵”。物理产出、Tuning 转换、队列节奏、Deploy 选路是分开的层。

---

## 1. 默认技术选型

| 对象 | Godot 类型 | 说明 |
|---|---|---|
| 球（Ball） | `RigidBody2D` | 真实 2D 物理，按 `ball-machine-physical.md` 模型 A（参数未锁定） |
| 钉板 Peg / 仓壁 | `StaticBody2D` | 固定碰撞体 |
| 摆动炮台 Turret | `Node2D` + 物理化运动 | 表现层参考候选草案，未锁定 |
| 球落点/触发区 | `Area2D` | 检测球进入 Tuning 槽 / Unit 槽 |
| 战场单位 Unit | `CharacterBody2D` | 沿路推进，不接受玩家直接操控 |
| 敌人 Enemy | `CharacterBody2D` | 同上，反向推进 |
| 单位攻击/受击判定 | `Area2D`（Hitbox/Hurtbox）或距离判定 | 见第 5 节 |
| 门 Gate / 基地 Base | `Area2D` + `Node2D` | 路线端点接触区 |
| Deploy Lane 点击区 | `Area2D` 或 `Control` | 见第 7 节 |
| UI（球机面板/Deploy/结算/HUD） | `Control` + `CanvasLayer` | |
| 数据配置 | `Resource` | 机器组件、Tuning 槽、单位、敌人、奖励 |

具体用 `RigidBody2D` 还是简化运动表现，取决于 `ball-machine-physical.md` 最终锁定的物理模型。MVP 默认按候选草案“模型 A 真物理”实现，但参数标注为占位。

---

## 2. 球机物理层

按 `docs/machine-warehouses.md` 的数据流 + `docs/ball-machine-physical.md` 的表现候选：

- 球用 `RigidBody2D`，在 `_integrate_forces()` 或物理属性里集中调参，**不要**把弹性、摩擦、重力散落写死在多个脚本。
- 钉板/仓壁用 `StaticBody2D`；三仓三块串联钉板结构（候选草案）作为 scene 组合，不写死成一个巨型场景。
- 球进入 Tuning 槽（`Gate / Prime / Echo / Surge`）和 Unit 槽用 `Area2D` 进入事件检测，发 Signal 给上层结算。
- Unit slot 暴露检查（`Unit.Slot.Exposure Gate`）是规则层逻辑，按 canon 的“从左到右逐步暴露”实现，暴露节奏作为可调 baseline，不按种族藏默认表。
- 物理结果（进哪个槽、是否有效结算、回流/污染）通过 Signal 上抛，不让物理脚本直接改战场或经济状态。

物理数值未锁定：所有弹力、发射力、回流概率等用 `@export` + “占位/调试起手值”注释，等 playtest 后再定。

---

## 3. 队列与部署节奏

按 canon：队列部署是独立节奏层，不是瞬间出兵。

- Unit 槽填满 → 进入 `Queue`。
- `Queue` 按部署节拍（`Unit.Queue.deploy_interval` 一类）逐条部署。
- 部署时读取当前 `Deploy Lane`；批量部署开始时锁定路线，已部署单位不受后续切路影响。
- 部署节奏放在当前局的 `DeployManager`（普通 Node），不进 Autoload。

不要把“出兵”实现成点一下立刻刷一堆单位，绕过队列节奏。

---

## 4. 三路战场拓扑

按 `docs/battlefield-rules.md`：

- 三条固定路径 `Left / Mid / Right`，规则上按一维有序路径处理。
- 第一版路径坐标 `0-100`：玩家基地接触区 `0-8`、玩家 Lane Gate `8`、敌方 Lane Gate `92`、敌方基地接触区 `92-100`。玩家单位向 `100` 走，敌人向 `0` 走。
- 实现可用路线样条、路径点链或等价有序坐标。**不需要自由地图寻路**，不要引入 NavigationServer 复杂寻路。
- 每条 `Lane` 做成 scene，管理自己的单位、敌人、门。

单位推进示例（沿路一维进度，不做 RTS 寻路）：

```gdscript
# 沿当前路线推进；path_pos 是 0-100 标准化坐标
func _march(delta: float) -> void:
	if _current_target != null:
		_state = State.FIGHTING
		return
	path_pos += move_speed * delta * _dir   # 玩家 +1，敌人 -1
	global_position = lane.point_at(path_pos)
```

---

## 5. 单位接战结算

按 `docs/battlefield-rules.md` 单位字段（`hp / attack_damage / attack_interval / attack_range / move_speed / body_size / target_rule / skill_rule`）：

- 索敌基础规则：同路最近敌人（`target_rule` 默认）。优先用按路缓存的有序列表查最近，不要每帧全场扫 group。
- 攻击判定优先用距离 / `attack_range`，必要时用 `Area2D`。攻击者调用目标公开方法，不直接改目标内部：

```gdscript
func _fight(delta: float) -> void:
	_cooldown_left -= delta
	if _current_target == null or not is_instance_valid(_current_target):
		_state = State.MARCHING
		return
	if _cooldown_left <= 0.0:
		_current_target.take_damage(stats.attack_damage, self)
		_cooldown_left = stats.attack_interval
```

- 单位属性优先放 `UnitStats` Resource；运行时血量放运行时字段，不 `@export`。
- 数值都是占位/职责带起手值，不是最终平衡（与设计文档口径一致）。

---

## 6. 索敌与接战的性能边界

三路同屏单位 + 敌人可能较多，避免每帧全量扫描：

- 每条 `Lane` 维护本路单位/敌人的有序列表（按 path_pos），索敌只在本路相邻范围找。
- 用 `Area2D` 进入/离开事件维护接战候选，而不是每帧两两距离比对。
- 单位生成/死亡批量发生时，考虑对象池（仅在 profiler 证明有压力时）。

详见 `06-platform-export-performance.md`。

---

## 7. Deploy Lane 选路

按 `docs/deploy-lane-ui.md`：

- 用战场路线本体作为可点击区域（`Area2D` 或覆盖 `Control`），点哪条路哪条成为当前出兵路线。
- 战斗开始默认选中 `Mid`；点击立即生效；无切路冷却、无待切路线、无独立三按钮面板、不做自动选路/推荐。
- 选中高亮（玩家色、稳定、持续）和危险提示（敌方色、脉冲、短时）必须分层，不能混淆。
- 当前选中路线存在当前局的 `DeployManager`，部署时读取。

示例：

```gdscript
signal lane_selected(lane_index: int)

func _on_lane_clicked(lane_index: int) -> void:
	_current_lane = lane_index
	lane_selected.emit(lane_index)
	_update_highlight()   # 只改选中高亮，不动危险提示层
```

不要把 Deploy Lane 做成 RTS 微操或救命按钮。

---

## 8. 敌人波次与反制

按 `docs/enemy-rules.md`：

- 波次、反制预警由当前局 `WaveManager` 驱动，读波次 Resource，不写死在敌人脚本里。
- 反制（counter）生效必须可读、可预警（`counter_warned` Signal → UI 预警），按 canon 的反制规则实现。
- 反制改机器时走 `Machine Contract` 声明方式（来源/所属仓/目标组件/操作/范围/玩家读法/失败风险），不要默认隐式改机器。

具体波次表、反制内容以 `docs/enemy-rules.md` 为准；未在文档锁定的不要自己编。

---

## 9. 奖励 / 商店 / Gold

按候选草案 `docs/neutral-modifiers.md`（已确认结构，最终平衡未确认）：

- `Gold` 主要来自战后结算（设计 canon）。Gold faucet、价格带、休整结果页口径按该草案，但标注最终平衡未确认。
- 奖励卡、商店条目做成 Resource；经济逻辑放当前局 `EconomyManager`。
- 不要把经济数值当成已锁定平衡写死。

---

## 10. Guardian

按 `docs/guardian-system.md`：Guardian 是通用系统规则，不放具体种族 Guardian。实现 Guardian 通用行为时以该文档为准，种族特有 Guardian 不在 MVP 基础层自行发明。

---

## 11. UI 更新

UI 不应该每帧主动查询玩法状态。

```gdscript
# 玩法侧
gold_changed.emit(current_gold)

# HUD 侧
func bind() -> void:
	Events.gold_changed.connect(_on_gold_changed)
```

球机面板、Deploy Lane、波次预警、Endpoint 结算都用 Signal / `Events` 驱动刷新。

---

## 12. ECS / 复杂框架判断

默认不使用 ECS、不使用行为树、不使用复杂 RTS 寻路（设计 canon 已明确不把这些当核心需求）。

Godot 的主模型是 Scene + Node + Resource。只有出现“同屏上千对象 + profiler 证明 Node 成为瓶颈”时才评估数据导向结构，且需先确认。否则保持 Godot 原生方式。
