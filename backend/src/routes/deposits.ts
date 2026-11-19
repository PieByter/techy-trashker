import { and, asc, desc, eq, sql } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  depositItems,
  deposits,
  profiles,
  wasteBanks,
} from '../db/schema';
import { requireProfile } from '../lib/auth-helpers';
import { ApiError } from '../lib/errors';
import { generateDepositCode } from '../lib/ids';
import { round } from '../lib/numbers';
import { paginationMeta, paginationOffset } from '../lib/pagination';
import {
  serializeDeposit,
  serializeMember,
} from '../lib/serializers';
import {
  paginationQuerySchema,
  uuidParamSchema,
  wasteCategorySchema,
  wasteItemsSchema,
  weightKgSchema,
} from '../lib/validation';
import {
  commonErrorResponses,
  completeDepositResponseSchema,
  depositSchema,
  depositSummarySchema,
  paginatedSchema,
} from '../schemas';
import {
  awardDepositPoints,
  computeDepositWaste,
  insertDepositItems,
  withUniqueRetry,
} from '../services/deposits';

const depositListQuerySchema = paginationQuerySchema.extend({
  method: z.enum(['dropoff', 'pickup']).optional(),
  status: z
    .enum(['scheduled', 'processing', 'completed', 'cancelled'])
    .optional(),
  sort: z.enum(['newest', 'oldest']).default('newest'),
});

const createDepositBodySchema = z
  .object({
    method: z.enum(['dropoff', 'pickup']),
    material: z.string().trim().min(2, 'Nama material wajib diisi.').max(80),
    category: wasteCategorySchema,
    weightKg: weightKgSchema,
    wasteBankId: z.string().uuid('ID bank sampah tidak valid.').optional(),
    address: z.string().trim().min(10, 'Alamat terlalu pendek.').max(300).optional(),
    scheduledAt: z.coerce.date().optional(),
    notes: z.string().trim().max(500).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.method !== 'pickup') return;

    if (!value.address) {
      ctx.addIssue({
        code: 'custom',
        path: ['address'],
        message: 'Alamat wajib diisi untuk penjemputan.',
      });
    }

    if (!value.scheduledAt) {
      ctx.addIssue({
        code: 'custom',
        path: ['scheduledAt'],
        message: 'Jadwal penjemputan wajib diisi.',
      });
      return;
    }

    const minTime = Date.now() + 15 * 60 * 1000;
    const maxTime = Date.now() + 30 * 24 * 60 * 60 * 1000;

    if (value.scheduledAt.getTime() < minTime) {
      ctx.addIssue({
        code: 'custom',
        path: ['scheduledAt'],
        message: 'Jadwal penjemputan minimal 15 menit dari sekarang.',
      });
    }

    if (value.scheduledAt.getTime() > maxTime) {
      ctx.addIssue({
        code: 'custom',
        path: ['scheduledAt'],
        message: 'Jadwal penjemputan maksimal 30 hari ke depan.',
      });
    }
  });

const completeDepositBodySchema = z.object({
  items: wasteItemsSchema,
  wasteBankId: z.string().uuid('ID bank sampah tidak valid.').optional(),
  notes: z.string().trim().max(500).optional(),
});

async function findWasteBankName(
  app: FastifyInstance,
  wasteBankId: string | null,
): Promise<string | null> {
  if (!wasteBankId) return null;

  const [bank] = await app.db
    .select({ name: wasteBanks.name })
    .from(wasteBanks)
    .where(eq(wasteBanks.id, wasteBankId))
    .limit(1);

  if (!bank) {
    throw new ApiError(
      404,
      'WASTE_BANK_NOT_FOUND',
      'Bank sampah tidak ditemukan.',
    );
  }

  return bank.name;
}

