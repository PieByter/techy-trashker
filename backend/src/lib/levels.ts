export interface LevelInfo {
  level: string;
  nextLevel: string | null;
  nextLevelPoints: number;
  levelProgress: number;
}

export const LEVELS = [
  { name: 'Pemula', minPoints: 0 },
  { name: 'Eco Warrior', minPoints: 100 },
  { name: 'Green Hero', minPoints: 200 },
  { name: 'Earth Champion', minPoints: 500 },
  { name: 'Eco Legend', minPoints: 1000 },
] as const;

export function levelFor(points: number): LevelInfo {
  const safePoints = Math.max(0, points);
  let index = 0;

  while (
    index + 1 < LEVELS.length &&
    safePoints >= LEVELS[index + 1].minPoints
  ) {
    index += 1;
  }

  const current = LEVELS[index];
  const next = LEVELS[index + 1] ?? null;
  const nextLevelPoints = next?.minPoints ?? current.minPoints;
  const progress = next ? Math.min(1, safePoints / next.minPoints) : 1;

  return {
    level: current.name,
    nextLevel: next?.name ?? null,
    nextLevelPoints,
    levelProgress: Math.round(progress * 1000) / 1000,
  };
}
