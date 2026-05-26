# Continuous Phase Audit Plan

## Current Files Involved

- `src/types/game.ts`: owns run, battle, wave, reward, unit, slot, and modifier types.
- `src/systems/GameState.ts`: creates the initial run state and currently names progress as `waveIndex` / `waveActive`.
- `src/systems/WaveSystem.ts`: starts waves, spawns enemies, detects wave end, and contains the hard battlefield reset.
- `src/systems/BattleSystem.ts`: spawns units, updates deterministic lane combat, removes dead units, and records combat stats.
- `src/systems/SlotTriggerSystem.ts`: handles SPAWN, UP, GOLD, and MAGIC slot effects. The previous CHARGE mechanic has since been removed.
- `src/systems/RewardSystem.ts`: builds reward choices and mutates long-term modifiers.
- `src/systems/StatsSystem.ts`: creates and updates per-wave stats.
- `src/data/waves.ts`: defines enemy pressure schedule.
- `src/data/rewards.ts`: defines reward cards.
- `src/scenes/PrototypeScene.ts`: wires wave lifecycle, reward cards, HUD, buttons, ball dropping, and battle rendering.

## Hard Reset Findings

- `src/systems/WaveSystem.ts` `startWave()` resets combat time, moves current stats into `lastWave`, creates a fresh stat bucket, clears `state.battle.units = []`, and restores enemy base HP.
- `src/systems/WaveSystem.ts` `finishWave()` clears `state.modifiers.nextWaveSpawnLevelBonus`, so a phase transition can erase queued long-term value.
- `src/scenes/PrototypeScene.ts` `addRewardCard()` increments `state.waveIndex`, refreshes sensors, and calls `startNextWave()`, which calls `startWave()` and therefore clears the battlefield after each reward.
- `src/scenes/PrototypeScene.ts` `endWave()` treats each wave as a self-contained battle and shows a wave summary before rewards.

## State Currently Reset Between Waves

- All battle units are removed, including surviving player units and any future elite units.
- Enemy base HP is restored by `startWave()`.
- Battle elapsed time is reset.
- The current stat bucket is replaced.
- `nextWaveSpawnLevelBonus` is cleared by `finishWave()`.
- There is no persistent `spawnQueue`, no build-pause flag, and no long-term machine/building/relic arrays in the current state.

## Proposed Refactor Plan

1. Rename wave concepts in code to phase concepts where they drive run progression.
2. Replace `WaveSystem.ts` with `PhaseSystem.ts`.
3. Convert `data/waves.ts` into `data/phases.ts` with six phase definitions.
4. Add persistent run fields to `GameState`: `phaseIndex`, `phaseActive`, `isBuildPause`, `spawnQueue`, `machineUpgrades`, `slotUpgrades`, `buildings`, `relics`, `selectedRewards`, and elite promotion counters.
5. Add unit lifetime and veterancy fields to `BattleUnit`.
6. Add `SpawnQueueSystem.ts` so SPAWN adds persistent queue items and queue deployment happens each update.
7. Add `EliteSystem.ts` for phase-end veterancy and elite stat growth.
8. Make phase completion clean only temporary/summon units and transient effects.
9. Make reward selection resume the next phase without clearing player units, queue, gold, upgrades, buildings, or relics.
10. Update HUD and debug controls from wave wording to phase wording.

## Data Structures To Add Or Modify

- `PhaseDef`, `PhaseObjectiveType`, `PhaseCompleteReason`, `PhaseStats`.
- `SpawnQueueItem` with release pacing and tags.
- `UnitLifetime` and expanded `BattleUnit` fields for `maxHp`, `damage`, `lifetime`, `isElite`, `veterancyXp`, `veterancyLevel`, `phaseSpawned`, and tags.
- `GameModifiers` fields for queue release speed, elite veterancy bonus, basic stat bonuses, and next elite promotion.

## Functions To Replace

- Replace `startWave()` with `startPhase()`.
- Replace `updateWaveSpawns()` with `updatePhaseEnemySpawns()`.
- Replace `shouldEndWave()` with `shouldCompletePhase()`.
- Replace `finishWave()` with `completePhase()`.
- Replace `startNextWave()` scene method with `resumeNextPhase()`.
- Replace direct SPAWN unit creation in `triggerSpawn()` with `addToSpawnQueue()`.

## Risks

- Enemy phase spawns use elapsed time, so preserving continuous battle time requires per-phase elapsed tracking instead of resetting global battle time.
- Existing HUD has only eight slots and will need denser text without overlapping.
- Reward names and old wave wording appear in docs and scene labels, so stale wording can hide old assumptions.
- Unit rendering currently derives max HP from base definitions and level; it must use each unit's own `maxHp` after veterancy.

## Verification Steps

- Run a RED test for phase persistence before implementation.
- Verify `npm test` passes after implementation.
- Run `npm run typecheck`.
- Run `npm run build`.
- Search for old reset keywords and confirm no phase transition uses them.
- Update `docs/PROGRESS.md` with the checkpoint outcome.
