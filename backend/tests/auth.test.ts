import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  createTestContext,
  loginAs,
  registerUser,
  type TestContext,
} from './helpers/app';

let ctx: TestContext;

beforeAll(async () => {
  ctx = await createTestContext();
});

afterAll(async () => {
  await ctx.app.close();
});

const uniqueEmail = (suffix: string) => `tester-${suffix}@example.com`;

describe('auth & profile', () => {
  it('registers a new user, provisions a profile, and authorizes /me', async () => {
    const email = uniqueEmail('register');
    const session = await registerUser(ctx, {
      name: 'Tester Baru',
      email,
    });

    expect(session.user.email).toBe(email);
    expect(session.user.name).toBe('Tester Baru');
    expect(session.user.memberCode).toMatch(/^TT-\d{4}-\d{5}$/);
    expect(session.accessToken).toBeTruthy();
    expect(session.refreshToken).toBeTruthy();

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(session.accessToken),
    });

    expect(me.statusCode).toBe(200);
    expect(me.json()).toMatchObject({
      email,
      points: 0,
      level: 'Pemula',
      stats: {
        deposits: 0,
        completedDeposits: 0,
        rewardsRedeemed: 0,
      },
    });
  });

  it('rejects duplicate email registration', async () => {
    const email = uniqueEmail('duplicate');
    await registerUser(ctx, { name: 'Pertama', email });

    const response = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        name: 'Kedua',
        email,
        password: 'rahasia123',
      },
    });

    expect(response.statusCode).toBe(409);
    expect(response.json().error.code).toBe('EMAIL_TAKEN');
  });

  it('rejects invalid login credentials without leaking details', async () => {
    const response = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        email: 'andhika@techytrashker.id',
        password: 'password-salah',
      },
    });

    expect(response.statusCode).toBe(401);
    expect(response.json()).toEqual({
      error: {
        code: 'INVALID_CREDENTIALS',
        message: 'Email atau password salah.',
      },
    });
  });

  it('rotates refresh tokens', async () => {
    const session = await loginAs(ctx, 'andhika@techytrashker.id');

    const firstRefresh = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: session.refreshToken },
    });

    expect(firstRefresh.statusCode).toBe(200);
    const rotated = firstRefresh.json();
    expect(rotated.accessToken).not.toBe(session.accessToken);
    expect(rotated.refreshToken).not.toBe(session.refreshToken);

    const reuse = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: session.refreshToken },
    });

    expect(reuse.statusCode).toBe(401);
    expect(reuse.json().error.code).toBe('INVALID_REFRESH_TOKEN');
  });

  it('revokes the access token on logout', async () => {
    const session = await loginAs(ctx, 'petugas@techytrashker.id');

    const logout = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/logout',
      headers: bearer(session.accessToken),
    });

    expect(logout.statusCode).toBe(204);

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: bearer(session.accessToken),
    });

    expect(me.statusCode).toBe(401);
  });

  it('requires a bearer token', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/me',
    });

    expect(response.statusCode).toBe(401);
    expect(response.json().error.code).toBe('UNAUTHENTICATED');
  });

  it('forbids non-admin users from admin endpoints', async () => {
    const session = await loginAs(ctx, 'andhika@techytrashker.id');

    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/admin/redemptions',
      headers: bearer(session.accessToken),
    });

    expect(response.statusCode).toBe(403);
    expect(response.json().error.code).toBe('FORBIDDEN');
  });

  it('validates registration input', async () => {
    const response = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        name: 'A',
        email: 'bukan-email',
        password: 'pendek',
      },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json().error.code).toBe('VALIDATION_ERROR');
    expect(response.json().error.details.length).toBeGreaterThan(0);
  });

  it('updates profile name and avatar', async () => {
    const session = await loginAs(ctx, 'andhika@techytrashker.id');

    const response = await ctx.app.inject({
      method: 'PATCH',
      url: '/api/v1/me',
      headers: bearer(session.accessToken),
      payload: {
        name: 'Andhika P.',
        avatarUrl: 'https://example.com/avatar.png',
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      name: 'Andhika P.',
      avatarUrl: 'https://example.com/avatar.png',
    });
  });
});
