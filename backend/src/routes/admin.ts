import { and, desc, eq, sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  pointTransactions,
  profiles,
  redemptions,
  rewards,
} from '../db/schema';
import { ApiError, isUniqueViolation } from '../lib/errors';
import { paginationMeta, paginationOffset } from '../lib/pagination';
import {
  serializeRedemption,
  serializeReward,
} from '../lib/serializers';
import { slugify } from '../lib/slug';
import {
  nameSchema,
  paginationQuerySchema,
  uuidParamSchema,
} from '../lib/validation';
import {
  commonErrorResponses,
  paginatedSchema,
  redemptionSchema,
  rewardSchema,
} from '../schemas';

const rewardBodySchema = z.object({
  title: nameSchema.max(120),
  description: z.string().trim().min(10).max(1000),
  pointsCost: z.number().int().min(1).max(1_000_000),
  stock: z.number().int().min(0).max(1_000_000),
  imageUrl: z.string().url().max(1000).nullable().optional(),
  isActive: z.boolean().optional(),
  slug: z
    .string()
    .trim()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug hanya boleh huruf kecil, angka, dan tanda hubung.')
    .max(100)
    .optional(),
});

const rewardUpdateBodySchema = rewardBodySchema
  .partial()
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Minimal satu field harus diisi.',
  });

const redemptionListQuerySchema = paginationQuerySchema.extend({
  status: z.enum(['pending', 'fulfilled', 'cancelled']).optional(),
});

const redemptionUpdateBodySchema = z.object({
  status: z.enum(['fulfilled', 'cancelled']),
});

