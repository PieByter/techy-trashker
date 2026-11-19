import { desc, eq, sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { pointTransactions } from '../db/schema';
import { requireProfile } from '../lib/auth-helpers';
import { paginationMeta, paginationOffset } from '../lib/pagination';
import { serializePointTransaction } from '../lib/serializers';
import { paginationQuerySchema } from '../lib/validation';
import {
  commonErrorResponses,
  pointHistoryResponseSchema,
} from '../schemas';

export const pointRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/points/history',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Profile'],
        summary: 'Riwayat transaksi poin',
        security: [{ bearerAuth: [] }],
        querystring: paginationQuerySchema,
        response: {
          200: pointHistoryResponseSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);
      const { page, limit } = request.query;

      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(pointTransactions)
        .where(eq(pointTransactions.userId, profile.id));

      const rows = await app.db
        .select()
        .from(pointTransactions)
        .where(eq(pointTransactions.userId, profile.id))
        .orderBy(desc(pointTransactions.createdAt))
        .limit(limit)
        .offset(paginationOffset(page, limit));

      const [summaryRow] = await app.db
        .select({
          earned: sql<number>`coalesce(sum(${pointTransactions.amount}) filter (where ${pointTransactions.amount} > 0), 0)::int`,
          spent: sql<number>`coalesce((sum(${pointTransactions.amount}) filter (where ${pointTransactions.amount} < 0)) * -1, 0)::int`,
        })
        .from(pointTransactions)
        .where(eq(pointTransactions.userId, profile.id));

      return {
        data: rows.map(serializePointTransaction),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
        summary: {
          earned: Number(summaryRow?.earned ?? 0),
          spent: Number(summaryRow?.spent ?? 0),
          balance: profile.points,
        },
      };
    },
  );
};
