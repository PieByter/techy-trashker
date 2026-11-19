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
let adminToken: string;

beforeAll(async () => {
  ctx = await createTestContext();
  adminToken = (await loginAs(ctx, 'admin@techytrashker.id')).accessToken;
});

afterAll(async () => {
  await ctx.app.close();
});

async function rewardsBySlug(accessToken: string) {
  const response = await ctx.app.inject({
    method: 'GET',
    url: '/api/v1/rewards?limit=100',
    headers: bearer(accessToken),
  });

  return response.json().data as Array<{
    id: string;
    slug: string;
    title: string;
    pointsCost: number;
    stock: number;
    canRedeem: boolean;
    isActive: boolean;
  }>;
}

describe('rewards & redemptions', () => {
  it('shows the catalog and affordability for a new member', async () => {
    const member = await registerUser(ctx, {
      name: 'Reward Member',
      email: 'reward-user@example.com',
    });

    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/rewards',
      headers: bearer(member.accessToken),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().data).toHaveLength(5);
    expect(
      response.json().data.every((reward: { canRedeem: boolean }) => !reward.canRedeem),
    ).toBe(true);

    const anonymous = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/rewards',
    });
    expect(anonymous.statusCode).toBe(200);
  });

  it('rejects redemption when points are insufficient', async () => {
    const member = await registerUser(ctx, {
      name: 'Reward Poor',
      email: 'reward-poor@example.com',
    });
    const bibit = (await rewardsBySlug(member.accessToken)).find(
      (reward) => reward.slug === 'bibit-tanaman',
    )!;

    const response = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/rewards/${bibit.id}/redeem`,
      headers: bearer(member.accessToken),
    });

    expect(response.statusCode).toBe(409);
    expect(response.json().error.code).toBe('INSUFFICIENT_POINTS');
  });

  it('redeems a reward, deducts points, and decrements stock', async () => {
    const member = await registerUser(ctx, {
      name: 'Reward Rich',
      email: 'reward-rich@example.com',
    });

    await ctx.db
      .update(profiles)
      .set({ points: 500 })
      .where(eq(profiles.id, member.user.id));

    const catalog = await rewardsBySlug(member.accessToken);
    const tote = catalog.find((reward) => reward.slug === 'tote-bag-daur-ulang')!;
    expect(tote.canRedeem).toBe(true);

    const redeem = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/rewards/${tote.id}/redeem`,
      headers: bearer(member.accessToken),
    });

    expect(redeem.statusCode).toBe(200);
    expect(redeem.json()).toMatchObject({
      pointsSpent: 150,
      redemption: {
        status: 'pending',
        pointsSpent: 150,
        reward: { id: tote.id, stock: 11 },
      },
      reward: { id: tote.id, stock: 11 },
      user: { points: 350 },
    });

    const redemptions = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/redemptions',
      headers: bearer(member.accessToken),
    });
    expect(redemptions.json().data).toHaveLength(1);

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(member.accessToken),
    });
    expect(me.json().stats.rewardsRedeemed).toBe(1);
  });

  it('lets admin fulfill a pending redemption exactly once', async () => {
    const list = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/admin/redemptions?status=pending',
      headers: bearer(adminToken),
    });

    expect(list.statusCode).toBe(200);
    expect(list.json().data.length).toBeGreaterThan(0);
    expect(list.json().data[0].user).toBeTruthy();
    const redemptionId = list.json().data[0].id;

    const fulfilled = await ctx.app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/redemptions/${redemptionId}`,
      headers: bearer(adminToken),
      payload: { status: 'fulfilled' },
    });

    expect(fulfilled.statusCode).toBe(200);
    expect(fulfilled.json().status).toBe('fulfilled');
    expect(fulfilled.json().fulfilledAt).toBeTruthy();

    const again = await ctx.app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/redemptions/${redemptionId}`,
      headers: bearer(adminToken),
      payload: { status: 'cancelled' },
    });

    expect(again.statusCode).toBe(409);
    expect(again.json().error.code).toBe('REDEMPTION_FINALIZED');
  });

  it('refunds points and stock when admin cancels a redemption', async () => {
    const member = await registerUser(ctx, {
      name: 'Reward Refund',
      email: 'reward-refund@example.com',
    });

    await ctx.db
      .update(profiles)
      .set({ points: 350 })
      .where(eq(profiles.id, member.user.id));

    const tumbler = (await rewardsBySlug(member.accessToken)).find(
      (reward) => reward.slug === 'tumbler-eco-500ml',
    )!;

    const redeem = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/rewards/${tumbler.id}/redeem`,
      headers: bearer(member.accessToken),
    });
    expect(redeem.statusCode).toBe(200);
    expect(redeem.json().user.points).toBe(50);

    const redemptionId = redeem.json().redemption.id;
    const cancelled = await ctx.app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/redemptions/${redemptionId}`,
      headers: bearer(adminToken),
      payload: { status: 'cancelled' },
    });

    expect(cancelled.statusCode).toBe(200);
    expect(cancelled.json().status).toBe('cancelled');
    expect(cancelled.json().reward.stock).toBe(8);
    expect(cancelled.json().user.points).toBe(350);

    const history = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/points/history',
      headers: bearer(member.accessToken),
    });

    expect(history.json().summary).toMatchObject({
      spent: 300,
      balance: 350,
    });
    expect(history.json().data).toHaveLength(2);
  });

  it('returns out-of-stock before deducting points', async () => {
    const member = await registerUser(ctx, {
      name: 'Reward Stock',
      email: 'reward-stock@example.com',
    });

    await ctx.db
      .update(profiles)
      .set({ points: 500 })
      .where(eq(profiles.id, member.user.id));

    const catalog = await rewardsBySlug(member.accessToken);
    const bibit = catalog.find((reward) => reward.slug === 'bibit-tanaman')!;

    await ctx.app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/rewards/${bibit.id}`,
      headers: bearer(adminToken),
      payload: { stock: 0 },
    });

    const response = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/rewards/${bibit.id}/redeem`,
      headers: bearer(member.accessToken),
    });

    expect(response.statusCode).toBe(409);
    expect(response.json().error.code).toBe('REWARD_OUT_OF_STOCK');

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(member.accessToken),
    });
    expect(me.json().points).toBe(500);
  });

  it('allows admin to create, update, and deactivate rewards', async () => {
    const member = await registerUser(ctx, {
      name: 'Reward Admin Check',
      email: 'reward-admin-check@example.com',
    });

    const forbidden = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/admin/rewards',
      headers: bearer(member.accessToken),
      payload: {
        title: 'Kaos Eco',
        description: 'Kaos katun organik untuk kegiatan bersih-bersih lingkungan.',
        pointsCost: 200,
        stock: 5,
      },
    });
    expect(forbidden.statusCode).toBe(403);

    const created = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/admin/rewards',
      headers: bearer(adminToken),
      payload: {
        title: 'Kaos Eco',
        description: 'Kaos katun organik untuk kegiatan bersih-bersih lingkungan.',
        pointsCost: 200,
        stock: 5,
      },
    });

    expect(created.statusCode).toBe(201);
    expect(created.json()).toMatchObject({
      title: 'Kaos Eco',
      slug: 'kaos-eco',
      pointsCost: 200,
      stock: 5,
      isActive: true,
    });
    const rewardId = created.json().id;

    const updated = await ctx.app.inject({
      method: 'PATCH',
      url: `/api/v1/admin/rewards/${rewardId}`,
      headers: bearer(adminToken),
      payload: { stock: 9, pointsCost: 225 },
    });

    expect(updated.statusCode).toBe(200);
    expect(updated.json()).toMatchObject({ stock: 9, pointsCost: 225 });

    const deactivated = await ctx.app.inject({
      method: 'DELETE',
      url: `/api/v1/admin/rewards/${rewardId}`,
      headers: bearer(adminToken),
    });
    expect(deactivated.statusCode).toBe(200);
    expect(deactivated.json().isActive).toBe(false);

    const list = await rewardsBySlug(member.accessToken);
    expect(list.find((reward) => reward.id === rewardId)).toBeUndefined();

    const detail = await ctx.app.inject({
      method: 'GET',
      url: `/api/v1/rewards/${rewardId}`,
      headers: bearer(member.accessToken),
    });
    expect(detail.statusCode).toBe(404);
  });
});
