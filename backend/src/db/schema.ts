import {
  boolean,
  doublePrecision,
  index,
  integer,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';

export const userRoleEnum = pgEnum('user_role', ['user', 'officer', 'admin']);
export const depositMethodEnum = pgEnum('deposit_method', ['dropoff', 'pickup']);
export const depositStatusEnum = pgEnum('deposit_status', [
  'scheduled',
  'processing',
  'completed',
  'cancelled',
]);
export const redemptionStatusEnum = pgEnum('redemption_status', [
  'pending',
  'fulfilled',
  'cancelled',
]);
export const pointTransactionTypeEnum = pgEnum('point_transaction_type', [
  'deposit',
  'redemption',
  'bonus',
  'adjustment',
]);

const createdAtColumn = () =>
  timestamp('created_at', { withTimezone: true }).notNull().defaultNow();
const updatedAtColumn = () =>
  timestamp('updated_at', { withTimezone: true }).notNull().defaultNow();

export const profiles = pgTable(
  'profiles',
  {
    id: uuid('id').primaryKey(),
    memberCode: text('member_code').notNull().unique(),
    name: text('name').notNull(),
    email: text('email').notNull().unique(),
    role: userRoleEnum('role').notNull().default('user'),
    points: integer('points').notNull().default(0),
    totalWeightKg: doublePrecision('total_weight_kg').notNull().default(0),
    avatarUrl: text('avatar_url'),
    createdAt: createdAtColumn(),
    updatedAt: updatedAtColumn(),
  },
  (table) => [
    index('profiles_points_idx').on(table.points),
    index('profiles_role_idx').on(table.role),
  ],
);

export const news = pgTable(
  'news',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    title: text('title').notNull(),
    slug: text('slug').notNull().unique(),
    category: text('category').notNull(),
    summary: text('summary').notNull(),
    content: text('content').notNull(),
    imageUrl: text('image_url'),
    publishedAt: timestamp('published_at', { withTimezone: true }).notNull(),
    createdAt: createdAtColumn(),
  },
  (table) => [index('news_published_at_idx').on(table.publishedAt)],
);

export const wasteBanks = pgTable(
  'waste_banks',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: text('name').notNull(),
    slug: text('slug').notNull().unique(),
    address: text('address').notNull(),
    phone: text('phone'),
    latitude: doublePrecision('latitude').notNull(),
    longitude: doublePrecision('longitude').notNull(),
    rating: doublePrecision('rating').notNull().default(0),
    isOpen: boolean('is_open').notNull().default(true),
    openHours: text('open_hours').notNull().default('08.00 - 16.00'),
    mapX: doublePrecision('map_x').notNull().default(0.5),
    mapY: doublePrecision('map_y').notNull().default(0.5),
    createdAt: createdAtColumn(),
    updatedAt: updatedAtColumn(),
  },
  (table) => [index('waste_banks_name_idx').on(table.name)],
);

export const deposits = pgTable(
  'deposits',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: text('code').notNull().unique(),
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    wasteBankId: uuid('waste_bank_id').references(() => wasteBanks.id, {
      onDelete: 'set null',
    }),
    method: depositMethodEnum('method').notNull(),
    status: depositStatusEnum('status').notNull().default('processing'),
    material: text('material').notNull(),
    category: text('category').notNull(),
    weightKg: doublePrecision('weight_kg').notNull().default(0),
    points: integer('points').notNull().default(0),
    address: text('address'),
    scheduledAt: timestamp('scheduled_at', { withTimezone: true }),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    notes: text('notes'),
    createdAt: createdAtColumn(),
    updatedAt: updatedAtColumn(),
  },
  (table) => [
    index('deposits_user_created_idx').on(table.userId, table.createdAt),
    index('deposits_status_idx').on(table.status),
    index('deposits_waste_bank_idx').on(table.wasteBankId),
  ],
);

export const depositItems = pgTable(
  'deposit_items',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    depositId: uuid('deposit_id')
      .notNull()
      .references(() => deposits.id, { onDelete: 'cascade' }),
    material: text('material').notNull(),
    category: text('category').notNull(),
    weightKg: doublePrecision('weight_kg').notNull(),
    points: integer('points').notNull(),
    createdAt: createdAtColumn(),
  },
  (table) => [index('deposit_items_deposit_idx').on(table.depositId)],
);

export const rewards = pgTable(
  'rewards',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    slug: text('slug').notNull().unique(),
    title: text('title').notNull(),
    description: text('description').notNull(),
    pointsCost: integer('points_cost').notNull(),
    stock: integer('stock').notNull().default(0),
    imageUrl: text('image_url'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: createdAtColumn(),
    updatedAt: updatedAtColumn(),
  },
  (table) => [index('rewards_active_idx').on(table.isActive)],
);

export const redemptions = pgTable(
  'redemptions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    rewardId: uuid('reward_id')
      .notNull()
      .references(() => rewards.id, { onDelete: 'restrict' }),
    pointsSpent: integer('points_spent').notNull(),
    status: redemptionStatusEnum('status').notNull().default('pending'),
    createdAt: createdAtColumn(),
    fulfilledAt: timestamp('fulfilled_at', { withTimezone: true }),
  },
  (table) => [
    index('redemptions_user_created_idx').on(table.userId, table.createdAt),
    index('redemptions_status_idx').on(table.status),
  ],
);

export const pointTransactions = pgTable(
  'point_transactions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    amount: integer('amount').notNull(),
    type: pointTransactionTypeEnum('type').notNull(),
    description: text('description').notNull(),
    depositId: uuid('deposit_id').references(() => deposits.id, {
      onDelete: 'set null',
    }),
    redemptionId: uuid('redemption_id').references(() => redemptions.id, {
      onDelete: 'set null',
    }),
    createdAt: createdAtColumn(),
  },
  (table) => [
    index('point_transactions_user_created_idx').on(
      table.userId,
      table.createdAt,
    ),
  ],
);

export const qrSessions = pgTable(
  'qr_sessions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    tokenHash: text('token_hash').notNull().unique(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    usedAt: timestamp('used_at', { withTimezone: true }),
    createdAt: createdAtColumn(),
  },
  (table) => [
    index('qr_sessions_user_idx').on(table.userId),
    index('qr_sessions_expires_idx').on(table.expiresAt),
  ],
);

export type Profile = typeof profiles.$inferSelect;
export type NewsItem = typeof news.$inferSelect;
export type WasteBank = typeof wasteBanks.$inferSelect;
export type Deposit = typeof deposits.$inferSelect;
export type DepositItem = typeof depositItems.$inferSelect;
export type Reward = typeof rewards.$inferSelect;
export type Redemption = typeof redemptions.$inferSelect;
export type PointTransaction = typeof pointTransactions.$inferSelect;
export type QrSession = typeof qrSessions.$inferSelect;
export type UserRole = (typeof userRoleEnum.enumValues)[number];
export type DepositMethod = (typeof depositMethodEnum.enumValues)[number];
export type DepositStatus = (typeof depositStatusEnum.enumValues)[number];
export type RedemptionStatus = (typeof redemptionStatusEnum.enumValues)[number];
