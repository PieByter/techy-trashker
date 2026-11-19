import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { qrSessions } from '../src/db/schema';
import { hashToken } from '../src/lib/ids';
import {
  bearer,
  createTestContext,
  loginAs,
  registerUser,
  type TestContext,
} from './helpers/app';

let ctx: TestContext;
let officerToken: string;

beforeAll(async () => {
  ctx = await createTestContext();
  officerToken = (await loginAs(ctx, 'petugas@techytrashker.id')).accessToken;
});

afterAll(async () => {
  await ctx.app.close();
});

async function createSession(accessToken: string) {
  return ctx.app.inject({
    method: 'POST',
    url: '/api/v1/qr/session',
    headers: bearer(accessToken),
  });
}

describe('QR setor', () => {
  it('creates a short-lived QR session', async () => {
    const member = await registerUser(ctx, {
      name: 'QR Member',
      email: 'qr-session@example.com',
    });

    const response = await createSession(member.accessToken);

    expect(response.statusCode).toBe(201);
    expect(response.json()).toMatchObject({
      expiresInSeconds: 300,
      member: {
        id: member.user.id,
        memberCode: member.user.memberCode,
      },
    });
    expect(response.json().token).toMatch(/^ttqr_/);
    expect(response.json().qrPayload).toContain('techytrashker://deposit?token=');
    expect(new Date(response.json().expiresAt).getTime()).toBeGreaterThan(
      Date.now(),
    );
  });

  it('requires authentication to create a session', async () => {
    const response = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/session',
    });

    expect(response.statusCode).toBe(401);
  });

  it('lets only officers scan, awards points once, and consumes the token', async () => {
    const member = await registerUser(ctx, {
      name: 'QR Scan Member',
      email: 'qr-scan@example.com',
    });
    const session = (await createSession(member.accessToken)).json();

    const forbidden = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(member.accessToken),
      payload: {
        token: session.token,
        items: [
          { material: 'Botol Plastik', category: 'Plastik', weightKg: 2 },
        ],
      },
    });
    expect(forbidden.statusCode).toBe(403);

    const scan = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(officerToken),
      payload: {
        token: session.token,
        items: [
          { material: 'Botol Plastik', category: 'Plastik', weightKg: 2 },
          { material: 'Kardus', category: 'Kertas', weightKg: 1 },
        ],
        notes: 'Ditimbang di bank sampah.',
      },
    });

    expect(scan.statusCode).toBe(200);
    expect(scan.json()).toMatchObject({
      pointsEarned: 50,
      deposit: {
        status: 'completed',
        method: 'dropoff',
        weightKg: 3,
        points: 50,
        notes: 'Ditimbang di bank sampah.',
      },
      member: {
        id: member.user.id,
        points: 50,
      },
    });
    expect(scan.json().deposit.items).toHaveLength(2);

    const [stored] = await ctx.db
      .select()
      .from(qrSessions)
      .where(eq(qrSessions.tokenHash, hashToken(session.token)))
      .limit(1);
    expect(stored.usedAt).toBeInstanceOf(Date);

    const reuse = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(officerToken),
      payload: {
        token: session.token,
        items: [
          { material: 'Botol Plastik', category: 'Plastik', weightKg: 1 },
        ],
      },
    });

    expect(reuse.statusCode).toBe(409);
    expect(reuse.json().error.code).toBe('QR_USED');

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(member.accessToken),
    });
    expect(me.json()).toMatchObject({
      points: 50,
      totalWeightKg: 3,
    });
  });

  it('rejects unknown and expired QR tokens', async () => {
    const member = await registerUser(ctx, {
      name: 'QR Expired',
      email: 'qr-expired@example.com',
    });

    const unknown = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(officerToken),
      payload: {
        token: 'ttqr_token-tidak-dikenal-sama-sekali',
        items: [
          { material: 'Kertas', category: 'Kertas', weightKg: 1 },
        ],
      },
    });
    expect(unknown.statusCode).toBe(404);
    expect(unknown.json().error.code).toBe('INVALID_QR');

    const session = (await createSession(member.accessToken)).json();
    await ctx.db
      .update(qrSessions)
      .set({ expiresAt: new Date(Date.now() - 1000) })
      .where(eq(qrSessions.tokenHash, hashToken(session.token)));

    const expired = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(officerToken),
      payload: {
        token: session.token,
        items: [
          { material: 'Kertas', category: 'Kertas', weightKg: 1 },
        ],
      },
    });

    expect(expired.statusCode).toBe(410);
    expect(expired.json().error.code).toBe('QR_EXPIRED');
  });

  it('supports memberCode fallback and rejects ambiguous payloads', async () => {
    const member = await registerUser(ctx, {
      name: 'QR Manual',
      email: 'qr-manual@example.com',
    });

    const ambiguous = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(officerToken),
      payload: {
        token: 'ttqr_apa-saja-yang-penting-panjang',
        memberCode: member.user.memberCode,
        items: [
          { material: 'Kertas', category: 'Kertas', weightKg: 1 },
        ],
      },
    });
    expect(ambiguous.statusCode).toBe(400);

    const scan = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/qr/scan',
      headers: bearer(officerToken),
      payload: {
        memberCode: member.user.memberCode.toLowerCase(),
        items: [
          { material: 'Kaleng Aluminium', category: 'Logam', weightKg: 1 },
        ],
      },
    });

    expect(scan.statusCode).toBe(200);
    expect(scan.json()).toMatchObject({
      pointsEarned: 20,
      member: {
        id: member.user.id,
        points: 20,
      },
    });
  });
});
