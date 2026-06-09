# planB 开发工具清单

这是一份给人看的工具索引，列出 planB 开发过程中会用到、已经安装、可选或计划使用的 skills、MCP、插件、本地验证工具和项目文档。

它不是 AI 指令文件。实际执行规则仍以 `AGENTS.md`、`mvp/AGENTS.md`、当前 `docs/` 权威文档，以及用户最新明确指令为准。

## 工具使用原则

- 项目 `docs/` 和现有代码优先级最高。
- 任何真正开发前，必须先获得用户明确确认；确认前不得创建或修改代码、资产、脚本、Godot 场景、Web prototype 或其他实现文件。
- 游戏 canon 和长期设计决策走 gstack-game 链路。
- Godot 实现细节走 GodotPrompter 和本地 `mvp/docs/agent/` 工程文档。
- 需求澄清、规格、实现计划、测试策略、代码审查、系统调试和 git 流程，在有需要时使用 Superpowers。
- 快速原型可以存在，但必须标记为验证用途，不能静默提升为正式 canon。

## 项目上下文文档

这些不是工具，但它们是人类开发者或 AI 进入项目时最先应该看的上下文入口。

| 范围 | 文件 |
|---|---|
| 根项目规则 | `AGENTS.md` |
| MVP 工程规则 | `mvp/AGENTS.md` |
| 当前设计权威 | `README.md`、`docs/gdd.md`、`docs/concept.md`、`docs/machine-warehouses.md`、`docs/battlefield-rules.md`、`docs/enemy-rules.md`、`docs/deploy-lane-ui.md`、`docs/guardian-system.md`、`docs/mvp-learning-checkpoints.md`、`docs/mvp-scope.md`、`docs/mvp-hive-loadout.md`、`docs/rewards-economy.md`、`docs/DESIGN.md`、`docs/PROGRESS.md` |
| MVP v0 实现输入 | `docs/ball-machine-physical.md` |
| MVP 工程文档 | `mvp/docs/agent/README.md`、`01-project-structure.md`、`02-scene-architecture.md`、`03-gdscript-standards.md`、`04-signals-autoloads-state.md`、`05-gameplay-patterns.md`、`06-platform-export-performance.md`、`07-assets-pipeline.md`、`08-testing-validation.md`、`09-ai-coding-workflow.md` |
| 历史材料 | `docs/archive/` 只作为归档背景；除非被明确重新提升，否则不是当前证明或实现输入 |

## Skills

### gstack-game

状态：项目本地 skills，当前用于游戏设计工作流。

位置：`.codex/skills/`

用途：游戏领域的设计、验证、评审、可玩性判断、QA、发布判断，以及从设计到实现的 handoff。它不是通用 Godot 编码指南。

| 分组 | Skills |
|---|---|
| 入口和安全 | `triage`、`careful`、`guard`、`unfreeze` |
| 创意和方向 | `spark-lens`、`game-ideation`、`game-direction`、`pitch-review` |
| GDD 和设计评审 | `game-import`、`game-review`、`plan-design-review`、`game-codex` |
| 玩家体验和验证 | `player-experience`、`build-playability-review`、`feel-pass`、`playtest`、`game-ux-review`、`game-visual-qa`、`asset-review` |
| 生产桥接 | `prototype-slice-plan`、`implementation-handoff`、`gameplay-implementation-review`、`balance-review` |
| 工程、QA、发布、文档、复盘 | `game-eng-review`、`game-debug`、`game-qa`、`game-ship`、`game-docs`、`game-retro` |

### GodotPrompter

状态：已安装，可被 Codex skill discovery 发现。

位置：

- 仓库 clone：`~/.codex/godot-prompter`
- skill 软链：`~/.agents/skills/godot-prompter`
- Codex agent 软链：`~/.codex/agents/godot-prompter`
- 当前观察到的安装版本：`1.9.0`

用途：Godot 4.x 实现知识，包括 GDScript、C#、场景树、Resource、Signal、UI、物理、动画、测试、导出、优化和平台细节。

