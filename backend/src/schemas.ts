import { z } from 'zod';

export const errorResponseSchema = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.unknown().optional(),
  }),
});

export const commonErrorResponses = {
  400: errorResponseSchema,
  401: errorResponseSchema,
  403: errorResponseSchema,
  404: errorResponseSchema,
  409: errorResponseSchema,
  410: errorResponseSchema,
  429: errorResponseSchema,
  500: errorResponseSchema,
} as const;

export const profileStatsSchema = z.object({
  deposits: z.number().int(),
  completedDeposits: z.number().int(),
  rewardsRedeemed: z.number().int(),
});

export const profileSchema = z.object({
  id: z.string().uuid(),
  memberCode: z.string(),
  name: z.string(),
  email: z.string(),
  role: z.enum(['user', 'officer', 'admin']),
  avatarUrl: z.string().nullable(),
  points: z.number().int(),
  totalWeightKg: z.number(),
  level: z.string(),
  nextLevel: z.string().nullable(),
  nextLevelPoints: z.number().int(),
  levelProgress: z.number(),
  stats: profileStatsSchema.optional(),
  createdAt: z.string(),
});

export const memberSchema = z.object({
  id: z.string().uuid(),
  memberCode: z.string(),
  name: z.string(),
  avatarUrl: z.string().nullable(),
  points: z.number().int(),
  level: z.string(),
});

export const authSessionSchema = z.object({
  user: profileSchema,
  accessToken: z.string(),
  refreshToken: z.string(),
  tokenType: z.string(),
  expiresAt: z.string(),
});

export const newsSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  slug: z.string(),
  category: z.string(),
  summary: z.string(),
  content: z.string().optional(),
  imageUrl: z.string().nullable(),
  publishedAt: z.string(),
  date: z.string(),
});

export const wasteBankSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  slug: z.string(),
  address: z.string(),
  phone: z.string().nullable(),
  latitude: z.number(),
  longitude: z.number(),
  distanceKm: z.number(),
  rating: z.number(),
  isOpen: z.boolean(),
  openHours: z.string(),
  mapX: z.number(),
  mapY: z.number(),
});

export const depositItemSchema = z.object({
  id: z.string().uuid(),
  material: z.string(),
  category: z.string(),
  weightKg: z.number(),
  points: z.number().int(),
});

export const depositSchema = z.object({
  id: z.string().uuid(),
  code: z.string(),
  method: z.enum(['dropoff', 'pickup']),
  status: z.enum(['scheduled', 'processing', 'completed', 'cancelled']),
  material: z.string(),
  category: z.string(),
  weightKg: z.number(),
  points: z.number().int(),
  wasteBankId: z.string().uuid().nullable(),
  wasteBankName: z.string().nullable(),
  address: z.string().nullable(),
  scheduledAt: z.string().nullable(),
  completedAt: z.string().nullable(),
  notes: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
  items: z.array(depositItemSchema),
});

export const rewardSchema = z.object({
  id: z.string().uuid(),
  slug: z.string(),
  title: z.string(),
  description: z.string(),
  pointsCost: z.number().int(),
  stock: z.number().int(),
  imageUrl: z.string().nullable(),
  isActive: z.boolean(),
  canRedeem: z.boolean(),
});

export const redemptionSchema = z.object({
  id: z.string().uuid(),
  status: z.enum(['pending', 'fulfilled', 'cancelled']),
  pointsSpent: z.number().int(),
  createdAt: z.string(),
  fulfilledAt: z.string().nullable(),
  reward: rewardSchema,
  user: memberSchema.optional(),
});

export const pointTransactionSchema = z.object({
  id: z.string().uuid(),
  amount: z.number().int(),
  type: z.enum(['deposit', 'redemption', 'bonus', 'adjustment']),
  description: z.string(),
  depositId: z.string().uuid().nullable(),
  redemptionId: z.string().uuid().nullable(),
  createdAt: z.string(),
});

export const paginationMetaSchema = z.object({
  page: z.number().int(),
  limit: z.number().int(),
  total: z.number().int(),
  totalPages: z.number().int(),
  hasNext: z.boolean(),
  hasPrev: z.boolean(),
});

export function paginatedSchema<T extends z.ZodType>(item: T) {
  return z.object({
    data: z.array(item),
    meta: paginationMetaSchema,
  });
}

export const depositSummarySchema = z.object({
  total: z.number().int(),
  completed: z.number().int(),
  scheduled: z.number().int(),
  processing: z.number().int(),
  cancelled: z.number().int(),
  totalWeightKg: z.number(),
  totalPoints: z.number().int(),
  byMethod: z.object({
    dropoff: z.number().int(),
    pickup: z.number().int(),
  }),
});

export const completeDepositResponseSchema = z.object({
  deposit: depositSchema,
  member: memberSchema,
  pointsEarned: z.number().int(),
});

export const officerDepositSchema = depositSchema.extend({
  member: memberSchema,
});


export const qrSessionSchema = z.object({
  token: z.string(),
  qrPayload: z.string(),
  expiresAt: z.string(),
  expiresInSeconds: z.number().int(),
  member: memberSchema,
});

export const qrScanResponseSchema = z.object({
  deposit: depositSchema,
  member: memberSchema,
  pointsEarned: z.number().int(),
});

export const redeemResponseSchema = z.object({
  redemption: redemptionSchema,
  reward: rewardSchema,
  user: profileSchema,
  pointsSpent: z.number().int(),
});

export const pointHistoryResponseSchema = z.object({
  data: z.array(pointTransactionSchema),
  meta: paginationMetaSchema,
  summary: z.object({
    earned: z.number().int(),
    spent: z.number().int(),
    balance: z.number().int(),
  }),
});

export const leaderboardEntrySchema = z.object({
  rank: z.number().int(),
  user: memberSchema,
  isCurrentUser: z.boolean(),
});

export const leaderboardResponseSchema = z.object({
  data: z.array(leaderboardEntrySchema),
  meta: z.object({
    limit: z.number().int(),
    totalParticipants: z.number().int(),
  }),
  currentUser: leaderboardEntrySchema.nullable(),
});

export const healthResponseSchema = z.object({
  status: z.enum(['ok', 'degraded']),
  database: z.enum(['ok', 'error']),
  uptime: z.number(),
  timestamp: z.string(),
  version: z.string(),
});
