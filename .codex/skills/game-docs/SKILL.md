---
name: game-docs
description: "Game release documentation update. Generates player-facing patch notes, internal changelog, and updates all project documentation after a release."
---

## Codex/macOS Adaptation

This skill is migrated from `/Users/yang/Projects/gstack-game/skills/game-docs`. Preserve the original gstack-game method, rubrics, and game-domain judgment, but run it as a Codex project skill on macOS:

- Use repository-local files and Codex tools. Prefer `rg`, `find`, `sed`, `ls`, and direct file reads.
- Resolve this skill's bundled material relative to `.codex/skills/game-docs/`.
- Ask the user directly when the original workflow reaches an interactive decision point.
- Treat `docs/gstack-artifacts/` as the local artifact directory when the original workflow refers to shared gstack storage.
- Do not use legacy generated automation, external artifact stores, usage logging, or platform-specific paths.

## User Sovereignty

AI models recommend. You decide. When this skill finds issues, proposes changes, or
a cross-model second opinion challenges a premise — the finding is presented to you,
not auto-applied. Cross-model agreement is a strong signal, not a mandate. Your
direction is the default unless you explicitly change it.

## Completion Status Protocol

DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT.
Escalation after 3 failed attempts.


# /game-docs: Release Documentation

Update all documentation after a game release or patch.

## Step 0: Release Context

```bash
# Find recent release info
git tag --sort=-creatordate | head -5
_LATEST_TAG=$(git tag --sort=-creatordate | head -1)
[ -n "$_LATEST_TAG" ] && git log "$_LATEST_TAG"..HEAD --oneline --no-merges | head -20
```

direct user question: What version is this release? What are the highlights?

## Section 1: Player-Facing Patch Notes

**Format — players read this, not developers:**

```markdown
# Version X.Y.Z — [Catchy Title]

## ✨ New
- [Feature in player language] — [what it means for gameplay]

## ⚡ Improved
- [Improvement] — [why it matters]

## 🐛 Fixed
- [Bug description in player terms] — [what was happening, now fixed]

## ⚖️ Balance Changes
- [What changed] — [designer intent / reasoning]

## 🔧 Known Issues
- [Issue] — [workaround if any]
```

**Rules:**
- No code references, file paths, or technical jargon
- Every change answers "so what?" for the player
- Balance changes include the WHY (players want to understand intent)
- Group by impact, not by code area

**Game-Specific Patch Note Patterns:**

| Change Type | Bad (developer voice) | Good (player voice) |
|-------------|----------------------|---------------------|
| **Nerf** | "Reduced Warrior base damage from 50 to 40" | "Warriors deal less damage in early game. We noticed Warriors were clearing content 30% faster than other classes at low levels — this brings them in line while preserving their late-game power fantasy." |
| **Buff** | "Increased Mage mana regen by 20%" | "Mages recover mana faster. We heard you — running out of mana mid-fight felt punishing. You'll still need to manage resources, but you won't be stuck auto-attacking as often." |
| **Economy** | "Adjusted gold drop rates" | "You'll earn gold slightly faster from quests, but shop prices for top-tier items are higher. The net effect: mid-game feels smoother, but the best gear still requires commitment." |
| **Feel** | "Fixed input latency" | "Attacks now respond faster when you tap. If combat felt 'mushy' before, try it now — we shaved 2 frames off the startup animation." |
| **Remove** | "Removed feature X" | "We've removed [feature]. We know some of you used it, and here's why: [honest reason]. What replaces it: [alternative]." |

**Balance Change Communication Protocol:**
1. State WHAT changed (the numbers)
2. State WHY (the design intent — never leave balance changes unexplained)
3. State the EXPECTED EFFECT ("fights should last 5s longer on average")
4. Acknowledge player impact ("if you main Warrior, this will feel different")
5. Invite feedback ("tell us how this lands after a few sessions")

## Section 2: Internal Changelog

**Format — for the team:**

```markdown
# [version] — [date]

## Changes
- [commit-style description] ([files affected]) @[author]

## Metrics
- LOC changed: ___
- Files changed: ___
- Tests added: ___
- Known debt introduced: ___
```

## Section 3: Documentation Sweep

Check and update:
- [ ] README — Version number, install instructions, screenshots current?
- [ ] GDD — Does it reflect current game state? Mark outdated sections.
- [ ] API docs — If modding/plugin support exists
- [ ] Platform store descriptions — App Store/Steam/Play Store
- [ ] Website/landing page — Screenshots, feature list, trailer

## AUTO/ASK/ESCALATE

- **AUTO:** Generate changelog from git log, update version numbers
- **ASK:** Patch notes tone/framing, which changes to highlight, balance change explanations
- **ESCALATE:** Major undocumented breaking change, store description contradicts current build

## Anti-Sycophancy

Forbidden:
- ❌ "Great release!"
- ❌ "Players will appreciate these changes"

Instead: "12 changes documented. 3 balance changes need designer intent explanations before publishing."

## Completion Summary

```
Documentation:
  Patch notes: [written / updated]
  Internal changelog: [written / updated]
  Docs swept: ___/___ up to date
  STATUS: DONE / DONE_WITH_CONCERNS

  Next Step:
    PRIMARY: /game-retro — docs done, run retrospective
```

## Save Artifact

When this workflow produces a persistent artifact, write it under `docs/gstack-artifacts/` unless it names a canonical project file such as `docs/gdd.md`. Include the skill name and current timestamp in the filename when the source workflow asks for a generated artifact name.


Write to `docs/gstack-artifacts/{user}-{branch}-release-docs-{datetime}.md`. Supersedes prior if exists.

Discoverable by: /game-ship

## Review Log
