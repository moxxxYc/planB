import type { RaceDef } from '../types/game';

export const raceDefs: Record<string, RaceDef> = {
  hive: {
    id: 'hive',
    name: '虫群',
    color: 0x70d75e,
    unitPool: ['hive_grub', 'hive_spitter', 'hive_carapace', 'hive_brood_guard', 'hive_behemoth'],
    unitSlots: [
      { index: 0, unitId: 'hive_grub', label: '幼虫兵', requirement: 1 },
      { index: 1, unitId: 'hive_spitter', label: '喷吐虫', requirement: 3 },
      { index: 2, unitId: 'hive_carapace', label: '甲壳虫', requirement: 5 },
      { index: 3, unitId: 'hive_brood_guard', label: '巢群卫士', requirement: 7 },
      { index: 4, unitId: 'hive_behemoth', label: '巨虫', requirement: 9 },
    ],
    passive: 'extra_grub_chance',
  },
  mech: {
    id: 'mech',
    name: '机械',
    color: 0x6cb6ff,
    unitPool: ['mech_drone', 'mech_gunner', 'mech_walker', 'mech_siege_crawler', 'mech_titan'],
    unitSlots: [
      { index: 0, unitId: 'mech_drone', label: '无人机', requirement: 1 },
      { index: 1, unitId: 'mech_gunner', label: '机枪手', requirement: 3 },
      { index: 2, unitId: 'mech_walker', label: '步行机甲', requirement: 5 },
      { index: 3, unitId: 'mech_siege_crawler', label: '攻城履带', requirement: 7 },
      { index: 4, unitId: 'mech_titan', label: '泰坦', requirement: 9 },
    ],
    passive: 'upgrade_efficiency',
  },
};
