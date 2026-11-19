import { createClient, type SupabaseClient, type User } from '@supabase/supabase-js';
import { loadConfig } from '../config';
import { createDb } from './index';
import {
  DEMO_ACCOUNTS,
  seedDatabase,
  type SeedUserIds,
} from './seed';

async function findUserByEmail(
  admin: SupabaseClient,
  email: string,
): Promise<User | null> {
  const perPage = 200;

  for (let page = 1; page <= 20; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage,
    });

    if (error) {
      throw new Error(`Gagal membaca daftar user Supabase: ${error.message}`);
    }

    const found = data.users.find(
      (user) => user.email?.toLowerCase() === email.toLowerCase(),
    );
    if (found) return found;
    if (data.users.length < perPage) break;
  }

  return null;
}

async function main(): Promise<void> {
  const config = loadConfig();

  if (!config.supabaseUrl || !config.supabaseServiceRoleKey) {
    throw new Error(
      'SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY wajib diisi untuk seed akun demo.',
    );
  }

  const connectionString = config.directUrl ?? config.databaseUrl;
  if (!connectionString) {
    throw new Error(
      'DIRECT_URL atau DATABASE_URL wajib diisi untuk seed database.',
    );
  }

  const admin = createClient(
    config.supabaseUrl,
    config.supabaseServiceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    },
  );

  const userIds = {} as SeedUserIds;

  for (const account of DEMO_ACCOUNTS) {
    const { data, error } = await admin.auth.admin.createUser({
      email: account.email,
      password: account.password,
      email_confirm: true,
      user_metadata: { name: account.name },
    });

    if (data.user) {
      userIds[account.key] = data.user.id;
      console.log(`Akun auth dibuat: ${account.email}`);
      continue;
    }

    const existing = await findUserByEmail(admin, account.email);
    if (!existing) {
      throw new Error(
        `Gagal membuat akun ${account.email}: ${error?.message ?? 'unknown error'}`,
      );
    }

    userIds[account.key] = existing.id;
    console.log(`Akun auth sudah ada: ${account.email}`);
  }

  const { db, client } = createDb(connectionString, { max: 1 });

  try {
    const ids = await seedDatabase(db, { users: userIds });
    console.log('Seed data demo selesai.');
    console.log(`Member : ${DEMO_ACCOUNTS[0].email} / ${DEMO_ACCOUNTS[0].password}`);
    console.log(`Petugas: ${DEMO_ACCOUNTS[1].email} / ${DEMO_ACCOUNTS[1].password}`);
    console.log(`Admin  : ${DEMO_ACCOUNTS[2].email} / ${DEMO_ACCOUNTS[2].password}`);
    console.log(`Profil : ${ids.memberId}`);
  } finally {
    await client.end({ timeout: 5 });
  }
}

main().catch((error: unknown) => {
  console.error('Seed gagal:', error);
  process.exit(1);
});
