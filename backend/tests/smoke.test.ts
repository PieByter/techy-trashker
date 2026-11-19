import { sql } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  DEFAULT_SEED_USER_IDS,
  seedDatabase,
} from '../src/db/seed';
import {
  deposits,
  news,
  pointTransactions,
  rewards,
  wasteBanks,
} from '../src/db/schema';
import { bearer, createTestContext, type TestContext } from './helpers/app';

let ctx: TestContext;

beforeAll(async () => {
  ctx = await createTestContext();
});

afterAll(async () => {
  await ctx.app.close();
});

describe('smoke', () => {
  it('reports health', async () => {
    const response = await ctx.app.inject({ method: 'GET', url: '/health' });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      status: 'ok',
      database: 'ok',
    });
  });

  it('lists seeded news', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/news',
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.data).toHaveLength(3);
    expect(body.meta.total).toBe(3);
    expect(body.data[0].content).toBeUndefined();
  });

  it('logs in the demo member and reads profile', async () => {
    const login = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        email: 'andhika@techytrashker.id',
        password: 'rahasia123',
      },
    });

    expect(login.statusCode).toBe(200);
    const session = login.json();
    expect(session.user.points).toBe(147);

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(session.accessToken),
    });

    expect(me.statusCode).toBe(200);
    expect(me.json()).toMatchObject({
      name: 'Andhika Pratama',
      points: 147,
      totalWeightKg: 12.4,
      level: 'Eco Warrior',
      stats: {
        deposits: 6,
        completedDeposits: 5,
        rewardsRedeemed: 0,
      },
    });
  });

  it('returns deposit summary from seeded data', async () => {
    const login = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        email: 'andhika@techytrashker.id',
        password: 'rahasia123',
      },
    });
    const token = login.json().accessToken;

    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits/summary',
      headers: bearer(token),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      total: 6,
      completed: 5,
      scheduled: 1,
      totalWeightKg: 12.4,
      totalPoints: 147,
      byMethod: { dropoff: 3, pickup: 3 },
    });
  });

  it('can re-run the seed without duplicating data', async () => {
    await seedDatabase(ctx.db, { users: DEFAULT_SEED_USER_IDS });

    const [newsCount] = await ctx.db
      .select({ total: sql<number>`count(*)::int` })
      .from(news);
    const [bankCount] = await ctx.db
      .select({ total: sql<number>`count(*)::int` })
      .from(wasteBanks);
    const [rewardCount] = await ctx.db
      .select({ total: sql<number>`count(*)::int` })
      .from(rewards);
    const [depositCount] = await ctx.db
      .select({ total: sql<number>`count(*)::int` })
      .from(deposits);
    const [pointCount] = await ctx.db
      .select({ total: sql<number>`count(*)::int` })
      .from(pointTransactions);

    expect(Number(newsCount.total)).toBe(3);
    expect(Number(bankCount.total)).toBe(4);
    expect(Number(rewardCount.total)).toBe(5);
    expect(Number(depositCount.total)).toBe(6);
    expect(Number(pointCount.total)).toBe(5);
  });
});
