import { migrate } from 'drizzle-orm/postgres-js/migrator';
import { loadConfig } from '../config';
import { createDb } from './index';

async function main(): Promise<void> {
  const config = loadConfig();
  const connectionString = config.directUrl ?? config.databaseUrl;

  if (!connectionString) {
    throw new Error(
      'DIRECT_URL atau DATABASE_URL belum diisi. Migrasi butuh direct connection Supabase (port 5432).',
    );
  }

  const { db, client } = createDb(connectionString, { max: 1 });

  try {
    console.log('Menjalankan migrasi Drizzle...');
    await migrate(db, { migrationsFolder: './drizzle' });
    console.log('Migrasi selesai.');
  } finally {
    await client.end({ timeout: 5 });
  }
}

main().catch((error: unknown) => {
  console.error('Migrasi gagal:', error);
  process.exit(1);
});
