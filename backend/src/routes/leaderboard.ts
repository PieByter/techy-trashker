import { asc, desc, eq, gt, sql, and } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { profiles } from '../db/schema';
import { serializeLeaderboardEntry } from '../lib/serializers';
import {
  commonErrorResponses,
  leaderboardResponseSchema,
} from '../schemas';

const leaderboardQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(10),
});

export const leaderboardRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/leaderboard',
    {
      preHandler: [app.optionalAuth],
      schema: {
        tags: ['Leaderboard'],
        summary: 'Peringkat pengguna berdasarkan total poin',
        security: [],
        querystring: leaderboardQuerySchema,
        response: {
          200: leaderboardResponseSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const { limit } = request.query;
      const baseUrl = app.config.publicBaseUrl;
      const userFilter = eq(profiles.role, 'user');

      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(profiles)
        .where(userFilter);

      const rows = await app.db
        .select()
        .from(profiles)
        .where(userFilter)
        .orderBy(desc(profiles.points), asc(profiles.createdAt))
        .limit(limit);

      const currentProfile =
        request.profile?.role === 'user' ? request.profile : null;
      const currentIndex = currentProfile
        ? rows.findIndex((row) => row.id === currentProfile.id)
        : -1;

      let currentUser: ReturnType<typeof serializeLeaderboardEntry> | null =
        null;

      if (currentProfile) {
        if (currentIndex >= 0) {
          currentUser = serializeLeaderboardEntry(
            currentIndex + 1,
            currentProfile,
            baseUrl,
            true,
          );
        } else {
          const [rankRow] = await app.db
            .select({ total: sql<number>`count(*)::int` })
            .from(profiles)
            .where(and(userFilter, gt(profiles.points, currentProfile.points)));

          currentUser = serializeLeaderboardEntry(
            Number(rankRow?.total ?? 0) + 1,
            currentProfile,
            baseUrl,
            true,
          );
        }
      }

      return {
        data: rows.map((row, index) =>
          serializeLeaderboardEntry(
            index + 1,
            row,
            baseUrl,
            currentProfile?.id === row.id,
          ),
        ),
        meta: {
          limit,
          totalParticipants: Number(countRow?.total ?? 0),
        },
        currentUser,
      };
    },
  );
};
