# Phase 2 Build Checklist

## 必跑验证

从仓库根目录运行：

```bash
bash mvp/tools/verify_all.sh
```

通过后才进入 controlled external playtest。

## 检查项

- 现有 playable session 可进入完整流程，不依赖单独 demo。
- Battle 1 可读：机器输出、队列头、当前 `Deploy Lane`、战场结果都能被玩家侧看到。
- First Reward 表达 `Launch / Tuning / Unit` 承诺。
- First Reward 后下一场战斗有 causality feedback。
- Queue-to-Lane bridge 可读，玩家不会以为已部署单位会被改路。
- 结果页包含 6 个 recap 字段：Main Axis、Most Impactful Reward、Key Battlefield Turn、Weakest Link、Enemy Counter Impact、Next Run Suggestion。
- Counter clarity 只覆盖既有反制，没有新增内容。
- 未加入 unrelated untracked 文件，例如 `deep-research-report*.md`。

## Handoff

- 使用 `docs/playtest/PHASE2_PLAYTEST_GUIDE.md` 执行观察。
- 使用 `docs/playtest/PHASE2_FEEDBACK_FORM.md` 收集反馈。
- 反馈只用于判断可读性是否过关，不用于临时扩内容。
