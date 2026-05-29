export interface PacingPreset {
  id: string;
  autoLaunchIntervalMs: number;
  multiBallDelayMs: number;
  unitGateFullOpenPhaseRatio: number;
  phaseToolWindowOpenRatio: number;
  phaseDurationsMs: number[];
}

export const activePacingPreset: PacingPreset = {
  id: 'fast_build_validation',
  autoLaunchIntervalMs: 1100,
  multiBallDelayMs: 120,
  unitGateFullOpenPhaseRatio: 0.4,
  phaseToolWindowOpenRatio: 0.35,
  phaseDurationsMs: [42000, 44000, 46000, 50000, 54000, 55000],
};
