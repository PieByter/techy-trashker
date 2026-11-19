import { eq, sql } from 'drizzle-orm';
import type { AppDatabase } from '../db';
import {
  depositItems,
  pointTransactions,
  profiles,
  type DepositItem,
  type Profile,
} from '../db/schema';
import { isUniqueViolation } from '../lib/errors';
import { pointsFor, type WasteCategory } from '../lib/points';
import { computeWaste, type ComputedWaste } from '../lib/validation';

export type DatabaseTransaction = Parameters<
  Parameters<AppDatabase['transaction']>[0]
>[0];

export interface WasteItemInput {
  material: string;
  category: WasteCategory;
  weightKg: number;
}

export function computeDepositWaste(items: WasteItemInput[]): ComputedWaste {
  return computeWaste(items, pointsFor);
}

export async function insertDepositItems(
  tx: DatabaseTransaction,
  depositId: string,
  items: ComputedWaste['items'],
): Promise<DepositItem[]> {
  return tx
    .insert(depositItems)
    .values(
      items.map((item) => ({
        depositId,
        material: item.material,
        category: item.category,
        weightKg: item.weightKg,
        points: item.points,
      })),
    )
    .returning();
}

export async function awardDepositPoints(
  tx: DatabaseTransaction,
  input: {
    profile: Profile;
    depositId: string;
    depositCode: string;
    points: number;
    weightKg: number;
  },
): Promise<Profile> {
  const now = new Date();

  const [updated] = await tx
    .update(profiles)
    .set({
      points: sql`${profiles.points} + ${input.points}`,
      totalWeightKg: sql`${profiles.totalWeightKg} + ${input.weightKg}`,
      updatedAt: now,
    })
    .where(eq(profiles.id, input.profile.id))
    .returning();

  if (input.points > 0) {
    await tx.insert(pointTransactions).values({
      userId: input.profile.id,
      amount: input.points,
      type: 'deposit',
      description: `Poin setoran ${input.depositCode}`,
      depositId: input.depositId,
    });
  }

  return updated;
}

/**
 * Kode setoran dibuat acak. Kalau bentrok (sangat jarang), seluruh transaksi
 * diulang supaya tidak ada data setengah jadi.
 */
export async function withUniqueRetry<T>(
  operation: () => Promise<T>,
  attempts = 3,
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      lastError = error;
    }
  }

  throw lastError;
}