export const adminRoutes: FastifyPluginAsyncZod = async (app) => {
  const adminOnly = {
    preHandler: [app.authenticate, app.requireRole('admin')],
    schema: {
      security: [{ bearerAuth: [] }],
    },
  };

  app.post(
    '/admin/rewards',
    {
      ...adminOnly,
      schema: {
        ...adminOnly.schema,
        tags: ['Admin'],
        summary: 'Tambah reward',
        body: rewardBodySchema,
        response: {
          201: rewardSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request, reply) => {
      const body = request.body;

      try {
        const [reward] = await app.db
          .insert(rewards)
          .values({
            slug: body.slug ?? slugify(body.title),
            title: body.title,
            description: body.description,
            pointsCost: body.pointsCost,
            stock: body.stock,
            imageUrl: body.imageUrl ?? null,
            isActive: body.isActive ?? true,
          })
          .returning();

        reply.code(201);
        return serializeReward(reward, app.config.publicBaseUrl, false);
      } catch (error) {
        if (isUniqueViolation(error)) {
          throw ApiError.conflict(
            'Slug reward sudah dipakai. Pilih slug lain.',
            'REWARD_SLUG_TAKEN',
          );
        }
        throw error;
      }
    },
  );

  app.patch(
    '/admin/rewards/:id',
    {
      ...adminOnly,
      schema: {
        ...adminOnly.schema,
        tags: ['Admin'],
        summary: 'Ubah reward',
        params: uuidParamSchema,
        body: rewardUpdateBodySchema,
        response: {
          200: rewardSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const body = request.body;
      const updates: Partial<typeof rewards.$inferInsert> = {
        updatedAt: new Date(),
      };

      if (body.title !== undefined) updates.title = body.title;
      if (body.description !== undefined) updates.description = body.description;
      if (body.pointsCost !== undefined) updates.pointsCost = body.pointsCost;
      if (body.stock !== undefined) updates.stock = body.stock;
      if (body.imageUrl !== undefined) updates.imageUrl = body.imageUrl;
      if (body.isActive !== undefined) updates.isActive = body.isActive;
      if (body.slug !== undefined) updates.slug = body.slug;

      try {
        const [reward] = await app.db
          .update(rewards)
          .set(updates)
          .where(eq(rewards.id, request.params.id))
          .returning();

        if (!reward) {
          throw new ApiError(
            404,
            'REWARD_NOT_FOUND',
            'Reward tidak ditemukan.',
          );
        }

        return serializeReward(reward, app.config.publicBaseUrl, false);
      } catch (error) {
        if (isUniqueViolation(error)) {
          throw ApiError.conflict(
            'Slug reward sudah dipakai. Pilih slug lain.',
            'REWARD_SLUG_TAKEN',
          );
        }
        throw error;
      }
    },
  );

  app.delete(
    '/admin/rewards/:id',
    {
      ...adminOnly,
      schema: {
        ...adminOnly.schema,
        tags: ['Admin'],
        summary: 'Nonaktifkan reward',
        description: 'Reward tidak dihapus permanen agar riwayat redemption tetap utuh.',
        params: uuidParamSchema,
        response: {
          200: rewardSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const [reward] = await app.db
        .update(rewards)
        .set({ isActive: false, updatedAt: new Date() })
        .where(eq(rewards.id, request.params.id))
        .returning();

      if (!reward) {
        throw new ApiError(404, 'REWARD_NOT_FOUND', 'Reward tidak ditemukan.');
      }

      return serializeReward(reward, app.config.publicBaseUrl, false);
    },
  );

  app.get(
    '/admin/redemptions',
    {
      ...adminOnly,
      schema: {
        ...adminOnly.schema,
        tags: ['Admin'],
        summary: 'Daftar redemption semua pengguna',
        querystring: redemptionListQuerySchema,
        response: {
          200: paginatedSchema(redemptionSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const { page, limit, status } = request.query;
      const filters = [];

      if (status) filters.push(eq(redemptions.status, status));

      const where = filters.length > 0 ? and(...filters) : undefined;
      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(redemptions)
        .where(where);

      const rows = await app.db
        .select({
          redemption: redemptions,
          reward: rewards,
          profile: profiles,
        })
        .from(redemptions)
        .innerJoin(rewards, eq(redemptions.rewardId, rewards.id))
        .innerJoin(profiles, eq(redemptions.userId, profiles.id))
        .where(where)
        .orderBy(desc(redemptions.createdAt))
        .limit(limit)
        .offset(paginationOffset(page, limit));

      return {
        data: rows.map((row) =>
          serializeRedemption(
            row.redemption,
            row.reward,
            app.config.publicBaseUrl,
            row.profile,
          ),
        ),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
      };
    },
  );

  app.patch(
    '/admin/redemptions/:id',
    {
      ...adminOnly,
      schema: {
        ...adminOnly.schema,
        tags: ['Admin'],
        summary: 'Penuhi atau batalkan redemption',
        description:
          'Pembatalan mengembalikan poin ke member dan mengembalikan stok reward.',
        params: uuidParamSchema,
        body: redemptionUpdateBodySchema,
        response: {
          200: redemptionSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const result = await app.db.transaction(async (tx) => {
        const [redemption] = await tx
          .select()
          .from(redemptions)
          .where(eq(redemptions.id, request.params.id))
          .limit(1)
          .for('update');

        if (!redemption) {
          throw new ApiError(
            404,
            'REDEMPTION_NOT_FOUND',
            'Penukaran reward tidak ditemukan.',
          );
        }

        if (redemption.status !== 'pending') {
          throw ApiError.conflict(
            `Redemption berstatus ${redemption.status} tidak bisa diubah.`,
            'REDEMPTION_FINALIZED',
          );
        }

        const [reward] = await tx
          .select()
          .from(rewards)
          .where(eq(rewards.id, redemption.rewardId))
          .limit(1)
          .for('update');

        if (!reward) {
          throw new ApiError(404, 'REWARD_NOT_FOUND', 'Reward tidak ditemukan.');
        }

        const [profile] = await tx
          .select()
          .from(profiles)
          .where(eq(profiles.id, redemption.userId))
          .limit(1)
          .for('update');

        if (!profile) {
          throw new ApiError(
            404,
            'MEMBER_NOT_FOUND',
            'Pemilik redemption tidak ditemukan.',
          );
        }

        const now = new Date();
        let updatedReward = reward;
        let updatedProfile = profile;

        if (request.body.status === 'cancelled') {
          [updatedReward] = await tx
            .update(rewards)
            .set({ stock: reward.stock + 1, updatedAt: now })
            .where(eq(rewards.id, reward.id))
            .returning();

          [updatedProfile] = await tx
            .update(profiles)
            .set({
              points: profile.points + redemption.pointsSpent,
              updatedAt: now,
            })
            .where(eq(profiles.id, profile.id))
            .returning();

          await tx.insert(pointTransactions).values({
            userId: profile.id,
            amount: redemption.pointsSpent,
            type: 'adjustment',
            description: `Refund penukaran: ${reward.title}`,
            redemptionId: redemption.id,
          });
        }

        const [updatedRedemption] = await tx
          .update(redemptions)
          .set({
            status: request.body.status,
            fulfilledAt: request.body.status === 'fulfilled' ? now : null,
          })
          .where(eq(redemptions.id, redemption.id))
          .returning();

        return {
          redemption: updatedRedemption,
          reward: updatedReward,
          profile: updatedProfile,
        };
      });

      return serializeRedemption(
        result.redemption,
        result.reward,
        app.config.publicBaseUrl,
        result.profile,
      );
    },
  );
};
