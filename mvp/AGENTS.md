# AGENTS.md — planB MVP v0 工程规则

> 目标：约束 AI coding agent 和人类开发者在 `mvp/` 实现目录里做“小步、可验证、不过度设计”的 Godot 开发。
>
> 作用域：本文件只管 `mvp/` 下的**工程实现**。它**不是设计权威**。游戏设计 canon 以仓库根 `AGENTS.md` 和 `docs/` 为准。
>
> 项目假设：Godot 4.6、GDScript、2D、桌面 + Web 兼顾（以 Compatibility 渲染器为基线）。Godot 工程根就是 `mvp/`（即 `res://` = `mvp/`）。

---

## 0. 必须先读

任何改动前，按任务类型读取最小必要上下文：

1. 总是先读：
   - 仓库根 `AGENTS.md`（设计 canon、文档权威顺序、设计边界）
   - 本文件 `mvp/AGENTS.md`
   - `mvp/docs/agent/README.md`
   - 当前任务涉及的已有 scene / script / resource

2. 玩法相关改动还要读对应设计文档（仓库根 `docs/`）：
   - `docs/gdd.md`、`docs/machine-warehouses.md`、`docs/battlefield-rules.md`、`docs/enemy-rules.md`、`docs/deploy-lane-ui.md`、`docs/guardian-system.md`、`docs/mvp-scope.md`、`docs/mvp-learning-checkpoints.md`
   - 候选草案（仅作候选，不是锁定规则）：`docs/neutral-modifiers.md`、`docs/ball-machine-physical.md`
   - 以及 `mvp/docs/agent/05-gameplay-patterns.md`

3. Godot 结构、场景、节点相关改动还要读：
   - `mvp/docs/agent/01-project-structure.md`
   - `mvp/docs/agent/02-scene-architecture.md`

4. GDScript 代码改动还要读：
   - `mvp/docs/agent/03-gdscript-standards.md`

5. Signal、Autoload、局内状态、跨场景通信相关改动还要读：
   - `mvp/docs/agent/04-signals-autoloads-state.md`

6. 平台、导出、性能、资源体积相关改动还要读：
   - `mvp/docs/agent/06-platform-export-performance.md`

7. 资产、Sprite、动画、AI 生成素材相关改动还要读：
   - `mvp/docs/agent/07-assets-pipeline.md`

8. 测试、验证、CI、导出相关改动还要读：
   - `mvp/docs/agent/08-testing-validation.md`

9. AI 执行流程相关改动还要读：
   - `mvp/docs/agent/09-ai-coding-workflow.md`

---

## 1. Source of Truth 优先级

当规则冲突时，按以下顺序判断：

1. 用户本次明确指令
2. 仓库根 `AGENTS.md`（设计边界、协作要求和文档权威顺序）
3. 仓库根 `docs/` 设计文档，按根 `AGENTS.md` 的**文档权威顺序**裁决
4. 当前任务 spec / handoff / task card（例如 `docs/gstack-artifacts/` 下的实现交接；只限定实现范围和验收，不能覆盖设计 canon）
5. 本文件 `mvp/AGENTS.md`
6. `mvp/docs/agent/*.md`
7. 现有代码和 Godot 工程结构
8. Godot 官方文档和社区实践

工程“最佳实践”不得推翻当前 MVP 范围或设计 canon。最佳实践服务于项目，不反过来绑架项目。

候选草案（`docs/neutral-modifiers.md`、`docs/ball-machine-physical.md`）不参与设计权威顺序，未经用户确认不能当作锁定规则写进实现。若当前 handoff 明确把候选内容列为 MVP v0 实现假设，只能按 handoff 的边界实现，仍不等于最终 canon。

---

## 2. 总原则

- 先读现状，再改代码。
- 先做最小可运行闭环，再抽象。
- 优先使用 Godot 原生模型：Scene、Node、Resource、Signal、Group、Autoload。
- 不引入复杂框架，不默认引入 ECS，不默认引入服务定位器，不默认引入大型事件总线。
- Scene 应尽量可独立运行；子场景不应该强依赖父场景的固定 NodePath。
- 跨场景持久状态（一局会话状态）才允许进入 Autoload；普通玩法对象不要进入 Autoload。
- Gameplay 核心数值优先暴露为 `@export` 或 Resource 配置，便于策划/数值调参。
- 桌面 + Web 兼顾：以 Compatibility 渲染器为基线，优先保证两端都稳定可玩，再谈画质。
- 每次改动都必须给出验证方式；无法验证时必须说明原因（写 `Not run: 原因`）。

