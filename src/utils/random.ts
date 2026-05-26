export function nextSeed(seed: number): number {
  let value = seed | 0;
  value ^= value << 13;
  value ^= value >>> 17;
  value ^= value << 5;
  return value >>> 0;
}

export function randomFloat(seed: number): { seed: number; value: number } {
  const updated = nextSeed(seed || 1);
  return { seed: updated, value: updated / 0xffffffff };
}

export function randomInt(seed: number, min: number, max: number): { seed: number; value: number } {
  const roll = randomFloat(seed);
  return {
    seed: roll.seed,
    value: Math.floor(roll.value * (max - min + 1)) + min,
  };
}

export function pickWeighted<T>(
  seed: number,
  items: T[],
  getWeight: (item: T) => number,
): { seed: number; item: T } {
  const total = items.reduce((sum, item) => sum + Math.max(0, getWeight(item)), 0);
  const roll = randomFloat(seed);
  let cursor = roll.value * total;
  for (const item of items) {
    cursor -= Math.max(0, getWeight(item));
    if (cursor <= 0) {
      return { seed: roll.seed, item };
    }
  }
  return { seed: roll.seed, item: items[items.length - 1] };
}
