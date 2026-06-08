# 09 — AI Coding Agent 执行协议

## 1. 工作模式

AI agent 必须采用“读现状 → 小计划 → 小改动 → 验证 → 汇报”的模式。

不要直接根据用户一句话大改项目。涉及设计 canon 的任何变更，先回到仓库根 `AGENTS.md` 的设计流程确认，不在工程实现里擅自改设计。

---

## 2. 开始任务前

必须能回答：

```text
我要改什么？为什么要改？
当前项目已有实现是什么？
涉及哪些 scene/script/resource？
需要读哪些设计文档（docs/*.md）？这次改动是否触碰设计 canon？
是否会改 project.godot / autoload / input / export / 物理层？
是否会动仓库根 AGENTS.md / docs/ / .gitignore？（默认不动，要动先确认）
如何验证？（桌面 / Web）
```

如果无法回答，先检查文件，不要猜。

---

## 3. 修改范围控制

一次任务只允许处理一个主目标。

允许：

```text
新增单位沿路自动接战
```

不允许自动扩展为：

```text
新增单位接战 + 球机物理 + Tuning 全槽 + Deploy UI + 经济 + 敌人反制 + Endpoint
```

发现连带需求写入 `Next`，不要直接做。

---

## 4. 文件修改规则

新增文件前先检查是否已有类似文件。修改已有系统时优先保持现有风格：目录风格、`class_name` 风格、Signal 连接风格、Resource 使用方式、命名规则、场景结构、本项目术语（`Launch / Tuning / Unit`、`Gate / Prime / Echo / Surge`、`Lane`、`Deploy`、`Guardian`、`Gold`）。

不要为了自己偏好的架构重写已有代码。

---

## 5. 高风险改动（必须先确认）

- 改主场景、输入映射、Autoload、导出配置、渲染器、物理层、坐标系统。
- 重命名核心 scene / 系统。
- 删除资源、大规模移动目录。
- 引入插件 / 外部依赖 / 测试框架。
- 把现有系统重构成新架构。
- 触碰仓库根 `AGENTS.md`、`docs/` 设计文档、`.gitignore`。
- 把候选草案（`neutral-modifiers.md` / `ball-machine-physical.md`）当成锁定规则写进实现。

---

## 6. 不确定时的行为

不确定时不要编造。应该写：

```text
我没有找到 X 的现有实现。
我找到了 A/B 两种可能入口。
建议先按 A 做，因为影响范围更小。
需要你确认是否采用 A。
```

设计未锁定的数值/内容，标注“占位/待确认”，不要伪装成已定规则。

---

## 7. 代码生成规则

生成 GDScript 时：必须是 Godot 4.6 API、必须加类型、必须避免跨层级硬路径、必须保留最小验证方式、必须解释新增 Signal / Group / Autoload 的用途、代码注释用中文、不要写无法运行的伪代码到正式脚本。

---

## 8. 与设计流程 / 文档的配合

```text
设计 canon（根 AGENTS.md + docs/*.md，按权威顺序）
  定义做什么、不做什么、玩法规则、平衡口径

handoff / task card（docs/gstack-artifacts/*）
  定义某次具体实现的目标、假设与验收

mvp/AGENTS.md + mvp/docs/agent/*.md
  定义 Godot 工程实现规则（怎么改代码）
```

AI agent 必须先遵守设计 canon 和当前任务输入，再遵守通用工程最佳实践。设计相关的新增/删改/锁定走根 `AGENTS.md` 的 gstack-game 设计流程，不在工程实现里替用户决定。

---

## 9. 完成任务后的汇报

使用固定格式：

```md
## Summary

## Files Changed

## Validation

## Manual Test Steps

## Risks / Limitations

## Suggested Next Step
```

没有实际运行验证必须写：

```text
Not run: 原因
```

不能写“应该可以”当成验证结果。
