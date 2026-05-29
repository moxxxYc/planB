import { debugBuildPresets } from '../data/debugPresets';
import type { DebugBuildPresetId } from '../types/game';

export interface BuildIdentitySmokePlanItem {
  presetId: DebugBuildPresetId;
  displayName: string;
  action: string;
  outputPath: string;
}

export function buildIdentitySmokePlan(outputDir = 'docs'): BuildIdentitySmokePlanItem[] {
  const normalizedDir = outputDir.replace(/\/+$/, '');
  return debugBuildPresets.map((preset) => ({
    presetId: preset.id,
    displayName: preset.name,
    action: `preset-${preset.id}`,
    outputPath: `${normalizedDir}/build-identity-${preset.id}-smoke.png`,
  }));
}
