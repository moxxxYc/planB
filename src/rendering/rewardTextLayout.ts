export const REWARD_CARD_DESCRIPTION_WRAP_WIDTH = 136;

type BaseTextStyle = Record<string, unknown>;

export function createRewardDescriptionTextStyle<T extends BaseTextStyle>(baseStyle: T) {
  return {
    ...baseStyle,
    align: 'center',
    fixedWidth: REWARD_CARD_DESCRIPTION_WRAP_WIDTH,
    lineSpacing: 2,
    wordWrap: {
      width: REWARD_CARD_DESCRIPTION_WRAP_WIDTH,
      useAdvancedWrap: true,
    },
  };
}
