import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { ApiError } from '../lib/errors';
import { serializeProfile } from '../lib/serializers';
import {
  emailSchema,
  nameSchema,
  passwordSchema,
} from '../lib/validation';
import { authSessionSchema, commonErrorResponses } from '../schemas';
import { createProfileForAuthUser, ensureProfile } from '../services/profiles';

const credentialsSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
});

interface SessionPayload {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresAt: string;
}

function toResponse(
  session: SessionPayload,
  user: ReturnType<typeof serializeProfile>,
) {
  return {
    user,
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    tokenType: session.tokenType,
    expiresAt: session.expiresAt,
  };
}

export const authRoutes: FastifyPluginAsyncZod = async (app) => {
  app.post(
    '/auth/register',
    {
      schema: {
        tags: ['Auth'],
        summary: 'Daftar akun baru',
        description:
          'Membuat user di Supabase Auth (email langsung dikonfirmasi untuk MVP) ' +
          'lalu membuat profil Techy Trashker.',
        security: [],
        body: z.object({
          name: nameSchema,
          email: emailSchema,
          password: passwordSchema,
        }),
        response: {
          201: authSessionSchema,
          ...commonErrorResponses,
        },
      },
      config: {
        rateLimit: { max: 10, timeWindow: '1 minute' },
      },
    },
    async (request, reply) => {
      const session = await app.auth.register(request.body);

      let profile;
      try {
        profile = await createProfileForAuthUser(app, session.user, {
          name: request.body.name,
        });
      } catch (error) {
        await app.auth.deleteUser(session.user.id).catch(() => undefined);
        throw error;
      }

      reply.code(201);
      return toResponse(
        session,
        serializeProfile(profile, app.config.publicBaseUrl),
      );
    },
  );

  app.post(
    '/auth/login',
    {
      schema: {
        tags: ['Auth'],
        summary: 'Login dengan email dan password',
        security: [],
        body: credentialsSchema,
        response: {
          200: authSessionSchema,
          ...commonErrorResponses,
        },
      },
      config: {
        rateLimit: { max: 20, timeWindow: '1 minute' },
      },
    },
    async (request) => {
      const session = await app.auth.login(request.body);
      const profile = await ensureProfile(app, session.user);

      return toResponse(
        session,
        serializeProfile(profile, app.config.publicBaseUrl),
      );
    },
  );

  app.post(
    '/auth/refresh',
    {
      schema: {
        tags: ['Auth'],
        summary: 'Perbarui access token dengan refresh token',
        security: [],
        body: z.object({
          refreshToken: z.string().min(10, 'Refresh token wajib diisi.'),
        }),
        response: {
          200: authSessionSchema,
          ...commonErrorResponses,
        },
      },
      config: {
        rateLimit: { max: 60, timeWindow: '1 minute' },
      },
    },
    async (request) => {
      const session = await app.auth.refresh(request.body.refreshToken);
      const profile = await ensureProfile(app, session.user);

      return toResponse(
        session,
        serializeProfile(profile, app.config.publicBaseUrl),
      );
    },
  );

  app.post(
    '/auth/logout',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['Auth'],
        summary: 'Logout dan cabut sesi Supabase',
        security: [{ bearerAuth: [] }],
        response: {
          204: z.null(),
          ...commonErrorResponses,
        },
      },
    },
    async (request, reply) => {
      const header = request.headers.authorization ?? '';
      const token = header.replace(/^Bearer\s+/i, '').trim();

      if (!token) {
        throw ApiError.unauthorized();
      }

      await app.auth.logout(token);
      return reply.code(204).send(null);
    },
  );
};
