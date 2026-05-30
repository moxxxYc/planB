import { buildingDefs } from '../data/buildings';
import { debugBuildPresets } from '../data/debugPresets';
import { doctrineTechDefs } from '../data/doctrineTechs';
import { activePacingPreset } from '../data/pacing';
import { phaseDefs } from '../data/phases';
import { relicDefs } from '../data/relics';
import { createInitialGameState } from './GameState';
import { applyDebugBuildPreset } from './DebugPresetSystem';
import { buildIdentityVisualSummary, buildPhaseTelemetrySummary, buildSurfaceHudSummaries } from './BuildTelemetrySystem';
import { buildProbeValidationReport } from './BuildProbeValidationSystem';
import { buildIdentitySmokePlan } from './BuildVisualSmokeSystem';
import { buildRuntimeVisualTimingReport } from './RuntimeVisualTimingSystem';

export type V12ReadinessStatus = 'proved' | 'partial' | 'missing';

export interface V12ReadinessItem {
  id: string;
  status: V12ReadinessStatus;
  requirement: string;
  evidence: string[];
  gap?: string;
}

export interface V12ReadinessReport {
  readyForCompletion: boolean;
  counts: Record<V12ReadinessStatus, number>;
  items: V12ReadinessItem[];
}

export function buildV12ReadinessReport(seed = 170): V12ReadinessReport {
  const probe = buildProbeValidationReport(seed);
  const naturalBlueprint = probe.naturalBlueprintRewardProbe;
  const state = createInitialGameState('hive', seed);
  const surfaceHud = buildSurfaceHudSummaries(state);
  const telemetry = buildPhaseTelemetrySummary(state);
  const smokePlan = buildIdentitySmokePlan('docs');
  const runtimeVisualTiming = buildRuntimeVisualTimingReport(seed);
  const visualArchetypes = new Set<string>();
  for (const preset of debugBuildPresets) {
    const presetState = createInitialGameState('hive', seed);
    applyDebugBuildPreset(presetState, preset.id);
    visualArchetypes.add(buildIdentityVisualSummary(presetState).archetype);
  }

  const items: V12ReadinessItem[] = [
    {
      id: 'three_surface_layers',
      status: hasThreeSurfaceData() ? 'proved' : 'missing',
      requirement: '发球区有遗物层，战备区有科技层，出兵区有工事层。',
      evidence: [
        `relicDefs=${relicDefs.length}`,
        `doctrineTechDefs=${doctrineTechDefs.length}`,
        `unitBuildings=${buildingDefs.filter((building) => building.chamber === 'unit').length}`,
      ],
    },
    {
      id: 'named_state_fields',
      status: hasNamedStateFields(state) ? 'proved' : 'missing',
      requirement: '持久化 launchRelics / decisionTechs / unitStructures / researchPoints / ballTags / phaseToolStock / chainHistory / buildArchetypeHint。',
      evidence: [
        `launchRelics=${Array.isArray(state.launchRelics)}`,
        `decisionTechs=${Array.isArray(state.decisionTechs)}`,
        `unitStructures=${Array.isArray(state.unitStructures)}`,
        `ballTags=${Array.isArray(state.ballTags)}`,
        `chainHistory=${Array.isArray(state.chainHistory)}`,
      ],
    },
    {
      id: 'midgame_pacing',
      status: hasMidgamePacing() ? 'proved' : 'missing',
      requirement: '阶段节奏为中短局，自动投球加快，挡板缩短速度为旧版 1/5，阶段内不再全开，并有中段工具窗口。',
      evidence: [
        `phaseDurations=${phaseDefs.map((phase) => phase.durationMs).join(',')}`,
        `autoLaunchIntervalMs=${activePacingPreset.autoLaunchIntervalMs}`,
        `unitGateFullOpenRatio=${activePacingPreset.unitGateFullOpenPhaseRatio}`,
        `phaseToolWindowOpenRatio=${activePacingPreset.phaseToolWindowOpenRatio}`,
      ],
    },
    {
      id: 'three_chamber_blueprint_rewards',
      status: hasThreeChamberBlueprintRewards(naturalBlueprint) ? 'proved' : 'missing',
      requirement: '阶段结束奖励固定给发球区、战备区、出兵区三张蓝图，且自然流程能通过蓝图形成构筑。',
      evidence: [
        `probeOk=${naturalBlueprint.ok}`,
        `offers=${naturalBlueprint.offeredChambersByPhase.map((chambers) => chambers.join('/')).join(' | ')}`,
        `selections=${naturalBlueprint.rewardSelections.map((selection) => `${selection.chamber}:${selection.rewardId}:${selection.sourceType}`).join(' / ')}`,
        `phaseTwoArchetype=${naturalBlueprint.phaseTwoArchetype}`,
        `queuedDeployed=${naturalBlueprint.metrics.unitsQueued}/${naturalBlueprint.metrics.unitsDeployed}`,
      ],
    },
    {
      id: 'debug_build_identities',
      status: debugBuildPresets.length >= 5 && visualArchetypes.size >= 5 ? 'proved' : 'missing',
      requirement: '至少 5 套可复现 debug 预设，并能清楚分辨构筑身份。',
      evidence: [
        `debugPresets=${debugBuildPresets.map((preset) => preset.name).join(' / ')}`,
        `visualArchetypes=${[...visualArchetypes].join(' / ')}`,
      ],
    },
    {
      id: 'cross_chamber_chain',
      status: probe.ok && probe.rows.every((row) => row.chainDepth >= 3) ? 'proved' : 'missing',
      requirement: '第 3 阶段前至少出现一次发球变化影响战备再影响出兵兑现的跨三仓连锁。',
      evidence: [
        `probeOk=${probe.ok}`,
        `chainDepths=${probe.rows.map((row) => `${row.presetName}:${row.chainDepth}`).join(' / ')}`,
      ],
    },
    {
      id: 'recovery_guardrail',
      status: recoveryProbePasses() ? 'proved' : 'missing',
      requirement: '连续 15 秒内禁止只有经济/法术收益却看不到后续出兵兑现。',
      evidence: [
        `recoveryProbe=${JSON.stringify(probe.rows.find((row) => row.presetId === 'recovery') ?? null)}`,
      ],
    },
    {
      id: 'phase_telemetry_answers',
      status: telemetryAnswersRequiredQuestions(telemetry.lines) ? 'proved' : 'missing',
      requirement: '阶段结束 telemetry 能回答球从哪里来、战备怎么分流、单位如何入队部署、主要靠哪一仓赢。',
      evidence: telemetry.lines,
    },
    {
      id: 'expected_outputs',
      status: hasExpectedOutputs(surfaceHud, smokePlan.length) ? 'proved' : 'missing',
      requirement: '输出三仓构筑数据、balance preset、HUD 三摘要、build summary、debug 预设、验证脚本。',
      evidence: [
        `hudRelics=${surfaceHud.relics}`,
        `hudTechs=${surfaceHud.techs}`,
        `hudStructures=${surfaceHud.structures}`,
        `smokePlanItems=${smokePlan.length}`,
      ],
    },
    {
      id: 'automated_validation',
      status: probe.ok && smokePlan.length >= 5 ? 'proved' : 'missing',
      requirement: '自动化或半自动验证脚本检查 launch -> standby -> unit slot -> queue -> deploy -> combat impact。',
      evidence: [
        `probeRows=${probe.rows.length}`,
        `probeFailures=${probe.failures.length}`,
        `visualSmokePlan=${smokePlan.map((item) => item.outputPath).join(' / ')}`,
      ],
    },
    {
      id: 'runtime_visual_timing',
      status: runtimeVisualTiming.passes ? 'proved' : 'partial',
      requirement: '前 90 秒内至少两个球仓出现肉眼可见结构变化。',
      evidence: [
        `timeLimitMs=${runtimeVisualTiming.timeLimitMs}`,
        `changedChambers=${runtimeVisualTiming.changedChambers.join(' / ')}`,
        `events=${runtimeVisualTiming.events.map((event) => `${event.atMs}:${event.label}:${event.changedChambers.join(',') || 'none'}`).join(' | ')}`,
      ],
      gap: runtimeVisualTiming.passes ? undefined : '还缺一条自动化运行 90 秒或等价快进的时序验证，证明自然流程中也会按时出现至少两个仓的结构变化。',
    },
  ];

  const counts = countStatuses(items);
  return {
    readyForCompletion: counts.missing === 0 && counts.partial === 0,
    counts,
    items,
  };

  function recoveryProbePasses(): boolean {
    const recovery = probe.rows.find((row) => row.presetId === 'recovery');
    return Boolean(probe.ok && recovery && recovery.deployed > 0 && recovery.combatImpactDamage > 0);
  }
}