---

## 3. 本项目硬边界（来自根 `AGENTS.md`，工程实现必须遵守）

这些是设计 canon，不是工程可自行更改的部分。实现时不得违背：

- **球机必须是主系统**。`Launch / Tuning / Unit` 三仓机器是核心，其他系统都服务它，不能替代它。
- **不做** PVP、联网、账号、后端服务、匹配、Steam 集成。MVP 是 15-20 分钟单机短局。
- **战场不是自由 RTS 地图**，不把复杂 RTS 寻路当核心需求。
- **不允许直接操作已部署单位**。玩家的战场操作主要是 `Deploy Lane` 选路。
- 正式机器术语是 `Launch / Tuning / Unit`。
- 正式 Tuning 基础槽是 `Gate / Prime / Echo / Surge`。
- `Gold / 金币` 主要来自战后结算。
- `Overdrive` 不属于 MVP 基础按钮。

不要用旧 Web MVP 或旧 Battle Lab 的实现假设。`docs/archive/` 下的旧 prototype 不是实现来源，默认忽略。

---

## 4. 禁止事项

AI agent 不得擅自执行以下操作：

- 不得重写整个项目结构。
- 不得无任务依据批量重命名文件、节点、Signal、Input Action。
- 不得静默修改 `project.godot`、`export_presets.cfg`、autoload 列表、input map、物理层。
- 不得静默修改仓库根 `.gitignore`、根 `AGENTS.md` 或 `docs/` 设计文档。
- 不得把临时玩法规则写死到多个脚本里。
- 不得用字符串 NodePath 穿透多个层级访问远端节点。
- 不得让子场景依赖父场景内部结构。
- 不得把所有系统都塞进一个 `GameManager`。
- 不得新增插件、addon、第三方库，除非任务明确要求。
- 不得把调试脚本、临时资源、AI 生成草图混进正式资源目录而不标记。
- 不得伪造验证结果。没有运行就写“未运行”。
- 不得发明缺失玩法、内容表、数值或生产进度；未定事项标记为未定。

---

## 5. 默认开发流程

每个任务按此流程执行：

1. **Inspect** — 读相关文档、scene、script、resource，明确现有结构，不凭文件名猜实现。
2. **Plan** — 列出最小改动范围，说明会改哪些文件，标注需要人工决策的问题。
3. **Implement** — 小步修改，每次只解决一个清晰目标，优先复用现有模式。
4. **Validate** — 至少做语法/导入/场景级验证；玩法任务说明手动验证步骤；导出相关任务说明导出与运行验证方式。
5. **Report** — 说明改了什么、验证结果、未验证项和风险，固定格式见 `09-ai-coding-workflow.md`。

---

## 6. 工具与技能分工（vibe coding 整体原则）

本项目的开发由"设计 / 工程 / 验证 / 通用编码纪律"四层协作，各有归属，不能互相越界：

| 层 | 用什么 | 管什么 |
|---|---|---|
| 设计 canon | gstack-game 技能链 + 根 `AGENTS.md` + `docs/*` | 做什么 / 不做什么、玩法规则、平衡口径（**设计阶段**） |
| Godot 工程实现 | `mvp/AGENTS.md` + `mvp/docs/agent/*` | 代码怎么写、目录/场景/Signal/Resource 规范 |
| 验证 | **GoPeak MCP（`gopeak`）优先**，回退 `verify_godot.sh` | 跑场景、读诊断、抓报错、截图自检（见第 8 节） |
| 通用编码纪律 | superpowers（**仅实现阶段、Codex 内**） | 规划、调试、验证纪律、code review、git 流程 |

superpowers 使用边界（重要，详见 `09-ai-coding-workflow.md`）：

- **可用且与本规范同向**：`writing-plans` / `executing-plans`、`systematic-debugging`、`verification-before-completion`、`requesting/receiving-code-review`、`using-git-worktrees`、`finishing-a-development-branch`。
- **`test-driven-development` 仅对纯逻辑层**（伤害结算、队列间隔、价格带、路径坐标、波次/配置解析）。球机物理、手感、场景接线、视觉、时序**不强行 TDD**，靠 GoPeak 跑起来+截图验证。
- **不要用 `brainstorming` 碰游戏设计**。设计走 gstack-game 和设计 canon；设计阶段禁止用 superpowers 代替 gstack-game。
- **`subagent-driven-development` 长自主跑要带人工检查点**：球机是手感驱动，agent 判断不了手感，且不得擅自替用户做决定。
- **Cursor 内不加载 superpowers**（用户已在 Cursor 禁用）；它只在 Codex 实现阶段生效。

