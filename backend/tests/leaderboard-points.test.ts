import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { profiles } from '../src/db/schema';
import {
  bearer,
  createTestContext,
  loginAs,
  registerUser,
  type TestContext,
} from './helpers/app';

let ctx: TestContext;
let memberToken: string;

beforeAll(async () => {
  ctx = await createTestContext();
  memberToken = (await loginAs(ctx, 'andhika@techytrashker.id')).accessToken;
});

afterAll(async () => {
  await ctx.app.close();
});

describe('points & leaderboard', () => {
  it('returns the seeded point ledger with a summary', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/points/history',
      headers: bearer(memberToken),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().data).toHaveLength(5);
    expect(response.json().meta).toMatchObject({
      total: 5,
      page: 1,
      limit: 20,
    });
    expect(response.json().summary).toEqual({
      earned: 147,
      spent: 0,
      balance: 147,
    });
  });

  it('paginates point history', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/points/history?page=2&limit=2',
      headers: bearer(memberToken),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().data).toHaveLength(2);
    expect(response.json().meta).toMatchObject({
      page: 2,
      totalPages: 3,
      hasNext: true,
      hasPrev: true,
    });
  });

  it('requires authentication for point history', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/points/history',
    });
    expect(response.statusCode).toBe(401);
  });

  it('returns an anonymous leaderboard without personal data', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard',
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().data).toHaveLength(1);
    expect(response.json().data[0]).toMatchObject({
      rank: 1,
      isCurrentUser: false,
      user: {
        name: 'Andhika Pratama',
        points: 147,
        level: 'Eco Warrior',
      },
    });
    expect(response.json().currentUser).toBeNull();
    expect(response.json().meta).toMatchObject({
      limit: 10,
      totalParticipants: 1,
    });
  });

  it('highlights the current user and excludes staff from the ranking', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard',
      headers: bearer(memberToken),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().data[0].isCurrentUser).toBe(true);
    expect(response.json().currentUser).toMatchObject({
      rank: 1,
      isCurrentUser: true,
      user: { name: 'Andhika Pratama' },
    });
    expect(
      response
        .json()
        .data.some((entry: { user: { name: string } }) =>
          ['Petugas Bank Sampah', 'Admin Techy Trashker'].includes(
            entry.user.name,
          ),
        ),
    ).toBe(false);
  });

  it('ranks new members and reports a current user outside the page', async () => {
    const high = await registerUser(ctx, {
      name: 'Leader High',
      email: 'leader-high@example.com',
    });
    const zero = await registerUser(ctx, {
      name: 'Leader Zero',
      email: 'leader-zero@example.com',
    });

    await ctx.db
      .update(profiles)
      .set({ points: 500 })
      .where(eq(profiles.id, high.user.id));

    const ranking = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard?limit=10',
      headers: bearer(zero.accessToken),
    });

    expect(ranking.statusCode).toBe(200);
    expect(ranking.json().meta.totalParticipants).toBe(3);
    expect(ranking.json().data.map((entry: { rank: number }) => entry.rank)).toEqual([
      1, 2, 3,
    ]);
    expect(ranking.json().data[0].user.name).toBe('Leader High');
    expect(ranking.json().data[1].user.name).toBe('Andhika Pratama');
    expect(ranking.json().data[2].user.name).toBe('Leader Zero');
    expect(ranking.json().currentUser).toMatchObject({
      rank: 3,
      isCurrentUser: true,
    });

    const topOnly = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard?limit=1',
      headers: bearer(memberToken),
    });

    expect(topOnly.json().data).toHaveLength(1);
    expect(topOnly.json().data[0].user.name).toBe('Leader High');
    expect(topOnly.json().currentUser).toMatchObject({
      rank: 2,
      isCurrentUser: true,
      user: { name: 'Andhika Pratama' },
    });
  });

  it('returns profile stats summary', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me/stats',
      headers: bearer(memberToken),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      points: 147,
      totalWeightKg: 12.4,
      deposits: 6,
      completedDeposits: 5,
      rewardsRedeemed: 0,
    });
  });
});