export const depositRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/deposits',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Deposits'],
        summary: 'Riwayat setoran pengguna',
        security: [{ bearerAuth: [] }],
        querystring: depositListQuerySchema,
        response: {
          200: paginatedSchema(depositSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);
      const { page, limit, method, status, sort } = request.query;
      const filters = [eq(deposits.userId, profile.id)];

      if (method) filters.push(eq(deposits.method, method));
      if (status) filters.push(eq(deposits.status, status));

      const where = and(...filters);

      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(deposits)
        .where(where);

      const rows = await app.db
        .select({
          deposit: deposits,
          wasteBankName: wasteBanks.name,
        })
        .from(deposits)
        .leftJoin(wasteBanks, eq(deposits.wasteBankId, wasteBanks.id))
        .where(where)
        .orderBy(
          sort === 'oldest'
            ? asc(deposits.createdAt)
            : desc(deposits.createdAt),
        )
        .limit(limit)
        .offset(paginationOffset(page, limit));

      return {
        data: rows.map((row) =>
          serializeDeposit(row.deposit, [], row.wasteBankName),
        ),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
      };
    },
  );

  app.get(
    '/deposits/summary',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Deposits'],
        summary: 'Ringkasan setoran untuk header riwayat',
        security: [{ bearerAuth: [] }],
        response: {
          200: depositSummarySchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);

      const [row] = await app.db
        .select({
          total: sql<number>`count(*)::int`,
          completed: sql<number>`count(*) filter (where ${deposits.status} = 'completed')::int`,
          scheduled: sql<number>`count(*) filter (where ${deposits.status} = 'scheduled')::int`,
          processing: sql<number>`count(*) filter (where ${deposits.status} = 'processing')::int`,
          cancelled: sql<number>`count(*) filter (where ${deposits.status} = 'cancelled')::int`,
          totalWeightKg: sql<number>`coalesce(sum(${deposits.weightKg}) filter (where ${deposits.status} = 'completed'), 0)::float8`,
          totalPoints: sql<number>`coalesce(sum(${deposits.points}) filter (where ${deposits.status} = 'completed'), 0)::int`,
          dropoff: sql<number>`count(*) filter (where ${deposits.method} = 'dropoff')::int`,
          pickup: sql<number>`count(*) filter (where ${deposits.method} = 'pickup')::int`,
        })
        .from(deposits)
        .where(eq(deposits.userId, profile.id));

      return {
        total: Number(row?.total ?? 0),
        completed: Number(row?.completed ?? 0),
        scheduled: Number(row?.scheduled ?? 0),
        processing: Number(row?.processing ?? 0),
        cancelled: Number(row?.cancelled ?? 0),
        totalWeightKg: round(Number(row?.totalWeightKg ?? 0), 2),
        totalPoints: Number(row?.totalPoints ?? 0),
        byMethod: {
          dropoff: Number(row?.dropoff ?? 0),
          pickup: Number(row?.pickup ?? 0),
        },
      };
    },
  );

  app.get(
    '/deposits/:id',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Deposits'],
        summary: 'Detail setoran',
        security: [{ bearerAuth: [] }],
        params: uuidParamSchema,
        response: {
          200: depositSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);

      const [row] = await app.db
        .select({
          deposit: deposits,
          wasteBankName: wasteBanks.name,
        })
        .from(deposits)
        .leftJoin(wasteBanks, eq(deposits.wasteBankId, wasteBanks.id))
        .where(eq(deposits.id, request.params.id))
        .limit(1);

      if (!row) {
        throw new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Setoran tidak ditemukan.');
      }

      if (profile.role === 'user' && row.deposit.userId !== profile.id) {
        throw new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Setoran tidak ditemukan.');
      }

      const items = await app.db
        .select()
        .from(depositItems)
        .where(eq(depositItems.depositId, row.deposit.id));

      return serializeDeposit(row.deposit, items, row.wasteBankName);
    },
  );

  app.post(
    '/deposits',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Deposits'],
        summary: 'Buat permintaan setor atau penjemputan',
        description:
          'Drop-off membuat setoran berstatus processing. Pickup membuat jadwal ' +
          'penjemputan berstatus scheduled. Poin baru diberikan setelah petugas ' +
          'menimbang dan menyelesaikan setoran.',
        security: [{ bearerAuth: [] }],
        body: createDepositBodySchema,
        response: {
          201: depositSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request, reply) => {
      const profile = requireProfile(request);
      const body = request.body;
      const wasteBankName = await findWasteBankName(
        app,
        body.wasteBankId ?? null,
      );

      const created = await withUniqueRetry(async () => {
        const [row] = await app.db
          .insert(deposits)
          .values({
            code: generateDepositCode(),
            userId: profile.id,
            wasteBankId: body.wasteBankId ?? null,
            method: body.method,
            status: body.method === 'pickup' ? 'scheduled' : 'processing',
            material: body.material,
            category: body.category,
            weightKg: body.weightKg,
            points: 0,
            address: body.method === 'pickup' ? (body.address ?? null) : null,
            scheduledAt:
              body.method === 'pickup' ? (body.scheduledAt ?? null) : null,
            notes: body.notes ?? null,
          })
          .returning();

        return row;
      });

      reply.code(201);
      return serializeDeposit(created, [], wasteBankName);
    },
  );

  app.post(
    '/deposits/:id/cancel',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Deposits'],
        summary: 'Batalkan setoran yang belum selesai',
        security: [{ bearerAuth: [] }],
        params: uuidParamSchema,
        response: {
          200: depositSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);

      const [deposit] = await app.db
        .select()
        .from(deposits)
        .where(eq(deposits.id, request.params.id))
        .limit(1);

      if (!deposit) {
        throw new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Setoran tidak ditemukan.');
      }

      if (profile.role === 'user' && deposit.userId !== profile.id) {
        throw new ApiError(404, 'DEPOSIT_NOT_FOUND', 'Setoran tidak ditemukan.');
      }

      if (deposit.status !== 'scheduled' && deposit.status !== 'processing') {
        throw ApiError.conflict(
          `Setoran berstatus ${deposit.status} tidak bisa dibatalkan.`,
          'DEPOSIT_CANNOT_BE_CANCELLED',
        );
      }

      const [updated] = await app.db
        .update(deposits)
        .set({ status: 'cancelled', updatedAt: new Date() })
        .where(eq(deposits.id, deposit.id))
        .returning();

      const bankName = await findWasteBankName(app, updated.wasteBankId);
      return serializeDeposit(updated, [], bankName);
    },
  );

  app.post(
    '/deposits/:id/complete',
    {
      preHandler: [app.authenticate, app.requireRole('officer', 'admin')],
      schema: {
        tags: ['Deposits'],
        summary: 'Petugas menimbang dan menyelesaikan setoran',
        description:
          'Menghitung poin dari item aktual, mengubah status menjadi completed, ' +
          'dan menambahkan poin serta total berat ke profil member.',
        security: [{ bearerAuth: [] }],
        params: uuidParamSchema,
        body: completeDepositBodySchema,
        response: {
          200: completeDepositResponseSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const body = request.body;
      const bankName = await findWasteBankName(
        app,
        body.wasteBankId ?? null,
      );

      const result = await app.db.transaction(async (tx) => {
        const [deposit] = await tx
          .select()
          .from(deposits)
          .where(eq(deposits.id, request.params.id))
          .limit(1)
          .for('update');

        if (!deposit) {
          throw new ApiError(
            404,
            'DEPOSIT_NOT_FOUND',
            'Setoran tidak ditemukan.',
          );
        }

        if (deposit.status === 'completed') {
          throw ApiError.conflict(
            'Setoran ini sudah diselesaikan.',
            'DEPOSIT_ALREADY_COMPLETED',
          );
        }

        if (deposit.status === 'cancelled') {
          throw ApiError.conflict(
            'Setoran ini sudah dibatalkan.',
            'DEPOSIT_CANCELLED',
          );
        }

        const [owner] = await tx
          .select()
          .from(profiles)
          .where(eq(profiles.id, deposit.userId))
          .limit(1)
          .for('update');

        if (!owner) {
          throw new ApiError(
            404,
            'MEMBER_NOT_FOUND',
            'Pemilik setoran tidak ditemukan.',
          );
        }

        const waste = computeDepositWaste(body.items);
        const now = new Date();
        const items = await insertDepositItems(tx, deposit.id, waste.items);

        const [updatedDeposit] = await tx
          .update(deposits)
          .set({
            material: waste.primaryMaterial,
            category: waste.primaryCategory,
            weightKg: waste.totalWeightKg,
            points: waste.totalPoints,
            status: 'completed',
            wasteBankId: body.wasteBankId ?? deposit.wasteBankId,
            notes: body.notes ?? deposit.notes,
            completedAt: now,
            updatedAt: now,
          })
          .where(eq(deposits.id, deposit.id))
          .returning();

        const updatedProfile = await awardDepositPoints(tx, {
          profile: owner,
          depositId: deposit.id,
          depositCode: deposit.code,
          points: waste.totalPoints,
          weightKg: waste.totalWeightKg,
        });

        return { deposit: updatedDeposit, items, profile: updatedProfile };
      });

      return {
        deposit: serializeDeposit(
          result.deposit,
          result.items,
          bankName ??
            (await findWasteBankName(app, result.deposit.wasteBankId)),
        ),
        member: serializeMember(result.profile, app.config.publicBaseUrl),
        pointsEarned: result.deposit.points,
      };
    },
  );
};