| 分组 | Skills |
|---|---|
| 核心和流程 | `using-godot-prompter`、`godot-project-setup`、`godot-brainstorming`、`godot-code-review`、`godot-debugging`、`godot-testing` |
| 架构和模式 | `scene-organization`、`state-machine`、`event-bus`、`component-system`、`resource-pattern`、`dependency-injection` |
| 物理、2D、3D、XR | `physics-system`、`2d-essentials`、`3d-essentials`、`xr-development` |
| 玩法系统 | `player-controller`、`input-handling`、`animation-system`、`tween-animation`、`audio-system`、`inventory-system`、`dialogue-system`、`save-load`、`ai-navigation`、`camera-system`、`localization`、`procedural-generation` |
| UI 和 UX | `godot-ui`、`responsive-ui`、`hud-system` |
| 多人 | `multiplayer-basics`、`multiplayer-sync`、`dedicated-server` |
| 渲染和视觉 | `shader-basics`、`particles-vfx` |
| 资产、平台、原生扩展 | `assets-pipeline`、`export-pipeline`、`godot-optimization`、`mobile-development`、`multithreading`、`gdextension`、`addon-development` |
| 脚本和数学 | `gdscript-patterns`、`gdscript-advanced`、`csharp-godot`、`csharp-signals`、`math-essentials` |

GodotPrompter 的 Codex agents 已作为可选专家入口安装：

- `godot-game-architect`
- `godot-game-dev`
- `godot-code-reviewer`
- `godot-shader-author`
- `godot-performance-profiler`
- `godot-animator`
- `godot-csharp-engineer`
- `godot-ui-designer`
- `godot-tools-engineer`

### Superpowers

状态：已安装为 Codex 插件 skill set。

用途：工程流程和执行纪律，尤其是规格、实现计划、调试、验证、代码审查、分支/worktree 和收尾流程。它不能替代 gstack-game 的游戏设计 canon，也不能替代 GodotPrompter 的 Godot API 细节。

当前可用 skills：

- `using-superpowers`
- `brainstorming`
- `writing-plans`
- `executing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`
- `requesting-code-review`
- `receiving-code-review`
- `using-git-worktrees`
- `finishing-a-development-branch`
- `subagent-driven-development`
- `dispatching-parallel-agents`
- `writing-skills`

项目备注：TDD 主要适用于纯逻辑，例如伤害结算、队列间隔、价格带、坐标计算和配置解析。物理手感、场景接线、视觉和时序类行为，应通过运行 Godot 场景和观察真实行为验证。

### 资产生成相关 Skills

状态：可用；仅在用户确认生成资产，或明确要求视觉探索时使用。

| Skill 或工具 | 用途 |
|---|---|
| `generate2dsprite` | 2D 游戏 sprite、生物、道具、动画表、透明底 cutout |
| `generate2dmap` | 2D 地图、战斗背景、战术场景、parallax 场景、tilemap |
| `hatch-pet` | Codex pet、mascot、轻量 sprite atlas；不是 planB 游戏资产的默认入口 |
| `asset-review` | 资产管线 QA、命名、格式、性能预算、风格一致性 |
| `game-visual-qa` | 游戏画面、UI、动效、适配和视觉质量检查 |

## MCP 和运行时工具

### GoPeak MCP

状态：可用，并且是 Godot 运行验证的首选工具。

用途：Godot 项目交互、诊断、场景/脚本创建、项目设置、编辑器运行、运行输出、导出和工具发现。涉及创建或修改场景/脚本时，仍必须先获得用户确认。

已知有用能力：

- `tool_catalog`
- `runtime_status`
- `editor_run`
- `scene_create`
- `script_create`
- `project_setting_get`
- `project_setting_set`
- `export_run`

GoPeak 的动态工具目录还能按需暴露更多 Godot 工具组，例如 LSP diagnostics、editor output、runtime tooling、testing、tilemap、animation、plugin、input、audio、navigation、theme UI 和 version gate。

### Node REPL MCP

状态：可用。

用途：JavaScript 执行、浏览器自动化辅助、轻量结构化数据处理，以及不适合用 shell 写的自动化 glue code。

### Browser Plugin

