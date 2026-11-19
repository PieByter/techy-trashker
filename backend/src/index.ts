import { buildApp } from './app';
import { createSupabaseAuthProvider } from './auth/supabase-auth';
import { assertRuntimeConfig, loadConfig } from './config';
import { createDb } from './db';

async function main(): Promise<void> {
  const config = loadConfig();
  assertRuntimeConfig(config);

  const { db, client } = createDb(config.databaseUrl!, { max: 5 });
  const auth = createSupabaseAuthProvider(config);

  const app = await buildApp({
    config,
    db,
    auth,
    logger: {
      level: config.logLevel,
      ...(config.nodeEnv === 'development'
        ? {
            transport: {
              target: 'pino-pretty',
              options: {
                translateTime: 'SYS:standard',
                ignore: 'pid,hostname',
              },
            },
          }
        : {}),
    },
    onClose: async () => {
      await client.end({ timeout: 5 });
    },
  });

  try {
    await app.listen({ host: config.host, port: config.port });
    app.log.info(
      { docs: `${config.publicBaseUrl}/docs` },
      'Techy Trashker API siap',
    );
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }

  const shutdown = async (signal: string): Promise<void> => {
    app.log.info({ signal }, 'Menutup server...');
    await app.close();
    process.exit(0);
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
