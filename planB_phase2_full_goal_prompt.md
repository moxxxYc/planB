# planB Phase 2 Full Goal Prompt for Codex

Copy the full prompt below into Codex Desktop goal mode. If Codex shows **“Implement this plan?”**, choose **Yes**. This prompt is intentionally scoped for one long autonomous Phase 2 run.

---

```text
/goal

Implement planB Phase 2: MVP Readability Sprint as one autonomous implementation run.

This is an approved implementation request, not a planning-only request. Do not stop after producing a plan unless there is a real blocker. Work in small internal milestones, but do not ask me for confirmation between milestones. Stop only for the explicit blocker conditions listed below.

Repository context:
- Work on the current planB repository and current branch.
- `mvp/` is the active Godot MVP implementation directory.
- Design authority remains in root docs and `docs/`.
- `docs/PHASE2_READABILITY_SPRINT.md` has already been created as the Phase 2 contract. Read it first and use it as the sprint source of truth. Update it only if a critical acceptance item is missing or inaccurate.

Primary objective:
Make the existing 15–20 minute Hive MVP playable session readable enough for controlled external playtesting. A first-time player should understand how a machine axis changes queue behavior, Deploy Lane routing, battle outcome, and final run recap.

The core player-understanding target is:
"I chose Launch / Tuning / Unit. That changed this machine component, which changed this queue behavior, which affected this lane or battle result. I can explain why the run succeeded or failed."

Why this matters:
The commercial risk is not whether more systems can be coded. The risk is whether players can read the machine-to-battlefield causality. Phase 2 must prove readability before content expansion.

Required tools / workflows:
- Use project-local gstack-game skills where useful for player-experience and playability judgment.
- Use GodotPrompter or `mvp/docs/agent/` for Godot 4.6 / GDScript / scene guidance.
- Use Superpowers-style execution discipline for task boundaries, verification, and review.
- Use GoPeak MCP only if the Godot project path is configured and useful. GoPeak does not replace the standard verification command.
- Standard verification command from repository root:
  `bash mvp/tools/verify_all.sh`

Hard non-goals:
- Do not create a separate tutorial mode, separate 3-step demo, or replacement MVP session.
- Do not add a second race.
- Do not add new enemies, new counter families, new Guardian kits, new event pools, new reward systems, or new battle content.
- Do not rebalance the economy broadly.
- Do not add complex meta progression.
- Do not promote `docs/ball-machine-physical.md` to long-term canon or finalize physical parameters.
- Do not restore, read, or use archived prototypes as implementation evidence.
- Do not change core terms: `Launch / Tuning / Unit`, `Gate / Prime / Echo / Surge`, `Deploy Lane`, `Guardian`, `Gold`.
- Do not add direct control of deployed units, free RTS pathfinding, `Overdrive` as a base button, PVP, networking, backend, accounts, matchmaking, Steam integration, or public demo polish.
- Do not rewrite project structure, `project.godot`, autoloads, input maps, export settings, or rendering mode without an unavoidable blocker-level reason.
- Do not add untracked research/report files such as `deep-research-report*.md` to git.

Autonomous decision rule:
When a detail is ambiguous, choose the smallest implementation that improves first-time readability while preserving existing canon and content. Do not ask for confirmation unless the change would violate a hard non-goal or require a major architecture rewrite.

Preflight:
1. Run `git status --short`.
2. Record any unrelated untracked files and do not add them.
3. Read at minimum:
   - `docs/PHASE2_READABILITY_SPRINT.md`
   - `README.md`
   - `AGENTS.md`
   - `mvp/AGENTS.md`
   - `docs/gdd.md`
   - `docs/mvp-learning-checkpoints.md`
   - `docs/mvp-scope.md`
   - `docs/machine-warehouses.md`
   - `docs/battlefield-rules.md`
   - `docs/deploy-lane-ui.md`
   - `docs/rewards-economy.md`
   - `docs/mvp-hive-loadout.md`
   - `docs/enemy-rules.md`
   - `mvp/scripts/run/mvp_playable_session.gd`
   - `mvp/scripts/run/mvp_session_model.gd`
   - `mvp/scripts/ball_machine/machine_causality_model.gd`
   - `mvp/scripts/battlefield/battlefield_deploy_model.gd`
   - `mvp/tools/verify_all.sh`
4. Run the baseline verification if practical:
   `bash mvp/tools/verify_all.sh`
   If Godot is missing, report the exact missing executable and the `GODOT_BIN=/path/to/godot bash mvp/tools/verify_all.sh` command. If this blocks all safe implementation, stop as BLOCKED. If verification fails due to a pre-existing project issue, save the output and continue only if the changes can still be safely scoped and later verified.

Implementation milestones:

Milestone 1 — Battle 1 readability inside the existing playable session
Goal:
A first-time player can understand the minimum machine -> queue -> Deploy Lane -> battle result chain by the end of Battle 1.

Implement player-facing support in the existing playable session so the player can see or infer:
- what the machine produced
- what entered the queue
- which Deploy Lane is currently selected
- where the next deployment will go
- what happened in the Battle 1 result

Rules:
- Keep UI/text short and player-facing.
- Do not use long tutorial walls.
- Do not create a new tutorial flow or separate demo scene as the deliverable.
- Debug scenes may be updated only for validation, not as the player-facing deliverable.

Milestone 2 — Player-facing machine causality feedback
Goal:
Machine causality must be visible in the playable session, not only in debug panels.

Expose a compact player-facing readout that can communicate:
- current or selected machine axis: Launch / Tuning / Unit
- relevant changed machine component
- generated or affected queue entry
- what result field or battle effect changed

Rules:
- Prefer deriving from existing model/session state.
- If adding a small readability trace or summary object is necessary, keep it narrow and deterministic.
- Do not implement final ball physics or final physical parameters.

Milestone 3 — First Reward axis commitment
Goal:
The first reward must feel like the player's first commitment to a machine axis, not a generic buff.

Implement or improve First Reward feedback so each visible first reward option communicates:
- axis: Launch / Tuning / Unit
- which machine component changes
- which queue behavior changes
- which battlefield outcome the player should watch in the next battle

After selection, show immediate confirmation of:
- chosen axis
- changed component
- next battle watch target

Rules:
- Do not expand reward count or create new reward families.
- Use existing MVP reward/economy resources when possible.
- Do not rebalance the whole economy.

Milestone 4 — Next-battle causality readout after First Reward
Goal:
The player must not wait until the final result page to learn whether the First Reward mattered.

After the next battle following First Reward, show a compact causality readout with:
- chosen/main axis
- changed machine component
- changed queue behavior
- affected lane or battle result
- one short explanation of why the outcome changed

Critical requirement:
The readout must not frame the outcome as only "you clicked the right lane." Deploy Lane should remain the routing/commitment surface for machine output, not the main system.

Milestone 5 — Queue-to-Lane bridge readability
Goal:
The queue head, current Deploy Lane, actual deployed lane, and battle result must not be confused.

Ensure the playable session makes these relationships readable:
- player can see the queue head or next deployable output
- player can see the currently selected Deploy Lane
- player can predict where the next deployment will go
- already-deployed units or outcomes do not appear to change origin when Deploy Lane changes later
- battle result distinguishes machine contribution from lane-click decision

This may be implemented together with Milestone 1 or 4 if that is the smallest safe change, but it must be explicitly verified.

Milestone 6 — Result Page machine-cause recap
Goal:
At run end, the result page must explain the run in machine-axis terms, not just Victory / Defeat.

Add or improve result recap fields:
- Main Axis
- Most Impactful Reward
- Key Battlefield Turn
- Weakest Link
- Enemy Counter Impact
- Next Run Suggestion

Rules:
- Prefer data-derived recap from session state, selected rewards, battle summaries, and existing counters.
- If a field must use deterministic fallback logic, keep it explicit and stable.
- Do not invent new content to fill recap fields.
- The recap should help the player answer: "What should I try differently next run?"

Milestone 7 — Minimal existing counter clarity, only after core loop works
Goal:
Clarify existing counter telegraphs only if the core readability loop is already implemented and verified.

Allowed existing counters only:
- Pool Polluter
- Echo Breaker
- Stagger Punisher

Clarify:
- what the counter is warning about
- which machine axis or behavior it pressures
- what kind of response is allowed or worth watching

Rules:
- No new counter systems.
- No new enemies.
- No new balance layer.
- No hidden tax feeling.
- If this milestone risks delaying or destabilizing the core loop, skip it and report it as intentionally deferred.

Milestone 8 — Verification and playtest handoff
Goal:
Phase 2 must end as a controlled external readability playtest candidate, not a public demo.

Verification:
- Add or update focused verification for the Phase 2 readability flow.
- This can be done by extending existing verifiers or adding a new focused verifier.
- If adding a new verifier, include it in `mvp/tools/verify_all.sh`.
- Missing Battle 1 readability state, First Reward axis commitment, next-battle causality feedback, Queue-to-Lane bridge fields, or Result Page recap fields should fail visibly.

At minimum, verification should check that the playable session can expose:
- Battle 1 readable machine/queue/lane/result summary
- First Reward axis commitment data
- next-battle causality summary after First Reward
- Queue-to-Lane relationship data
- result recap with the six required fields

Run:
`bash mvp/tools/verify_all.sh`

Playtest handoff docs:
Create or update minimal controlled playtest documents using repo-relative paths:
- `docs/playtest/PHASE2_PLAYTEST_GUIDE.md`
- `docs/playtest/PHASE2_FEEDBACK_FORM.md`
- `docs/playtest/KNOWN_ISSUES.md`
- `docs/playtest/BUILD_CHECKLIST.md`

The feedback form must ask at least:
- What do you think the goal of the run was?
- Which axis did you commit to: Launch, Tuning, or Unit?
- What did that choice change in the machine?
- What queue or lane effect did you expect to watch next?
- Why do you think you won or lost?
- Did you want to immediately start another run?
- What would you try differently next run?
- Which part was confusing?
- How would you describe this game in one sentence?

Definition of done:
Phase 2 is complete only if:
- The existing playable session, not a separate demo, contains the readability improvements.
- Battle 1 teaches the machine -> queue -> Deploy Lane -> battle result chain through player-facing UI or concise feedback.
- First Reward clearly communicates a Launch / Tuning / Unit commitment.
- The next battle after First Reward shows a causality readout.
- Queue-to-Lane bridge is readable.
- Result Page has the six machine-cause recap fields.
- Verification covers the Phase 2 readability flow.
- `bash mvp/tools/verify_all.sh` passes, or the final report clearly states the exact blocker.
- Playtest handoff docs exist.
- No content expansion or canon rewrite happened.

Git / commit behavior:
- Do not add unrelated untracked files.
- Do not use `git add .`.
- Use targeted `git add <path>` only.
- If committing is allowed in the current workflow, make local commits at logical boundaries or one final local commit after verification.
- Suggested commit messages if using multiple commits:
  - `feat: clarify battle 1 readability flow`
  - `feat: surface playable machine causality feedback`
  - `feat: add first reward axis commitment`
  - `feat: add next battle causality readout`
  - `feat: add result page machine cause recap`
  - `test: verify phase 2 readability loop`
  - `docs: add phase 2 playtest handoff`
- Do not push to GitHub unless I explicitly asked for push in the current session.

Stop conditions:
Stop as BLOCKED only if:
- Godot cannot be found and no safe code/documentation work can continue.
- The project cannot open or baseline verification shows a blocker outside Phase 2 scope.
- A required change would violate a hard non-goal.
- A required change would need major architecture replacement.
- There is a design-canon conflict that cannot be resolved by the smallest readability-preserving interpretation.

Final report format:
When finished, report exactly:
1. Final status: PASS / PASS_WITH_WARNINGS / BLOCKED
2. Summary of what changed
3. Changed files grouped by gameplay code, scenes, resources, verification, docs
4. Verification commands run and results
5. Whether GoPeak was used; if not, why not
6. Scope compliance confirmation, including explicit statement that no content expansion was added
7. Playtest readiness checklist
8. Known issues or deferred items
9. Git status summary
10. Commit hashes if commits were created

Do not continue beyond Phase 2 scope after completing this goal.
```
