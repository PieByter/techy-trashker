import { eq } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { profiles } from '../db/schema';
import { nameSchema } from '../lib/validation';
import { serializeProfile } from '../lib/serializers';
import {
  commonErrorResponses,
  profileSchema,
} from '../schemas';
import { loadProfileStats } from '../services/profiles';
import { requireProfile } from '../lib/auth-helpers';

export const meRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/me',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Profile'],
        summary: 'Profil pengguna yang sedang login',
        security: [{ bearerAuth: [] }],
        response: {
          200: profileSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);
      const stats = await loadProfileStats(app.db, profile.id);

      return serializeProfile(profile, app.config.publicBaseUrl, stats);
    },
  );

  app.patch(
    '/me',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Profile'],
        summary: 'Perbarui nama atau avatar',
        security: [{ bearerAuth: [] }],
        body: z
          .object({
            name: nameSchema.optional(),
            avatarUrl: z.string().url('URL avatar tidak valid.').max(1000).nullable().optional(),
          })
          .refine(
            (value) => value.name !== undefined || value.avatarUrl !== undefined,
            { message: 'Minimal satu field harus diisi.' },
          ),
        response: {
          200: profileSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);
      const updates: {
        updatedAt: Date;
        name?: string;
        avatarUrl?: string | null;
      } = { updatedAt: new Date() };

      if (request.body.name !== undefined) updates.name = request.body.name;
      if (request.body.avatarUrl !== undefined) {
        updates.avatarUrl = request.body.avatarUrl;
      }

      const [updated] = await app.db
        .update(profiles)
        .set(updates)
        .where(eq(profiles.id, profile.id))
        .returning();

      const stats = await loadProfileStats(app.db, updated.id);
      return serializeProfile(updated, app.config.publicBaseUrl, stats);
    },
  );

  app.get(
    '/me/stats',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Profile'],
        summary: 'Statistik ringkas pengguna',
        security: [{ bearerAuth: [] }],
        response: {
          200: z.object({
            points: z.number().int(),
            totalWeightKg: z.number(),
            deposits: z.number().int(),
            completedDeposits: z.number().int(),
            rewardsRedeemed: z.number().int(),
          }),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const profile = requireProfile(request);
      const stats = await loadProfileStats(app.db, profile.id);

      return {
        points: profile.points,
        totalWeightKg: profile.totalWeightKg,
        ...stats,
      };
    },
  );
};
