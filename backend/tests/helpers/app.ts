import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import { migrate } from 'drizzle-orm/pglite/migrator';
import path from 'node:path';
import { buildApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import type { AppDatabase } from '../../src/db';
import * as schema from '../../src/db/schema';
import {
  DEFAULT_SEED_USER_IDS,
  DEMO_ACCOUNTS,
  seedDatabase,
} from '../../src/db/seed';
import { FakeAuthProvider } from './fake-auth';

export interface TestContext {
  app: Awaited<ReturnType<typeof buildApp>>;
  db: AppDatabase;
  pglite: PGlite;
  auth: FakeAuthProvider;
}

export async function createTestContext(): Promise<TestContext> {
  const pglite = new PGlite();
  const pgliteDb = drizzle(pglite, { schema });

  await migrate(pgliteDb, {
    migrationsFolder: path.resolve(process.cwd(), 'drizzle'),
  });

  const db = pgliteDb as unknown as AppDatabase;
  await seedDatabase(db, { users: DEFAULT_SEED_USER_IDS });

  const auth = new FakeAuthProvider(
    DEMO_ACCOUNTS.map((account) => ({
      id: DEFAULT_SEED_USER_IDS[account.key],
      email: account.email,
      password: account.password,
      name: account.name,
    })),
  );

  const app = await buildApp({
    config: loadConfig({
      nodeEnv: 'test',
      publicBaseUrl: 'http://localhost:3000',
      rateLimitMax: 10_000,
      logLevel: 'silent',
      supabaseUrl: null,
      supabaseAnonKey: null,
      supabaseServiceRoleKey: null,
      databaseUrl: null,
      directUrl: null,
    }),
    db,
    auth,
    logger: false,
    onClose: async () => {
      await pglite.close();
    },
  });

  await app.ready();

  return { app, db, pglite, auth };
}

export function bearer(accessToken: string): { authorization: string } {
  return { authorization: `Bearer ${accessToken}` };
}

export interface SessionBody {
  user: {
    id: string;
    memberCode: string;
    name: string;
    email: string;
    points: number;
  };
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresAt: string;
}

export async function loginAs(
  ctx: TestContext,
  email: string,
  password = 'rahasia123',
): Promise<SessionBody> {
  const response = await ctx.app.inject({
    method: 'POST',
    url: '/api/v1/auth/login',
    payload: { email, password },
  });

  if (response.statusCode !== 200) {
    throw new Error(
      `Login ${email} gagal (${response.statusCode}): ${response.body}`,
    );
  }

  return response.json<SessionBody>();
}

export async function registerUser(
  ctx: TestContext,
  input: {
    name: string;
    email: string;
    password?: string;
  },
): Promise<SessionBody> {
  const response = await ctx.app.inject({
    method: 'POST',
    url: '/api/v1/auth/register',
    payload: {
      name: input.name,
      email: input.email,
      password: input.password ?? 'rahasia123',
    },
  });

  if (response.statusCode !== 201) {
    throw new Error(
      `Register ${input.email} gagal (${response.statusCode}): ${response.body}`,
    );
  }

  return response.json<SessionBody>();
}
