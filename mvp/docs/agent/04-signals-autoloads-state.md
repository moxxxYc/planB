# 04 — Signal、Autoload、状态管理

## 1. Signal 使用边界

Signal 适合：

- Child → Parent 通知（单位死亡、到门、球落入仓）。
- Gameplay → UI 通知（金币变化、波次清空、Endpoint 结果）。
- 一对多事件。
- 低耦合状态变化。

Signal 不适合：

- 高频每帧数据同步（球的实时位置、单位实时坐标）。
- 简单 Parent → Child 命令。
- 强顺序、强返回值的业务调用。
- 需要立即知道执行结果的流程。

---

## 2. Signal 命名

使用过去式或状态变化式：

```gdscript
signal unit_spawned(unit: Unit)
signal lane_selected(lane_index: int)
signal gold_changed(current: int)
signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal counter_warned(counter_id: StringName)
signal endpoint_reached(result: int)
```

不要：

```gdscript
signal spawn_unit
signal select_lane
signal update_gold
```

---

## 3. 连接方式

推荐在代码中连接关键 gameplay Signal，方便搜索和重构：

```gdscript
func _ready() -> void:
	unit.died.connect(_on_unit_died)
```

编辑器连接可用于 UI 按钮、简单场景内交互；复杂 gameplay 不要过度依赖不可见的编辑器连接。

---

## 4. Autoload 使用边界

Autoload 适合：

- `SceneLoader` / 场景切换
- `Events` 跨系统事件总线
- `RunSession` 一局会话状态（跨场景需要的当前局数据）
- `AudioService`、`SettingsService`（如需要）

Autoload 不适合：

- 当前局的 `WaveManager` / `DeployManager` / `EconomyManager`
- 球机物理逻辑、单位 AI、敌人 AI
- 单个 UI 页面逻辑
- 所有数据的“大仓库”

判断标准：

```text
如果它必须跨场景长期存在，才考虑 Autoload。
如果它只服务当前局/当前关卡，把它放在当前 scene 的 Managers 下。
```

---

## 5. 推荐 Autoload 列表

MVP 阶段尽量少，建议起步只用：

```text
Events.gd        # 跨系统事件
RunSession.gd    # 一局会话状态
SceneLoader.gd   # 场景切换
```

需要时再加 `AudioService.gd`、`SettingsService.gd`。不要一开始就创建十几个全局单例。新增 Autoload 属于改 `project.godot`，按 `01-project-structure.md` 第 6 节要求确认。

---

## 6. Events Autoload 规则

`Events.gd` 只放跨系统事件，不放业务实现。

示例（事件签名按实际系统确认）：

```gdscript
extends Node

signal gold_changed(current: int)
signal unit_spawned(unit_id: StringName, lane_index: int)
signal wave_cleared(wave_index: int)
signal counter_warned(counter_id: StringName)
signal endpoint_reached(result: int)
```

禁止在 `Events.gd` 里写：球机物理结算、接战伤害计算、奖励/商店计算、波次生成、存档逻辑。

---

## 7. RunSession 规则

`RunSession.gd` 保存当前局状态，例如：

```gdscript
extends Node

var gold: int = 0
var wave_index: int = 0
var machine_state: MachineState        # Launch/Tuning/Unit 当前构筑（Resource 或明确类）
var elapsed_time: float = 0.0
```

它不应该知道具体节点路径。不要写：

```gdscript
var player_base: Node2D
var current_unit_nodes: Array[Unit]
```

运行时节点引用由当前场景管理。一局结束（Endpoint）后按需重置或归档 `RunSession`。

---

## 8. 当前局 Manager

当前局内的管理器是普通 Node，挂在当前主场景下：

```text
Run
  Managers
    WaveManager       # 敌人波次、反制预警节奏
    DeployManager     # Deploy Lane 选路状态
    EconomyManager    # 奖励/商店/Gold faucet
```

它们随主场景创建和销毁，不进入 Autoload。

---

## 9. 状态机规则

简单对象用 enum 状态：

```gdscript
enum State { MARCHING, FIGHTING, DEAD }
var _state: State = State.MARCHING
```

球机仓、单位、敌人、一局流程都可以先用 enum 状态机。复杂角色再拆子状态或状态节点。不要一开始就引入复杂 HFSM / 行为树框架（设计 canon 也明确不把复杂 RTS / 行为树当核心需求）。

---

## 10. Group 规则

Group 适合松耦合分类：

```text
units
enemies
lanes
damageable
deployable
```

用法：

```gdscript
for node in get_tree().get_nodes_in_group("damageable"):
	if node.has_method("take_damage"):
		node.take_damage(10)
```

不要每帧全量扫描大型 group。三路接战这种性能敏感场景应维护按路的局部缓存，或用 `Area2D` 进出事件维护接战候选，详见 `06-platform-export-performance.md`。
