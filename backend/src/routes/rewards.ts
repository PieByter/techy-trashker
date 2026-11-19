import { and, desc, eq, ilike, or, sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  pointTransactions,
  profiles,
  redemptions,
  rewards,
} from '../db/schema';
import { requireProfile } from '../lib/auth-helpers';
import { ApiError } from '../lib/errors';
import { paginationMeta, paginationOffset } from '../lib/pagination';
import {
  serializeProfile,
  serializeRedemption,
  serializeReward,
} from '../lib/serializers';
import {
  paginationQuerySchema,
  uuidParamSchema,
} from '../lib/validation';
import {
  commonErrorResponses,
  paginatedSchema,
  redeemResponseSchema,
  redemptionSchema,
  rewardSchema,
} from '../schemas';

const rewardListQuerySchema = paginationQuerySchema.extend({
  q: z.string().trim().max(120).optional(),
});

const redemptionListQuerySchema = paginationQuerySchema.extend({
  status: z.enum(['pending', 'fulfilled', 'cancelled']).optional(),
});

export const rewardRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/rewards',
    {
      preHandler: [app.optionalAuth],
      schema: {
        tags: ['Rewards'],
        summary: 'Katalog reward aktif',
        security: [],
        querystring: rewardListQuerySchema,
        response: {
          200: paginatedSchema(rewardSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const { page, limit, q } = request.query;
      const filters = [eq(rewards.isActive, true)];

      if (q) {
        const search = or(
          ilike(rewards.title, `%${q}%`),
          ilike(rewards.description, `%${q}%`),
        );
        if (search) filters.push(search);
      }

      const where = and(...filters);
      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(rewards)
        .where(where);

      const rows = await app.db
        .select()
        .from(rewards)
        .where(where)
        .orderBy(desc(rewards.pointsCost))
        .limit(limit)
        .offset(paginationOffset(page, limit));

      const profile = request.profile;

      return {
        data: rows.map((reward) =>
          serializeReward(
            reward,
            app.config.publicBaseUrl,
            profile ? profile.points >= reward.pointsCost && reward.stock > 0 : false,
          ),
        ),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
      };
    },
  );

  app.get(
    '/rewards/:id',
    {
      preHandler: [app.optionalAuth],
      schema: {
        tags: ['Rewards'],
        summary: 'Detail reward',
        security: [],
        params: uuidParamSchema,
        response: {
          200: rewardSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const [reward] = await app.db
        .select()
        .from(rewards)
        .where(eq(rewards.id, request.params.id))
        .limit(1);

      if (!reward || !reward.isActive) {
        throw new ApiError(404, 'REWARD_NOT_FOUND', 'Reward tidak ditemukan.');
      }

      const profile = request.profile;

      return serializeReward(
        reward,
        app.config.publicBaseUrl,
        profile ? profile.points >= reward.pointsCost && reward.stock > 0 : false,
      );
    },
  );

  app.post(
    '/rewards/:id/redeem',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Rewards'],
        summary: 'Tukar poin dengan reward',
        description:
          'Poin langsung dipotong dan stok berkurang. Redemption berstatus pending ' +
          'sampai dipenuhi admin.',
        security: [{ bearerAuth: [] }],
        params: uuidParamSchema,
        response: {
          200: redeemResponseSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);

      const result = await app.db.transaction(async (tx) => {
        const [reward] = await tx
          .select()
          .from(rewards)
          .where(eq(rewards.id, request.params.id))
          .limit(1)
          .for('update');

        if (!reward || !reward.isActive) {
          throw new ApiError(
            404,
            'REWARD_NOT_FOUND',
            'Reward tidak ditemukan.',
          );
        }

        if (reward.stock <= 0) {
          throw ApiError.conflict(
            'Stok reward sudah habis.',
            'REWARD_OUT_OF_STOCK',
          );
        }

        const [lockedProfile] = await tx
          .select()
          .from(profiles)
          .where(eq(profiles.id, profile.id))
          .limit(1)
          .for('update');

        if (!lockedProfile) {
          throw ApiError.unauthorized();
        }

        if (lockedProfile.points < reward.pointsCost) {
          throw ApiError.conflict(
            `Poin belum cukup. Butuh ${reward.pointsCost} poin, kamu punya ${lockedProfile.points}.`,
            'INSUFFICIENT_POINTS',
          );
        }

        const now = new Date();

        const [updatedReward] = await tx
          .update(rewards)
          .set({ stock: reward.stock - 1, updatedAt: now })
          .where(eq(rewards.id, reward.id))
          .returning();

        const [updatedProfile] = await tx
          .update(profiles)
          .set({
            points: lockedProfile.points - reward.pointsCost,
            updatedAt: now,
          })
          .where(eq(profiles.id, lockedProfile.id))
          .returning();

        const [redemption] = await tx
          .insert(redemptions)
          .values({
            userId: lockedProfile.id,
            rewardId: reward.id,
            pointsSpent: reward.pointsCost,
            status: 'pending',
          })
          .returning();

        await tx.insert(pointTransactions).values({
          userId: lockedProfile.id,
          amount: -reward.pointsCost,
          type: 'redemption',
          description: `Tukar poin: ${reward.title}`,
          redemptionId: redemption.id,
        });

        return {
          redemption,
          reward: updatedReward,
          profile: updatedProfile,
        };
      });

      return {
        redemption: serializeRedemption(
          result.redemption,
          result.reward,
          app.config.publicBaseUrl,
        ),
        reward: serializeReward(
          result.reward,
          app.config.publicBaseUrl,
          false,
        ),
        user: serializeProfile(result.profile, app.config.publicBaseUrl),
        pointsSpent: result.redemption.pointsSpent,
      };
    },
  );

  app.get(
    '/redemptions',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Rewards'],
        summary: 'Riwayat penukaran reward pengguna',
        security: [{ bearerAuth: [] }],
        querystring: redemptionListQuerySchema,
        response: {
          200: paginatedSchema(redemptionSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);
      const { page, limit, status } = request.query;
      const filters = [eq(redemptions.userId, profile.id)];

      if (status) filters.push(eq(redemptions.status, status));

      const where = and(...filters);
      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(redemptions)
        .where(where);

      const rows = await app.db
        .select({ redemption: redemptions, reward: rewards })
        .from(redemptions)
        .innerJoin(rewards, eq(redemptions.rewardId, rewards.id))
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
          ),
        ),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
      };
    },
  );

  app.get(
    '/redemptions/:id',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Rewards'],
        summary: 'Detail penukaran reward',
        security: [{ bearerAuth: [] }],
        params: uuidParamSchema,
        response: {
          200: redemptionSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);

      const [row] = await app.db
        .select({ redemption: redemptions, reward: rewards })
        .from(redemptions)
        .innerJoin(rewards, eq(redemptions.rewardId, rewards.id))
        .where(eq(redemptions.id, request.params.id))
        .limit(1);

      if (!row) {
        throw new ApiError(
          404,
          'REDEMPTION_NOT_FOUND',
          'Penukaran reward tidak ditemukan.',
        );
      }

      if (profile.role === 'user' && row.redemption.userId !== profile.id) {
        throw new ApiError(
          404,
          'REDEMPTION_NOT_FOUND',
          'Penukaran reward tidak ditemukan.',
        );
      }

      return serializeRedemption(
        row.redemption,
        row.reward,
        app.config.publicBaseUrl,
      );
    },
  );
};
