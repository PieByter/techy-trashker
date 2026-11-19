import { drizzle, type PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

export type AppDatabase = PostgresJsDatabase<typeof schema>;
export type DbClient = ReturnType<typeof postgres>;

export function createDb(
  connectionString: string,
  options: { max?: number } = {},
): { db: AppDatabase; client: DbClient } {
  const client = postgres(connectionString, {
    max: options.max ?? 5,
    idle_timeout: 20,
    connect_timeout: 15,
    // Supabase transaction pooler (port 6543) tidak mendukung prepared statements.
    prepare: false,
    onnotice: () => undefined,
  });

  return {
    db: drizzle(client, { schema }),
    client,
  };
}
