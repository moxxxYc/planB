# 02 — Scene / Node 架构规则

## 1. Scene 是 Godot 的主要模块边界

优先把可复用游戏对象做成 scene。本项目典型可复用 scene：

- 球机仓：`LaunchChamber` / `TuningChamber` / `UnitChamber`（按 `docs/machine-warehouses.md`）
- 球机物理件：`PegBoard`、`Turret`（摆动炮台）、`Ball`（按候选草案 `docs/ball-machine-physical.md`，物理参数未锁定）
- 战场对象：`Lane`、`Unit`、`Gate`（门）、`Base`（基地）、`Guardian`
- Deploy Lane：`DeployLaneSelector`、`LaneRouteHint`
- 经济：`RewardCard`、`ShopItem`、`RestResultPanel`
- 敌人：`Enemy`、`WaveSpawner`、`CounterWarning`（反制预警）
- 通用：`HUD`、`DamageNumber`、`Endpoint`（结算页）

Scene 应该尽量自包含，可在测试场景中独立运行。

---

## 2. 什么时候拆 scene

满足任一条件就可以考虑拆 scene：

- 该对象会被复用多次（单位、敌人、奖励卡、钉板块）。
- 该对象有独立生命周期。
- 该对象需要单独测试（如单独验证球机物理或单条路接战）。
- 该对象有独立碰撞、动画、状态。
- 父场景开始变得难以维护。

不要过早拆分：只有 1 个节点 + 1 段简单逻辑且短期不复用、拆分后需要大量外部依赖才能运行、或拆分只是为了“看起来架构更好”。

---

## 3. 子场景依赖规则

子场景不应该假设父场景长什么样。

错误倾向：

```gdscript
var base = get_node("../../Battlefield/Base")
var hud = get_node("/root/Run/UI/HUD")
```

推荐方式：

1. 父场景注入依赖：

```gdscript
# 父场景把目标路/基地注入给单位
unit.target_lane = lane
```

2. 子场景发 Signal，父场景响应：

```gdscript
# 子场景（Unit）
signal died(unit: Node)

func _die() -> void:
	died.emit(self)

# 父场景（Lane 或 Battlefield）
unit.died.connect(_on_unit_died)
```

3. 使用 Group 查询弱依赖对象：

```gdscript
var enemies := get_tree().get_nodes_in_group("enemies")
```

4. 极少数全局服务走 Autoload，例如 `SceneLoader`、`Events`、`RunSession`（见 `04-signals-autoloads-state.md`）。

---

## 4. 父子通信规则

| 方向 | 推荐方式 |
|---|---|
| Parent → Child | 直接调用方法 / 设置属性 |
| Child → Parent | Signal |
| Sibling → Sibling | Parent 中介 |
| Object → UI | Signal / Events Autoload |
| Gameplay → Global service | 明确 Autoload API |
| Global service → Scene | Signal，不要硬持有大量 scene 引用 |

---

## 5. Node 树规则

Node 树应该表达运行时结构，不要变成“文件夹”。

球机仓推荐（结构示意，物理件以 `docs/ball-machine-physical.md` 候选草案为参考，未锁定）：

```text
LaunchChamber (Node2D)
  PegBoard (Node2D)
    Peg (StaticBody2D / 多个)
  Turret (Node2D)          # 摆动炮台
    Muzzle (Marker2D)
  BallSpawner (Node2D)
  ChamberBounds (StaticBody2D)
```

不推荐（把职责拆成一堆 Manager 节点）：

```text
LaunchChamber
  Managers
    PegManager
    BallManager
    TurretManager
```

Godot 的 Node 有运行时成本。只有需要进入 SceneTree、需要 Transform、Signal、生命周期或编辑器可视化时才做 Node。

---

## 6. 推荐一局主场景

按本项目“球机 + 三路自动战斗 + Deploy Lane + 经济 + Endpoint”组织（结构示意，节点名按实际实现确认）：

```text
Run (Node)
  BallMachine (Node2D)        # 左侧：三仓物理球机
    LaunchChamber
    TuningChamber
    UnitChamber
  Battlefield (Node2D)        # 右侧：三条路自动战斗
    Lanes (Node2D)
      Lane (x3)
        Units
        Enemies
        Gate
    PlayerBase
    EnemyBase
    Guardian
  UI (CanvasLayer)
    HUD
    DeployLaneSelector
    RewardPanel / ShopPanel
    EndpointPanel
  Managers (Node)             # 只服务当前局，不进 Autoload
    WaveManager
    DeployManager
    EconomyManager
```

`docs/ball-machine-physical.md` 候选草案提到左右分屏（左球机、右战场）；上面的分组与之一致，但具体布局、比例和物理参数未锁定，实现时以确认后的设计为准。

说明：

- 球机和战场是两个并列子系统，物理球机产出 → 单位队列 → Deploy Lane 选路 → 三路自动接战。
- UI 放 `CanvasLayer`，不混在世界节点下。
- Manager 节点只管理当前局，不等于全局 Autoload。
- 长期/跨场景状态才进入 Autoload（如 `RunSession`）。

---

## 7. 坐标与表现规则

- 物理球机用真实 2D 物理（`RigidBody2D` 球、`StaticBody2D` 钉板/边界），物理参数集中可调，不要散落写死。
- 战场单位沿固定路推进，逻辑位置以路线进度/脚底点为准，不做复杂 RTS 寻路。
- 接战判定优先用距离、路线相遇、`Area2D`，不要用复杂像素检测。
- 视觉体积和碰撞/判定体积分离。
- 灰阶可读性：按候选草案 `docs/ball-machine-physical.md`，表现要在灰阶下仍可读；实现表现层时保留这条约束，不靠纯颜色区分关键信息。

---

## 8. 组合优先于深继承

推荐用组合表达职责：

```gdscript
@export var stats: UnitStats          # Resource 配置
@onready var hurtbox: Area2D = $Hurtbox
```

谨慎使用深继承：

```text
UnitBase
  MeleeUnit
    FastMeleeUnit
      BuffedFastMeleeUnit   # 不推荐，父类假设容易被破坏
```

深继承很容易让后期改动破坏父类假设。MVP 阶段单位/敌人差异优先用 Resource 数据 + 少量组合脚本表达。

---

## 9. 可测试场景

每个重要可复用 scene 建议有测试场景：

```text
scenes/test/ball_machine_test.tscn   # 单独验证球机物理与产出
scenes/test/lane_combat_test.tscn    # 单独验证一条路自动接战
scenes/test/deploy_lane_test.tscn    # 单独验证 Deploy Lane 选路
scenes/test/enemy_wave_test.tscn     # 单独验证波次与反制预警
```

测试场景用于快速手动验证，不一定是自动化测试。
