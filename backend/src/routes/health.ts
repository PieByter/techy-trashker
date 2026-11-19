import { sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import {
  commonErrorResponses,
  healthResponseSchema,
} from '../schemas';

export const healthRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/health',
    {
      schema: {
        tags: ['Health'],
        summary: 'Health check layanan dan database',
        security: [],
        response: {
          200: healthResponseSchema,
          503: healthResponseSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (_request, reply) => {
      let databaseOk = true;

      try {
        await app.db.execute(sql`select 1`);
      } catch {
        databaseOk = false;
        reply.code(503);
      }

      return {
        status: databaseOk ? ('ok' as const) : ('degraded' as const),
        database: databaseOk ? ('ok' as const) : ('error' as const),
        uptime: Math.round(process.uptime()),
        timestamp: new Date().toISOString(),
        version: '0.1.0',
      };
    },
  );
};
