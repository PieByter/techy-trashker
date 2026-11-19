import { and, asc, desc, eq, inArray, sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { deposits, profiles, wasteBanks } from '../db/schema';
import { paginationMeta, paginationOffset } from '../lib/pagination';
import {
  serializeDeposit,
  serializeMember,
} from '../lib/serializers';
import { paginationQuerySchema } from '../lib/validation';
import {
  commonErrorResponses,
  officerDepositSchema,
  paginatedSchema,
} from '../schemas';

const officerQueueQuerySchema = paginationQuerySchema.extend({
  status: z
    .enum(['scheduled', 'processing', 'completed', 'cancelled'])
    .optional(),
  method: z.enum(['dropoff', 'pickup']).optional(),
  wasteBankId: z.string().uuid().optional(),
  sort: z.enum(['scheduled', 'newest', 'oldest']).default('scheduled'),
});

export const officerRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/officer/deposits',
    {
      preHandler: [app.authenticate, app.requireRole('officer', 'admin')],
      schema: {
        tags: ['Officer'],
        summary: 'Antrean setoran untuk petugas',
        description:
          'Default menampilkan setoran aktif (scheduled + processing). Gunakan ' +
          'status untuk melihat riwayat tertentu. Endpoint ini dipakai petugas ' +
          'untuk menemukan penjemputan yang harus diselesaikan.',
        security: [{ bearerAuth: [] }],
        querystring: officerQueueQuerySchema,
        response: {
          200: paginatedSchema(officerDepositSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const { page, limit, status, method, wasteBankId, sort } = request.query;
      const filters = [];

      if (status) {
        filters.push(eq(deposits.status, status));
      } else {
        filters.push(inArray(deposits.status, ['scheduled', 'processing']));
      }

      if (method) filters.push(eq(deposits.method, method));
      if (wasteBankId) filters.push(eq(deposits.wasteBankId, wasteBankId));

      const where = and(...filters);

      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(deposits)
        .where(where);

      const orderBy =
        sort === 'newest'
          ? [desc(deposits.createdAt)]
          : sort === 'oldest'
            ? [asc(deposits.createdAt)]
            : [asc(deposits.scheduledAt), asc(deposits.createdAt)];

      const rows = await app.db
        .select({
          deposit: deposits,
          profile: profiles,
          wasteBankName: wasteBanks.name,
        })
        .from(deposits)
        .innerJoin(profiles, eq(deposits.userId, profiles.id))
        .leftJoin(wasteBanks, eq(deposits.wasteBankId, wasteBanks.id))
        .where(where)
        .orderBy(...orderBy)
        .limit(limit)
        .offset(paginationOffset(page, limit));

      return {
        data: rows.map((row) => ({
          ...serializeDeposit(row.deposit, [], row.wasteBankName),
          member: serializeMember(row.profile, app.config.publicBaseUrl),
        })),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
      };
    },
  );
};
