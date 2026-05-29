import type { BuildingChamber } from '../types/game';
import { buyUnitStructureWithGold } from './BuildingSystem';
import { buildChamberPanelSummaries, type BuildChamberPanelSummaries } from './BuildTelemetrySystem';
import { createInitialGameState } from './GameState';
import { unlockDoctrineTech } from './DoctrineSystem';
import { installRelic } from './RelicSystem';

export interface RuntimeVisualTimingEvent {
  atMs: number;
  label: string;
  changedChambers: BuildingChamber[];
  summaries: BuildChamberPanelSummaries;
}

export interface RuntimeVisualTimingReport {
  timeLimitMs: number;
  passes: boolean;
  changedChamberCount: number;
  changedChambers: BuildingChamber[];
  events: RuntimeVisualTimingEvent[];
}

export function buildRuntimeVisualTimingReport(seed = 170): RuntimeVisualTimingReport {
  const timeLimitMs = 90000;
  const state = createInitialGameState('hive', seed);
  let previous = buildChamberPanelSummaries(state);
  const changedChambers = new Set<BuildingChamber>();
  const events: RuntimeVisualTimingEvent[] = [];

  record(0, 'baseline machine layout');

  state.phaseElapsedMs = 42000;
  installRelic(state, 'prism_magazine');
  record(42000, 'phase reward: launch relic installed');

  state.phaseElapsedMs = 62000;
  state.researchPoints = Math.max(state.researchPoints, 3);
  unlockDoctrineTech(state, 'decision_slot_calibration');
  record(62000, 'research purchase: decision tech unlocked');

  state.phaseElapsedMs = 76000;
  state.gold = Math.max(state.gold, 42);
  buyUnitStructureWithGold(state, 'unit_queue_conveyor');
  record(76000, 'gold purchase: unit structure installed');

  const changedChamberList = [...changedChambers];
  return {
    timeLimitMs,
    passes: changedChamberList.length >= 2 && events.every((event) => event.atMs <= timeLimitMs),
    changedChamberCount: changedChamberList.length,
    changedChambers: changedChamberList,
    events,
  };

  function record(atMs: number, label: string) {
    const summaries = buildChamberPanelSummaries(state);
    const eventChangedChambers = getChangedChambers(previous, summaries);
    for (const chamber of eventChangedChambers) changedChambers.add(chamber);
    events.push({
      atMs,
      label,
      changedChambers: eventChangedChambers,
      summaries,
    });
    previous = summaries;
  }
}

function getChangedChambers(left: BuildChamberPanelSummaries, right: BuildChamberPanelSummaries): BuildingChamber[] {
  return (['launch', 'decision', 'unit'] as BuildingChamber[])
    .filter((chamber) => left[chamber].join('\n') !== right[chamber].join('\n'));
}
