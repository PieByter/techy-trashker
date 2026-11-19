import { and, desc, eq, ilike, or, sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { news } from '../db/schema';
import { ApiError } from '../lib/errors';
import { paginationMeta, paginationOffset } from '../lib/pagination';
import { serializeNews } from '../lib/serializers';
import {
  paginationQuerySchema,
  uuidParamSchema,
} from '../lib/validation';
import {
  commonErrorResponses,
  newsSchema,
  paginatedSchema,
} from '../schemas';

const newsListQuerySchema = paginationQuerySchema.extend({
  category: z.string().trim().max(50).optional(),
  q: z.string().trim().max(120).optional(),
});

export const newsRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/news',
    {
      schema: {
        tags: ['News'],
        summary: 'Daftar berita',
        security: [],
        querystring: newsListQuerySchema,
        response: {
          200: paginatedSchema(newsSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const { page, limit, category, q } = request.query;
      const filters = [];

      if (category) filters.push(ilike(news.category, `%${category}%`));
      if (q) {
        const search = or(
          ilike(news.title, `%${q}%`),
          ilike(news.summary, `%${q}%`),
        );
        if (search) filters.push(search);
      }

      const where = filters.length > 0 ? and(...filters) : undefined;

      const [countRow] = await app.db
        .select({ total: sql<number>`count(*)::int` })
        .from(news)
        .where(where);

      const rows = await app.db
        .select()
        .from(news)
        .where(where)
        .orderBy(desc(news.publishedAt))
        .limit(limit)
        .offset(paginationOffset(page, limit));

      return {
        data: rows.map((item) =>
          serializeNews(item, app.config.publicBaseUrl, false),
        ),
        meta: paginationMeta(page, limit, Number(countRow?.total ?? 0)),
      };
    },
  );

  app.get(
    '/news/:id',
    {
      schema: {
        tags: ['News'],
        summary: 'Detail berita',
        security: [],
        params: uuidParamSchema,
        response: {
          200: newsSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const [item] = await app.db
        .select()
        .from(news)
        .where(eq(news.id, request.params.id))
        .limit(1);

      if (!item) {
        throw new ApiError(404, 'NEWS_NOT_FOUND', 'Berita tidak ditemukan.');
      }

      return serializeNews(item, app.config.publicBaseUrl, true);
    },
  );
};
