import { and, eq, sql } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';
import type { AuthUser } from '../auth/types';
import type { AppDatabase } from '../db';
import { deposits, profiles, redemptions, type Profile } from '../db/schema';
import { ApiError, isUniqueViolation } from '../lib/errors';
import { generateMemberCode } from '../lib/ids';
import type { ProfileStats } from '../lib/serializers';

const MAX_PROFILE_ATTEMPTS = 5;

export async function createProfileForAuthUser(
  app: FastifyInstance,
  authUser: AuthUser,
  options: { name?: string } = {},
): Promise<Profile> {
  const name =
    options.name?.trim() ||
    authUser.name.trim() ||
    authUser.email.split('@')[0] ||
    'Pengguna';

  for (let attempt = 0; attempt < MAX_PROFILE_ATTEMPTS; attempt += 1) {
    try {
      const [created] = await app.db
        .insert(profiles)
        .values({
          id: authUser.id,
          memberCode: generateMemberCode(),
          name,
          email: authUser.email,
          role: 'user',
        })
        .returning();

      return created;
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;

      const [byId] = await app.db
        .select()
        .from(profiles)
        .where(eq(profiles.id, authUser.id))
        .limit(1);

      if (byId) return byId;

      const [byEmail] = await app.db
        .select()
        .from(profiles)
        .where(eq(profiles.email, authUser.email))
        .limit(1);

      if (byEmail) return byEmail;
      // Kalau yang bentrok member_code, coba kode baru.
    }
  }

  throw new ApiError(
    500,
    'PROFILE_CREATE_FAILED',
    'Gagal membuat profil pengguna.',
  );
}

export async function ensureProfile(
  app: FastifyInstance,
  authUser: AuthUser,
): Promise<Profile> {
  const [existing] = await app.db
    .select()
    .from(profiles)
    .where(eq(profiles.id, authUser.id))
    .limit(1);

  if (existing) return existing;

  // User bisa saja dibuat langsung lewat Supabase Auth (mis. dashboard)
  // sehingga profilnya belum ada. Provision otomatis saat request pertama.
  const [byEmail] = await app.db
    .select()
    .from(profiles)
    .where(eq(profiles.email, authUser.email))
    .limit(1);

  if (byEmail) return byEmail;

  return createProfileForAuthUser(app, authUser);
}

export async function loadProfileStats(
  db: AppDatabase,
  userId: string,
): Promise<ProfileStats> {
  const [depositStats] = await db
    .select({
      total: sql<number>`count(*)::int`,
      completed: sql<number>`count(*) filter (where ${deposits.status} = 'completed')::int`,
    })
    .from(deposits)
    .where(eq(deposits.userId, userId));

  const [redemptionStats] = await db
    .select({
      total: sql<number>`count(*) filter (where ${redemptions.status} <> 'cancelled')::int`,
    })
    .from(redemptions)
    .where(and(eq(redemptions.userId, userId)));

  return {
    deposits: Number(depositStats?.total ?? 0),
    completedDeposits: Number(depositStats?.completed ?? 0),
    rewardsRedeemed: Number(redemptionStats?.total ?? 0),
  };
}