冲突优先级：**设计 canon > 本项目 Godot 工程规则（`mvp/AGENTS.md` + `docs/agent/*`） > superpowers 等通用工程教条**。通用教条与 Godot 现实或项目 canon 冲突时，以项目文档为准。

---

## 7. Godot 代码基线

- 使用 GDScript，Godot 4.6 API。
- 球机/单位/投射等物理对象按 `05-gameplay-patterns.md` 选型（默认 `RigidBody2D` / `CharacterBody2D` / `Area2D`，由该对象职责决定）。
- 使用 `Area2D` 处理触发、命中、交互区、Deploy Lane 点击热区一类的判定。
- 使用 `Control` / `CanvasLayer` 处理 UI（球机面板、Deploy Lane、结算页、HUD）。
- 使用 `Resource` 保存可复用配置：机器组件、Tuning 槽数值、单位属性、敌人波次、奖励/商店条目、关卡配置。
- 使用 `Signal` 做事件通知，尤其 child → parent、domain event → UI。
- 使用 `Group` 做松耦合查询，例如 `units`、`enemies`、`lanes`、`damageable`。
- Autoload 只做稳定全局服务：场景切换、一局会话状态、跨系统事件总线。

---

## 8. 验证要求

最低验证梯度：

```text
Level 0: 静态检查 — 代码读通，路径存在，类名/节点名一致。
Level 1: Godot 导入/启动检查 — headless 能打开 mvp/ 工程并退出。
Level 2: 场景烟测 — 关键 scene 可运行，不报缺失节点/资源。
Level 3: 玩法烟测 — 人工或自动跑通本任务核心路径。
Level 4: 导出烟测 — 导出相关任务尽量导出目标平台并运行。
```

验证工具优先级：

- **优先用 GoPeak MCP（`gopeak`）** 驱动验证——运行场景、读取脚本诊断、抓运行时报错、截图自检。它能直接覆盖 Level 1/2/3，是本项目首选验证手段。
- **回退**：没有 MCP 或只需快速 headless 烟测时，用 CLI 脚本（`GODOT_BIN` 指向 Godot 4.6）：

```bash
GODOT_BIN=/path/to/Godot ./mvp/tools/verify_godot.sh
```

GoPeak 的具体用法和前提见 `mvp/docs/agent/08-testing-validation.md` 第 10 节。

如果 `mvp/project.godot` 尚不存在，`verify_godot.sh` 会报告 `Not run` 并以非 0 状态退出；这不算 Level 1 通过。创建 Godot 工程后，Level 1 必须真实打开 `mvp/` 工程并退出。

---

## 9. 何时要求人工确认

遇到以下情况必须停止并要求确认，不能自行决定：

- 需要改变核心玩法设计，或触碰任何设计 canon。
- 需要扩大 MVP 或当前阶段范围。
- 需要新增全局架构层或新 Autoload。
- 需要引入插件或外部依赖。
- 需要删除或迁移大量资源。
- 需要修改导出平台、渲染器、输入方案、物理层、坐标系统。
- 需要把候选草案提升为锁定实现规则。
- 现有设计文档与代码冲突，且无法从上下文判断谁更新。

---

## 10. 分层文档索引

- `mvp/docs/agent/README.md` — 使用说明和维护规则
- `mvp/docs/agent/01-project-structure.md` — 项目结构、命名、版本控制
- `mvp/docs/agent/02-scene-architecture.md` — Scene/Node 架构
- `mvp/docs/agent/03-gdscript-standards.md` — GDScript 编码规范
- `mvp/docs/agent/04-signals-autoloads-state.md` — Signal、Autoload、状态管理
- `mvp/docs/agent/05-gameplay-patterns.md` — 球机物理 / 三路自动战斗 / Deploy Lane 实现模式
- `mvp/docs/agent/06-platform-export-performance.md` — 桌面 + Web 导出与性能
- `mvp/docs/agent/07-assets-pipeline.md` — 资产与 AI 美术流程
- `mvp/docs/agent/08-testing-validation.md` — 测试、验证、CI
- `mvp/docs/agent/09-ai-coding-workflow.md` — AI coding 执行协议
