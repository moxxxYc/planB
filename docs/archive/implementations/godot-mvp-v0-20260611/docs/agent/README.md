# Agent 文档使用说明

本目录是 `mvp/AGENTS.md` 的渐进式披露补充文档。`mvp/AGENTS.md` 只放高优先级工程规则；长规则拆在本目录。

本目录只覆盖 `mvp/` 下的**工程实现**。游戏设计 canon 以仓库根 `AGENTS.md` 和 `docs/` 为准。

> 状态说明：本套工程规范是在**尚无任何实现代码**时写的初稿，属于**可调约定**，不是不可动的硬约束。一旦开始写代码，实际目录名、场景结构、Signal 命名、Resource 形态若与文档不符，**以实现为准并同步更新本目录**，不要为了贴合过时文档而硬改代码。具体维护时机见第 4 节。

---

## 1. 使用方式

AI agent 每次任务不需要读完整目录，只读相关文件。

推荐读取规则：

| 任务类型 | 必读 |
|---|---|
| 新增玩法功能 | 根 `AGENTS.md`、相关 `docs/*.md`、`mvp/AGENTS.md`、`05-gameplay-patterns.md` |
| 修改场景结构 | `mvp/AGENTS.md`、`01-project-structure.md`、`02-scene-architecture.md` |
| 修改 GDScript | `mvp/AGENTS.md`、`03-gdscript-standards.md` |
| 修改 Signal / Autoload / 局内状态 | `04-signals-autoloads-state.md` |
| 平台 / 导出 / 性能 | `06-platform-export-performance.md` |
| 资产导入 / Sprite / 动画 | `07-assets-pipeline.md` |
| 测试 / 验证 / CI | `08-testing-validation.md` |
| 大任务拆解 / AI 执行 | `09-ai-coding-workflow.md` |

---

## 2. 文档边界

- 仓库根 `docs/*.md`：游戏设计源，决定做什么、不做什么，权威顺序见根 `AGENTS.md`。
- 仓库根 `AGENTS.md`：项目最高权威，设计 canon + 协作要求。
- `mvp/AGENTS.md`：`mvp/` 实现目录的最高工程规则，决定怎么改代码。
- `mvp/docs/agent/*.md`：细化工程实践。
- `mvp/tests/`、`mvp/tools/`：验证与辅助工具（GDScript CLI 脚本和 shell 脚本都放 `mvp/tools/`）。
- handoff / task card（如 `docs/gstack-artifacts/*`）：某次具体变更的输入。

设计文档说“做什么”，本目录说“怎么实现”。两者冲突时，设计 canon 优先；工程文档只调整实现方式，不改设计意图。

---

## 3. 阶段切换规则

MVP v0 完成后，不删除现有设计文档。归档与阶段切换以仓库根 `AGENTS.md` 的工作流为准。

工程侧推荐：

```text
mvp/  (MVP v0 active 实现)
  ↓ 阶段定版后
保留可复现的工程结构，下一阶段从当前正式设计文档重新写有范围约束的实现计划
```

AI agent 默认只把当前 `mvp/` 当作 active 实现。`docs/archive/` 只作历史参考，不得自动复活归档范围。

---

## 4. 维护方式

当项目出现稳定新约定时，才更新本目录。例如：

- 新增统一的伤害/接战结算模型。
- 新增统一的机器组件 / Tuning 槽 Resource 配置模式。
- 新增统一的 scene 验证脚本。
- 导出在某平台发现固定限制。
- 资产流程从 placeholder 转为正式生产流程。

不要因为一次性任务就修改全局工程规则。涉及设计 canon 的变更不在本目录处理，回到根 `AGENTS.md` 工作流。
