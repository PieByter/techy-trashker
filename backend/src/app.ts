import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import fastifyStatic from '@fastify/static';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import Fastify, {
  type FastifyInstance,
  type FastifyServerOptions,
} from 'fastify';
import {
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
} from 'fastify-type-provider-zod';
import path from 'node:path';
import type { AuthProvider } from './auth/types';
import type { Config } from './config';
import type { AppDatabase } from './db';
import { errorHandler } from './plugins/error-handler';
import {
  authenticate,
  optionalAuth,
  requireRole,
} from './plugins/auth';
import { apiRoutes } from './routes';
import { healthRoutes } from './routes/health';

export interface BuildAppOptions {
  config: Config;
  db: AppDatabase;
  auth: AuthProvider;
  logger?: FastifyServerOptions['logger'];
  onClose?: () => Promise<void> | void;
}

export async function buildApp(
  options: BuildAppOptions,
): Promise<FastifyInstance> {
  const { config } = options;

  const app = Fastify({
    logger: options.logger ?? false,
    trustProxy: config.trustProxy,
    bodyLimit: 1024 * 1024,
  });

  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  app.decorate('config', config);
  app.decorate('db', options.db);
  app.decorate('auth', options.auth);
  app.decorateRequest('profile', null);
  app.decorateRequest('authUser', null);
  app.decorate('authenticate', authenticate);
  app.decorate('optionalAuth', optionalAuth);
  app.decorate('requireRole', requireRole);

  app.setErrorHandler(errorHandler);
  app.setNotFoundHandler((request, reply) => {
    reply.code(404).send({
      error: {
        code: 'NOT_FOUND',
        message: `Route ${request.method} ${request.url} tidak ditemukan.`,
      },
    });
  });

  await app.register(cors, {
    origin:
      config.corsOrigin === '*'
        ? '*'
        : config.corsOrigin.split(',').map((origin) => origin.trim()),
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  });

  await app.register(helmet, {
    contentSecurityPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  });

  await app.register(rateLimit, {
    max: config.rateLimitMax,
    timeWindow: '1 minute',
    errorResponseBuilder: (_request, context) => ({
      error: {
        code: 'RATE_LIMITED',
        message: `Terlalu banyak permintaan. Coba lagi dalam ${context.after}.`,
      },
    }),
  });

  await app.register(swagger, {
    openapi: {
      openapi: '3.0.3',
      info: {
        title: 'Techy Trashker API',
        description:
          'API MVP Techy Trashker — bank sampah digital. Autentikasi memakai Supabase Auth ' +
          '(Bearer access token), data memakai Supabase Postgres melalui Drizzle ORM.',
        version: '0.1.0',
      },
      servers: [{ url: config.publicBaseUrl }],
      tags: [
        { name: 'Auth', description: 'Registrasi, login, refresh, logout.' },
        { name: 'Profile', description: 'Profil, poin, level, dan statistik.' },
        { name: 'News', description: 'Berita dan edukasi lingkungan.' },
        {
          name: 'Deposits',
          description: 'Setoran sampah, penjemputan, dan penyelesaian oleh petugas.',
        },
        { name: 'Officer', description: 'Antrean kerja petugas bank sampah.' },
        { name: 'QR', description: 'QR setor berumur pendek dan scan petugas.' },
        { name: 'Waste Banks', description: 'Daftar bank sampah terdekat.' },
        { name: 'Rewards', description: 'Katalog reward dan penukaran poin.' },
        { name: 'Leaderboard', description: 'Peringkat pengguna berdasarkan poin.' },
        { name: 'Admin', description: 'Pengelolaan reward dan redemption.' },
        { name: 'Health', description: 'Status layanan.' },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            description: 'Supabase Auth access token.',
          },
        },
      },
    },
    transform: jsonSchemaTransform,
  });

  await app.register(swaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: true,
      persistAuthorization: true,
    },
    staticCSP: false,
  });

  await app.register(fastifyStatic, {
    root: path.resolve(process.cwd(), 'public'),
    prefix: '/static/',
    index: false,
    cacheControl: true,
    maxAge: '1h',
  });

  app.get('/', async () => ({
    name: 'techy-trashker-api',
    version: '0.1.0',
    docs: '/docs',
    openapi: '/docs/json',
    health: '/health',
    api: '/api/v1',
  }));

  await app.register(healthRoutes);
  await app.register(apiRoutes, { prefix: '/api/v1' });

  if (options.onClose) {
    app.addHook('onClose', options.onClose);
  }

  return app;
}
