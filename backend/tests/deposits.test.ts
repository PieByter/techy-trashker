import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  createTestContext,
  loginAs,
  registerUser,
  type TestContext,
} from './helpers/app';

let ctx: TestContext;
let memberToken: string;
let officerToken: string;

const futureIso = (days: number) =>
  new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();

beforeAll(async () => {
  ctx = await createTestContext();
  memberToken = (await loginAs(ctx, 'andhika@techytrashker.id')).accessToken;
  officerToken = (await loginAs(ctx, 'petugas@techytrashker.id')).accessToken;
});

afterAll(async () => {
  await ctx.app.close();
});

describe('deposits', () => {
  it('lists seeded deposits with filters, sorting, and pagination', async () => {
    const list = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
    });

    expect(list.statusCode).toBe(200);
    const body = list.json();
    expect(body.data).toHaveLength(6);
    expect(body.meta.total).toBe(6);
    expect(body.data[0].code).toBe('TT-00148');
    expect(body.data[0].status).toBe('scheduled');

    const pickup = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits?method=pickup',
      headers: bearer(memberToken),
    });
    expect(pickup.json().data).toHaveLength(3);

    const scheduled = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits?status=scheduled',
      headers: bearer(memberToken),
    });
    expect(scheduled.json().data).toHaveLength(1);

    const oldest = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits?sort=oldest',
      headers: bearer(memberToken),
    });
    expect(oldest.json().data[0].code).toBe('TT-00143');

    const page2 = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits?page=2&limit=2',
      headers: bearer(memberToken),
    });
    expect(page2.json().data).toHaveLength(2);
    expect(page2.json().meta).toMatchObject({
      page: 2,
      limit: 2,
      total: 6,
      totalPages: 3,
      hasNext: true,
      hasPrev: true,
    });
  });

  it('returns deposit detail with items and bank name', async () => {
    const list = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits?limit=100',
      headers: bearer(memberToken),
    });
    const deposit = list
      .json()
      .data.find((item: { code: string }) => item.code === 'TT-00147');

    const detail = await ctx.app.inject({
      method: 'GET',
      url: `/api/v1/deposits/${deposit.id}`,
      headers: bearer(memberToken),
    });

    expect(detail.statusCode).toBe(200);
    expect(detail.json()).toMatchObject({
      code: 'TT-00147',
      material: 'Botol Plastik',
      category: 'Plastik',
      weightKg: 2.4,
      points: 48,
      wasteBankName: 'Bank Sampah Berseri',
    });
    expect(detail.json().items).toHaveLength(1);
    expect(detail.json().items[0].points).toBe(48);
  });

  it('provides the officer work queue with member details', async () => {
    const forbidden = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/officer/deposits',
      headers: bearer(memberToken),
    });
    expect(forbidden.statusCode).toBe(403);

    const queue = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/officer/deposits',
      headers: bearer(officerToken),
    });

    expect(queue.statusCode).toBe(200);
    expect(queue.json().data).toHaveLength(1);
    expect(queue.json().data[0]).toMatchObject({
      code: 'TT-00148',
      status: 'scheduled',
      method: 'pickup',
      member: {
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Andhika Pratama',
      },
    });

    const pickups = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/officer/deposits?method=pickup&status=scheduled',
      headers: bearer(officerToken),
    });
    expect(pickups.json().data).toHaveLength(1);

    const processing = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/officer/deposits?status=processing',
      headers: bearer(officerToken),
    });
    expect(processing.json().data).toHaveLength(0);
  });

  it('does not expose another member deposits', async () => {
    const other = await registerUser(ctx, {
      name: 'Member Lain',
      email: 'deposit-other@example.com',
    });

    const list = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/deposits?limit=1',
      headers: bearer(memberToken),
    });
    const depositId = list.json().data[0].id;

    const response = await ctx.app.inject({
      method: 'GET',
      url: `/api/v1/deposits/${depositId}`,
      headers: bearer(other.accessToken),
    });

    expect(response.statusCode).toBe(404);
    expect(response.json().error.code).toBe('DEPOSIT_NOT_FOUND');
  });

  it('validates pickup requests and creates a scheduled pickup', async () => {
    const missingAddress = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
      payload: {
        method: 'pickup',
        material: 'Botol Plastik',
        category: 'Plastik',
        weightKg: 1.5,
        scheduledAt: futureIso(2),
      },
    });

    expect(missingAddress.statusCode).toBe(400);

    const past = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
      payload: {
        method: 'pickup',
        material: 'Botol Plastik',
        category: 'Plastik',
        weightKg: 1.5,
        address: 'Jl. Gatot Subroto No. 12, Medan',
        scheduledAt: futureIso(-1),
      },
    });

    expect(past.statusCode).toBe(400);

    const created = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
      payload: {
        method: 'pickup',
        material: 'Botol Plastik',
        category: 'plastik',
        weightKg: 1.5,
        address: 'Jl. Gatot Subroto No. 12, Medan',
        scheduledAt: futureIso(2),
        notes: 'Tolong datang pagi.',
      },
    });

    expect(created.statusCode).toBe(201);
    expect(created.json()).toMatchObject({
      method: 'pickup',
      status: 'scheduled',
      weightKg: 1.5,
      points: 0,
      address: 'Jl. Gatot Subroto No. 12, Medan',
    });
    expect(created.json().code).toMatch(/^TT-\d{5}$/);
  });

  it('rejects invalid bank references and unauthenticated creation', async () => {
    const invalidBank = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
      payload: {
        method: 'dropoff',
        material: 'Botol Plastik',
        category: 'Plastik',
        weightKg: 1,
        wasteBankId: '00000000-0000-4000-8000-000000000099',
      },
    });

    expect(invalidBank.statusCode).toBe(404);
    expect(invalidBank.json().error.code).toBe('WASTE_BANK_NOT_FOUND');

    const unauthenticated = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      payload: {
        method: 'dropoff',
        material: 'Botol Plastik',
        category: 'Plastik',
        weightKg: 1,
      },
    });

    expect(unauthenticated.statusCode).toBe(401);
  });

  it('cancels a pending deposit and refuses repeat cancellation', async () => {
    const created = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
      payload: {
        method: 'dropoff',
        material: 'Kardus',
        category: 'Kertas',
        weightKg: 2,
      },
    });
    const id = created.json().id;

    const cancelled = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/deposits/${id}/cancel`,
      headers: bearer(memberToken),
    });

    expect(cancelled.statusCode).toBe(200);
    expect(cancelled.json().status).toBe('cancelled');

    const again = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/deposits/${id}/cancel`,
      headers: bearer(memberToken),
    });

    expect(again.statusCode).toBe(409);
    expect(again.json().error.code).toBe('DEPOSIT_CANNOT_BE_CANCELLED');
  });

  it('completes a deposit as officer and awards points atomically', async () => {
    const member = await registerUser(ctx, {
      name: 'Member Setoran',
      email: 'deposit-complete@example.com',
    });

    const created = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(member.accessToken),
      payload: {
        method: 'dropoff',
        material: 'Botol Plastik',
        category: 'Plastik',
        weightKg: 2,
      },
    });

    expect(created.statusCode).toBe(201);
    const depositId = created.json().id;

    const forbidden = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/deposits/${depositId}/complete`,
      headers: bearer(member.accessToken),
      payload: {
        items: [
          { material: 'Botol Plastik', category: 'Plastik', weightKg: 2 },
        ],
      },
    });
    expect(forbidden.statusCode).toBe(403);

    const completed = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/deposits/${depositId}/complete`,
      headers: bearer(officerToken),
      payload: {
        items: [
          { material: 'Botol Plastik', category: 'Plastik', weightKg: 2 },
          { material: 'Kardus', category: 'Kertas', weightKg: 1 },
        ],
      },
    });

    expect(completed.statusCode).toBe(200);
    expect(completed.json()).toMatchObject({
      pointsEarned: 50,
      deposit: {
        status: 'completed',
        weightKg: 3,
        points: 50,
        material: '2 jenis sampah',
        category: 'Campuran',
      },
      member: {
        id: member.user.id,
        points: 50,
      },
    });
    expect(completed.json().deposit.items).toHaveLength(2);

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(member.accessToken),
    });
    expect(me.json()).toMatchObject({
      points: 50,
      totalWeightKg: 3,
      stats: {
        deposits: 1,
        completedDeposits: 1,
      },
    });

    const history = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/points/history',
      headers: bearer(member.accessToken),
    });
    expect(history.json().data).toHaveLength(1);
    expect(history.json().data[0]).toMatchObject({
      amount: 50,
      type: 'deposit',
    });

    const repeat = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/deposits/${depositId}/complete`,
      headers: bearer(officerToken),
      payload: {
        items: [
          { material: 'Botol Plastik', category: 'Plastik', weightKg: 1 },
        ],
      },
    });

    expect(repeat.statusCode).toBe(409);
    expect(repeat.json().error.code).toBe('DEPOSIT_ALREADY_COMPLETED');
  });

  it('completes a scheduled pickup while preserving the address', async () => {
    const created = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/deposits',
      headers: bearer(memberToken),
      payload: {
        method: 'pickup',
        material: 'Kertas & Kardus',
        category: 'Kertas',
        weightKg: 3,
        address: 'Jl. Imam Bonjol No. 45, Medan',
        scheduledAt: futureIso(3),
      },
    });
    const id = created.json().id;

    const completed = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/deposits/${id}/complete`,
      headers: bearer(officerToken),
      payload: {
        items: [
          { material: 'Kertas & Kardus', category: 'Kertas', weightKg: 2.5 },
        ],
        notes: 'Sudah ditimbang ulang.',
      },
    });

    expect(completed.statusCode).toBe(200);
    expect(completed.json().deposit).toMatchObject({
      status: 'completed',
      method: 'pickup',
      address: 'Jl. Imam Bonjol No. 45, Medan',
      weightKg: 2.5,
      points: 25,
      notes: 'Sudah ditimbang ulang.',
    });
  });
});