export function formatV12ReadinessReport(report: V12ReadinessReport): string {
  const lines = [
    `V1.2 READINESS ${report.readyForCompletion ? 'READY' : 'NOT_READY'} proved=${report.counts.proved} partial=${report.counts.partial} missing=${report.counts.missing}`,
    ...report.items.map((item) => {
      const status = item.status.toUpperCase();
      const gap = item.gap ? ` gap=${item.gap}` : '';
      return `[${status}] ${item.id}: ${item.requirement}${gap}`;
    }),
  ];
  return lines.join('\n');
}

function hasThreeSurfaceData(): boolean {
  return relicDefs.length > 0
    && doctrineTechDefs.length > 0
    && buildingDefs.some((building) => building.chamber === 'launch')
    && buildingDefs.some((building) => building.chamber === 'decision')
    && buildingDefs.some((building) => building.chamber === 'unit');
}

function hasNamedStateFields(state: ReturnType<typeof createInitialGameState>): boolean {
  return Array.isArray(state.launchRelics)
    && Array.isArray(state.decisionTechs)
    && Array.isArray(state.unitStructures)
    && typeof state.researchPoints === 'number'
    && Array.isArray(state.ballTags)
    && Array.isArray(state.phaseToolStock)
    && Array.isArray(state.chainHistory)
    && typeof state.buildArchetypeHint === 'string';
}

