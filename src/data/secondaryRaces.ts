import type { SecondaryRaceId } from '../types/game';

export interface SecondarySupportUnitDef {
  id: string;
  name: string;
  role: 'ranged_support' | 'frontline_support';
  description: string;
}

export interface SecondaryRaceDef {
  id: SecondaryRaceId;
  name: string;
  supportUnits: SecondarySupportUnitDef[];
  coreTrait: {
    id: string;
    name: string;
    description: string;
  };
  supportHook: {
    id: string;
    name: string;
    description: string;
  };
  machineModifier: {
    id: string;
    name: string;
    description: string;
  };
  forbiddenAsSecondary: string[];
}

export const secondaryRaceDefs: Record<SecondaryRaceId, SecondaryRaceDef> = {
  arcane: {
    id: 'arcane',
    name: '秘仪议会',
    supportUnits: [
      {
        id: 'arcane_rune_acolyte',
        name: '符文侍从',
        role: 'ranged_support',
        description: 'Arcane secondary support identity marker. Combat queue insertion is not part of this slice.',
      },
      {
        id: 'arcane_refraction_guard',
        name: '折光卫士',
        role: 'frontline_support',
        description: 'Arcane secondary support identity marker. Combat queue insertion is not part of this slice.',
      },
    ],
    coreTrait: {
      id: 'rune_conversion',
      name: '符文转译',
      description: 'Standby Magic and Standby Upgrade create Rune. Standby Gold does not.',
    },
    supportHook: {
      id: 'rune_socket_charge',
      name: '符文插槽充能',
      description: 'Every 3 Rune spent may charge an eligible main-race building socket. This slice records no-socket events and creates no fallback effect.',
    },
    machineModifier: {
      id: 'standby_rune_conversion',
      name: '战备转译',
      description: 'Stored Rune automatically spends on the next resolved Unit Spawn event for main-race slot progress.',
    },
    forbiddenAsSecondary: [
      'guardian_hero_pool',
      'building_pool',
      'second_unit_spawn_board',
      'manual_rune_button',
    ],
  },
};
