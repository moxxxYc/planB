# 03 — GDScript 编码规范（Godot 4.6）

## 1. 基本风格

遵守 Godot 官方 GDScript 风格：

- UTF-8、LF 换行、Tab 缩进、文件末尾保留一个换行。
- 单行尽量不超过 100 字符；每行只写一个语句。
- 布尔运算用 `and` / `or` / `not`，不用 `&&` / `||` / `!`。
- 文件名 `snake_case`；`class_name` `PascalCase`；函数、变量 `snake_case`；常量 `CONSTANT_CASE`。
- Signal 用 `snake_case`，语义优先过去式（`unit_spawned`、`lane_selected`）。
- 使用 Godot 4.6 API，不要写 Godot 3.x 语法（如 `export var`、`yield`、`onready var` 旧写法）。

---

## 2. 推荐代码顺序

```gdscript
class_name Unit
extends CharacterBody2D

## 战场单位：沿指定路推进并自动接战。不接受玩家直接操控。

signal died(unit: Unit)
signal reached_gate(unit: Unit)

enum State {
	MARCHING,   # 沿路推进
	FIGHTING,   # 接战中
	DEAD,
}

const ARRIVE_THRESHOLD := 4.0

@export var stats: UnitStats           # 单位属性，Resource 配置
@export var move_speed: float = 120.0

var _state: State = State.MARCHING
var _current_target: Node2D = null

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D


func _ready() -> void:
	add_to_group("units")


func _physics_process(delta: float) -> void:
	match _state:
		State.MARCHING:
			_march(delta)
		State.FIGHTING:
			_fight(delta)
		State.DEAD:
			pass


func take_damage(amount: int, source: Node = null) -> void:
	# 公开受击入口，攻击方不要直接改本对象内部血量
	if _state == State.DEAD or amount <= 0:
		return
	stats.current_hp = max(0, stats.current_hp - amount)
	if stats.current_hp == 0:
		_die()


func _march(_delta: float) -> void:
	pass


func _fight(_delta: float) -> void:
	pass


func _die() -> void:
	_state = State.DEAD
	died.emit(self)
```

---

## 3. 类型规则

默认使用静态类型。

```gdscript
@export var move_speed: float = 120.0
var current_hp: int = 100
var march_dir := Vector2.RIGHT
```

`:=` 只在类型明显时使用：

```gdscript
var enemies := get_tree().get_nodes_in_group("enemies")
```

`get_node()` 建议显式类型：

```gdscript
@onready var hurtbox: Area2D = $Hurtbox
# 或
@onready var hurtbox := $Hurtbox as Area2D
```

避免类型不明确的写法：

```gdscript
@onready var hurtbox := $Hurtbox   # 不推荐：后续难判断 API
```

---

## 4. Export 变量规则

对策划、数值调试有意义的参数使用 `@export`：

```gdscript
@export var launch_power: float = 600.0
@export var unit_spawn_cost: int = 1
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
```

不要 export 运行时内部状态：

```gdscript
var _current_target: Node2D
var _cooldown_left: float
```

需要限制范围时使用提示：

```gdscript
@export_range(0.0, 2000.0, 1.0) var launch_power: float = 600.0
```

物理/平衡数值若设计未锁定，注释标注“占位/调试起手值，非最终平衡”。

---

## 5. Signal 规则

Signal 名称表达“已经发生的事”：

```gdscript
signal unit_spawned(unit: Unit)
signal lane_selected(lane_index: int)
signal gold_changed(current: int)
signal wave_cleared(wave_index: int)
signal endpoint_reached(result: int)
```

不要用命令式 Signal：

```gdscript
signal spawn_unit
signal update_gold_label
signal start_wave
```

Signal 不应替代所有方法调用。Parent → Child 用方法更直接，Child → Parent 用 Signal 更解耦。

---

## 6. 注释规则

注释解释“为什么”，不要重复“做了什么”。代码注释用中文。

好：

```gdscript
# 延迟释放：本方法可能从 Signal 回调里被调用，立即 free 会引发悬空引用
_free_current_scene.call_deferred()
```

差：

```gdscript
# 把血量减去伤害
current_hp -= amount
```

复杂玩法规则必须写注释，尤其是：球机物理产出与单位生成的对应关系、接战命中/冷却规则、Deploy Lane 选路与危险提示判定、敌人反制生效条件、奖励/商店价格带、状态切换、平台特殊处理。

---

## 7. 错误处理与断言

公开方法要对非法输入做防御：

```gdscript
func apply_damage(amount: int) -> void:
	if amount <= 0:
		return
```

只在开发期不变量使用 `assert()`：

```gdscript
assert(stats != null, "Unit 需要 UnitStats。")
```

不要用 `assert()` 处理玩家输入、外部数据或可恢复错误。

---

## 8. NodePath 与缓存

可以用 `@onready` 缓存直接子节点或稳定子节点：

```gdscript
@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
```

避免长路径：

```gdscript
@onready var hud = $"../../../../UI/HUD"   # 不推荐
```

跨场景引用用注入、Signal、Group 或 Autoload。

---

## 9. 数据结构规则

稳定结构优先使用 Resource 或明确类，不要滥用 Dictionary。

适合 Dictionary：一次性解析数据、小范围临时映射、外部 JSON 原样承载。

不适合 Dictionary：机器组件配置、Tuning 槽数值、单位/敌人属性、奖励/商店条目、长期维护的玩法状态。

推荐：

```gdscript
class_name UnitStats
extends Resource

@export var max_hp: int = 50
@export var move_speed: float = 120.0
@export var attack_damage: int = 8

var current_hp: int = max_hp   # 运行时状态可放这里，但不要 @export
```

---

## 10. 性能敏感代码

球机物理和三路接战会有较多同屏对象，每帧逻辑中禁止随意做：

- 大量 `get_node()` / `find_child()`。
- 大量字符串拼接。
- 大量 group 全量扫描（如每帧 `get_nodes_in_group("units")` 再两两比对）。
- 频繁 `load()` 资源。
- 每帧实例化/销毁大量对象（球、单位、伤害数字）。

需要时先缓存引用、预加载 PackedScene、降低检测频率（Timer / 累积时间）、用 `Area2D` 事件替代全量距离扫描、必要时上对象池。详见 `06-platform-export-performance.md`。