状态：可通过 Codex 插件工具使用。

用途：本地浏览器目标，例如 `localhost`、Web prototype、文件预览、截图和视觉 QA。它不是当前 Godot MVP 的默认工具，但如果重新启用一次性浏览器原型，会有用。

### Chrome Plugin

状态：可通过 Codex 插件工具使用。

用途：只有在需要用户已有 Chrome 状态时才使用，例如登录态、cookie、Chrome 扩展或当前浏览器 tab。它不是 planB 默认开发工具。

## Codex 内置工具

| 工具 | 用途 |
|---|---|
| Shell / `exec_command` | 本地检查、验证命令、git status、Godot CLI、验证脚本 |
| `apply_patch` | 手工编辑文件 |
| `image_gen` | 生成或编辑 raster 图片：概念图、placeholder 资产、sprite、key art |
| `web` browsing | 查询当前外部文档、GitHub 仓库、插件 manifest、工具研究 |
| `tool_search` | 发现延迟加载的 Codex 工具或插件，例如 Browser、Chrome、Figma、GitHub、Slack、Gmail、Vercel |

## Godot 和本地验证

状态：当前 MVP 实现目标。

| 工具 | 用途 |
|---|---|
| Godot 4.6 | 当前 MVP 引擎目标，工程根目录在 `mvp/` |
| GDScript | 主要实现语言 |
| Compatibility renderer | 桌面 + Web 兼容性的基线渲染器 |
| `mvp/tools/verify_godot.sh` | Godot headless 烟测入口 |
| `mvp/tools/verify_project.gd` | 项目级验证脚本 |
| `mvp/tools/verify_machine_causality.gd` | 机器因果链 vertical 验证 |
| `mvp/tools/verify_battlefield_deploy_loop.gd` | Deploy Lane 和战场循环验证 |
| `mvp/tools/verify_mvp_session.gd` | MVP session 验证 |
| `mvp/tools/verify_playable_session.gd` | playable session 验证 |

当前文档有一处已知状态不一致：根 `AGENTS.md` 仍写着仓库没有构建或验证命令，但 `README.md` 和 `mvp/AGENTS.md` 已经描述了 `mvp/tools/verify_godot.sh`。这应当作为后续文档漂移单独处理，不能作为绕过用户确认门槛的理由。

## GitHub 和外部协作

状态：可选。

| 工具 | 用途 |
|---|---|
| Git CLI | 分支、提交、diff、status、本地历史 |
| GitHub plugin / connector | PR 摘要、PR review comments、CI 检查、按需发布改动 |
| `gh` CLI | 当 connector 不够用时，用作 GitHub Actions / PR 细节操作的 fallback |

Slack、Gmail 和 Public Equity Investing connector 存在于更大的 Codex 环境里，但不是 planB 开发工具；除非用户明确要求用它们处理项目沟通或研究。

## 可选或计划中的工具

| 工具 | 状态 | 使用场景 |
|---|---|---|
| Game Studio plugin | 候选，未作为 planB 默认工具安装 | 一次性浏览器游戏原型，Phaser、Three.js、React Three Fiber、浏览器游戏 UI、sprite pipeline 和浏览器 playtest |
| Figma / FigJam | 可选 | UI mockup、图表、设计系统导向的视觉规划，或明确要求的视觉 handoff |
| Vercel plugin | 可选 | 托管 Web prototype，或浏览器原型启用后的 Vercel 文档/部署调试 |
| Blender / glTF 工具 | 仅当 3D 资产进入范围后再规划 | GLB/glTF 清理、导出、压缩、碰撞代理、LOD；当前 2D MVP baseline 不需要 |
| GUT / gdUnit4 | 候选测试框架 | 当 Godot 自动化单元/集成测试值得维护时再引入 |

## 不应当当作当前证明的工具或材料

- docs cleanup 之前的旧 Web MVP 脚本、npm 命令、probe 和 audit alias。
- `docs/archive/prototypes/three_axis_readability_battle_lab/`。
- 未被明确提升进当前文档的任何生成资产或原型。
- 尚未安装、验证并被项目接受的外部插件推荐。
