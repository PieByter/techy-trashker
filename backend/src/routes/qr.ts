import { eq, lt, and } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  deposits,
  profiles,
  qrSessions,
  wasteBanks,
  type Profile,
  type QrSession,
} from '../db/schema';
import { requireProfile } from '../lib/auth-helpers';
import { ApiError } from '../lib/errors';
import {
  generateDepositCode,
  generateQrToken,
  hashToken,
} from '../lib/ids';
import {
  serializeDeposit,
  serializeMember,
  serializeQrSession,
} from '../lib/serializers';
import {
  wasteItemsSchema,
} from '../lib/validation';
import {
  commonErrorResponses,
  qrScanResponseSchema,
  qrSessionSchema,
} from '../schemas';
import {
  awardDepositPoints,
  computeDepositWaste,
  insertDepositItems,
  withUniqueRetry,
} from '../services/deposits';

const scanBodySchema = z
  .object({
    token: z.string().min(10).optional(),
    memberCode: z.string().trim().min(5).max(40).optional(),
    wasteBankId: z.string().uuid('ID bank sampah tidak valid.').optional(),
    items: wasteItemsSchema,
    notes: z.string().trim().max(500).optional(),
  })
  .superRefine((value, ctx) => {
    const hasToken = Boolean(value.token);
    const hasMemberCode = Boolean(value.memberCode);

    if (hasToken === hasMemberCode) {
      ctx.addIssue({
        code: 'custom',
        path: ['token'],
        message: 'Kirim token QR atau memberCode (pilih salah satu).',
      });
    }
  });

async function findBankName(
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

export const qrRoutes: FastifyPluginAsyncZod = async (app) => {
  app.post(
    '/qr/session',
    {
      preHandler: [app.authenticate],
      schema: {
        tags: ['QR'],
        summary: 'Buat QR setor berumur pendek',
        description:
          'QR ini ditunjukkan ke petugas. Token hanya disimpan dalam bentuk hash ' +
          'dan tidak bisa dipakai dua kali.',
        security: [{ bearerAuth: [] }],
        response: {
          201: qrSessionSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request, reply) => {
      const profile = requireProfile(request);
      const token = generateQrToken();
      const expiresInSeconds = app.config.qrTtlSeconds;
      const expiresAt = new Date(Date.now() + expiresInSeconds * 1000);

      // Bersihkan sesi kedaluwarsa milik user ini (best effort).
      await app.db
        .delete(qrSessions)
        .where(
          and(
            eq(qrSessions.userId, profile.id),
            lt(qrSessions.expiresAt, new Date()),
          ),
        );

      await app.db.insert(qrSessions).values({
        userId: profile.id,
        tokenHash: hashToken(token),
        expiresAt,
      });

      reply.code(201);
      return serializeQrSession({
        token,
        qrPayload: `techytrashker://deposit?token=${encodeURIComponent(token)}`,
        expiresAt,
        expiresInSeconds,
        profile,
        baseUrl: app.config.publicBaseUrl,
      });
    },
  );

  app.post(
    '/qr/scan',
    {
      preHandler: [app.authenticate, app.requireRole('officer', 'admin')],
      schema: {
        tags: ['QR'],
        summary: 'Petugas memindai QR dan mencatat setoran',
        description:
          'Menerima token QR (atau memberCode sebagai fallback manual), ' +
          'menghitung poin dari item aktual, dan langsung menyelesaikan setoran.',
        security: [{ bearerAuth: [] }],
        body: scanBodySchema,
        response: {
          200: qrScanResponseSchema,
          ...commonErrorResponses,
        },
      },
    },
    async (request) => {
      const body = request.body;
      const bankName = await findBankName(app, body.wasteBankId ?? null);

      const result = await withUniqueRetry(() =>
        app.db.transaction(async (tx) => {
          let profile: Profile | undefined;
          let session: QrSession | undefined;

          if (body.token) {
            const [qrSession] = await tx
              .select()
              .from(qrSessions)
              .where(eq(qrSessions.tokenHash, hashToken(body.token)))
              .limit(1)
              .for('update');

            if (!qrSession) {
              throw new ApiError(
                404,
                'INVALID_QR',
                'QR tidak dikenal. Minta pengguna membuat QR baru.',
              );
            }

            if (qrSession.usedAt) {
              throw ApiError.conflict(
                'QR ini sudah dipakai untuk setoran.',
                'QR_USED',
              );
            }

            if (qrSession.expiresAt.getTime() <= Date.now()) {
              throw new ApiError(
                410,
                'QR_EXPIRED',
                'QR sudah kedaluwarsa. Minta pengguna membuat QR baru.',
              );
            }

            const [member] = await tx
              .select()
              .from(profiles)
              .where(eq(profiles.id, qrSession.userId))
              .limit(1)
              .for('update');

            if (!member) {
              throw new ApiError(
                404,
                'MEMBER_NOT_FOUND',
                'Member pemilik QR tidak ditemukan.',
              );
            }

            profile = member;
            session = qrSession;
          } else if (body.memberCode) {
            const [member] = await tx
              .select()
              .from(profiles)
              .where(eq(profiles.memberCode, body.memberCode.trim().toUpperCase()))
              .limit(1)
              .for('update');

            if (!member) {
              throw new ApiError(
                404,
                'MEMBER_NOT_FOUND',
                'Member dengan kode tersebut tidak ditemukan.',
              );
            }

            profile = member;
          }

          if (!profile) {
            throw new ApiError(
              400,
              'INVALID_QR',
              'Token QR atau memberCode wajib dikirim.',
            );
          }

          const waste = computeDepositWaste(body.items);
          const now = new Date();

          const [deposit] = await tx
            .insert(deposits)
            .values({
              code: generateDepositCode(),
              userId: profile.id,
              wasteBankId: body.wasteBankId ?? null,
              method: 'dropoff',
              status: 'completed',
              material: waste.primaryMaterial,
              category: waste.primaryCategory,
              weightKg: waste.totalWeightKg,
              points: waste.totalPoints,
              completedAt: now,
              notes: body.notes ?? null,
            })
            .returning();

          const items = await insertDepositItems(tx, deposit.id, waste.items);
          const updatedProfile = await awardDepositPoints(tx, {
            profile,
            depositId: deposit.id,
            depositCode: deposit.code,
            points: waste.totalPoints,
            weightKg: waste.totalWeightKg,
          });

          if (session) {
            await tx
              .update(qrSessions)
              .set({ usedAt: now })
              .where(eq(qrSessions.id, session.id));
          }

          return { deposit, items, profile: updatedProfile };
        }),
      );

      return {
        deposit: serializeDeposit(result.deposit, result.items, bankName),
        member: serializeMember(result.profile, app.config.publicBaseUrl),
        pointsEarned: result.deposit.points,
      };
    },
  );
};