function hasMidgamePacing(): boolean {
  return phaseDefs.every((phase) => phase.durationMs >= 40000 && phase.durationMs <= 55000)
    && activePacingPreset.autoLaunchIntervalMs <= 1200
    && activePacingPreset.unitGateFullOpenPhaseRatio >= 1.95
    && activePacingPreset.unitGateFullOpenPhaseRatio <= 2.05
    && activePacingPreset.phaseToolWindowOpenRatio > 0
    && activePacingPreset.phaseToolWindowOpenRatio < 1;
}

function hasThreeChamberBlueprintRewards(naturalBlueprint: ReturnType<typeof buildProbeValidationReport>['naturalBlueprintRewardProbe']): boolean {
  return naturalBlueprint.ok
    && naturalBlueprint.offeredChambersByPhase.length >= 2
    && naturalBlueprint.offeredChambersByPhase.every((chambers) => chambers.join('|') === 'launch|decision|unit')
    && naturalBlueprint.acquiredChambers.join('|') === 'launch|decision|unit'
    && naturalBlueprint.phaseTwoArchetype !== '混合构筑'
    && naturalBlueprint.metrics.naturalLaunchOrDecisionBuildingInstalled
    && naturalBlueprint.metrics.nonSpawnRecoveryWithin15s
    && naturalBlueprint.metrics.unitsQueued > 0
    && naturalBlueprint.metrics.unitsDeployed > 0;
}

function telemetryAnswersRequiredQuestions(lines: string[]): boolean {
  const text = lines.join('\n');
  return text.includes('发球')
    && text.includes('战备')
    && text.includes('入队')
    && text.includes('部署')
    && text.includes('主仓')
    && text.includes('回流效率')
    && text.includes('挡回');
}

function hasExpectedOutputs(surfaceHud: ReturnType<typeof buildSurfaceHudSummaries>, smokePlanLength: number): boolean {
  return smokePlanLength >= 5
    && typeof surfaceHud.relics === 'string'
    && typeof surfaceHud.techs === 'string'
    && typeof surfaceHud.structures === 'string'
    && relicDefs.length > 0
    && doctrineTechDefs.length > 0
    && buildingDefs.length > 0;
}

function countStatuses(items: V12ReadinessItem[]): Record<V12ReadinessStatus, number> {
  return items.reduce<Record<V12ReadinessStatus, number>>((counts, item) => {
    counts[item.status] += 1;
    return counts;
  }, { proved: 0, partial: 0, missing: 0 });
}
