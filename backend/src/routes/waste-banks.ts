import { and, eq, ilike, or } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { wasteBanks } from '../db/schema';
import {
  DEFAULT_CENTER,
  haversineKm,
  type Coordinate,
} from '../lib/distance';
import { ApiError } from '../lib/errors';
import { paginationMeta } from '../lib/pagination';
import { serializeWasteBank } from '../lib/serializers';
import {
  booleanQuerySchema,
  paginationQuerySchema,
  uuidParamSchema,
} from '../lib/validation';
import {
  commonErrorResponses,
  paginatedSchema,
  wasteBankSchema,
} from '../schemas';

const locationQuerySchema = z
  .object({
    lat: z.coerce.number().min(-90).max(90).optional(),
    lng: z.coerce.number().min(-180).max(180).optional(),
  })
  .refine((value) => (value.lat === undefined) === (value.lng === undefined), {
    message: 'lat dan lng harus dikirim bersamaan.',
    path: ['lat'],
  });

const wasteBankListQuerySchema = paginationQuerySchema
  .extend({
    q: z.string().trim().max(120).optional(),
    openOnly: booleanQuerySchema.optional(),
  })
  .and(locationQuerySchema);

function locationFrom(lat?: number, lng?: number): Coordinate {
  if (lat !== undefined && lng !== undefined) {
    return { latitude: lat, longitude: lng };
  }
  return DEFAULT_CENTER;
}

export const wasteBankRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    '/waste-banks',
    {
      schema: {
        tags: ['Waste Banks'],
        summary: 'Daftar bank sampah, diurutkan dari yang terdekat',
        description:
          'Kalau lat/lng tidak dikirim, jarak dihitung dari titik tengah Kota Medan.',
        security: [],
        querystring: wasteBankListQuerySchema,
        response: {
          200: paginatedSchema(wasteBankSchema),
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const { page, limit, q, openOnly, lat, lng } = request.query;
      const filters = [];

      if (openOnly) filters.push(eq(wasteBanks.isOpen, true));
      if (q) {
        const search = or(
          ilike(wasteBanks.name, `%${q}%`),
          ilike(wasteBanks.address, `%${q}%`),
        );
        if (search) filters.push(search);
      }

      const rows = await app.db
        .select()
        .from(wasteBanks)
        .where(filters.length > 0 ? and(...filters) : undefined);

      const center = locationFrom(lat, lng);
      const withDistance = rows
        .map((bank) => ({
          bank,
          distanceKm: haversineKm(center, {
            latitude: bank.latitude,
            longitude: bank.longitude,
          }),
        }))
        .sort((a, b) => a.distanceKm - b.distanceKm);

      const start = (page - 1) * limit;
      const pageRows = withDistance.slice(start, start + limit);

      return {
        data: pageRows.map(({ bank, distanceKm }) =>
          serializeWasteBank(bank, distanceKm),
        ),
        meta: paginationMeta(page, limit, withDistance.length),
      };
    },
  );

  app.get(
    '/waste-banks/:id',
    {
      schema: {
        tags: ['Waste Banks'],
        summary: 'Detail bank sampah',
        security: [],
        params: uuidParamSchema,
        querystring: locationQuerySchema,
        response: {
          200: wasteBankSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const [bank] = await app.db
        .select()
        .from(wasteBanks)
        .where(eq(wasteBanks.id, request.params.id))
        .limit(1);

      if (!bank) {
        throw new ApiError(
          404,
          'WASTE_BANK_NOT_FOUND',
          'Bank sampah tidak ditemukan.',
        );
      }

      const center = locationFrom(request.query.lat, request.query.lng);
      const distanceKm = haversineKm(center, {
        latitude: bank.latitude,
        longitude: bank.longitude,
      });

      return serializeWasteBank(bank, distanceKm);
    },
  );
};
