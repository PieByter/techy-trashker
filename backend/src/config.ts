import { config as loadEnv } from 'dotenv';
import { z } from 'zod';

loadEnv({ path: '.env.local', quiet: true });
loadEnv({ path: '.env', quiet: true });

export type NodeEnv = 'development' | 'test' | 'production';

export interface Config {
  nodeEnv: NodeEnv;
  host: string;
  port: number;
  publicBaseUrl: string;
  corsOrigin: string;
  logLevel: string;
  trustProxy: boolean;
  qrTtlSeconds: number;
  rateLimitMax: number;
  supabaseUrl: string | null;
  supabaseAnonKey: string | null;
  supabaseServiceRoleKey: string | null;
  databaseUrl: string | null;
  directUrl: string | null;
}

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  PUBLIC_BASE_URL: z.string().url().optional(),
  CORS_ORIGIN: z.string().default('*'),
  LOG_LEVEL: z
    .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'])
    .default('info'),
  TRUST_PROXY: z
    .enum(['true', 'false'])
    .default('false')
    .transform((value) => value === 'true'),
  QR_TTL_SECONDS: z.coerce.number().int().min(60).max(3600).default(300),
  RATE_LIMIT_MAX: z.coerce.number().int().min(1).default(300),
});

function optionalEnv(value: string | undefined): string | null {
  const trimmed = value?.trim();
  if (!trimmed) return null;
  // Anggap placeholder dari .env.example sebagai belum diisi.
  if (trimmed.includes('<') && trimmed.includes('>')) return null;
  return trimmed;
}

function pick<T>(override: T | undefined, fallback: T): T {
  return override !== undefined ? override : fallback;
}

export function loadConfig(overrides: Partial<Config> = {}): Config {
  const parsed = envSchema.parse(process.env);
  const port = pick(overrides.port, parsed.PORT);
  const nodeEnv = pick(overrides.nodeEnv, parsed.NODE_ENV);

  return {
    nodeEnv,
    host: pick(overrides.host, parsed.HOST),
    port,
    publicBaseUrl: pick(
      overrides.publicBaseUrl,
      parsed.PUBLIC_BASE_URL ?? `http://localhost:${port}`,
    ),
    corsOrigin: pick(overrides.corsOrigin, parsed.CORS_ORIGIN),
    logLevel: pick(overrides.logLevel, parsed.LOG_LEVEL),
    trustProxy: pick(overrides.trustProxy, parsed.TRUST_PROXY),
    qrTtlSeconds: pick(overrides.qrTtlSeconds, parsed.QR_TTL_SECONDS),
    rateLimitMax: pick(overrides.rateLimitMax, parsed.RATE_LIMIT_MAX),
    supabaseUrl: pick(
      overrides.supabaseUrl,
      optionalEnv(process.env.SUPABASE_URL),
    ),
    supabaseAnonKey: pick(
      overrides.supabaseAnonKey,
      optionalEnv(
        process.env.SUPABASE_ANON_KEY ?? process.env.SUPABASE_PUBLISHABLE_KEY,
      ),
    ),
    supabaseServiceRoleKey: pick(
      overrides.supabaseServiceRoleKey,
      optionalEnv(
        process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_SECRET_KEY,
      ),
    ),
    databaseUrl: pick(
      overrides.databaseUrl,
      optionalEnv(process.env.DATABASE_URL),
    ),
    directUrl: pick(overrides.directUrl, optionalEnv(process.env.DIRECT_URL)),
  };
}

export function assertRuntimeConfig(config: Config): void {
  const missing: string[] = [];

  if (!config.supabaseUrl) missing.push('SUPABASE_URL');
  if (!config.supabaseAnonKey) {
    missing.push('SUPABASE_ANON_KEY (atau SUPABASE_PUBLISHABLE_KEY)');
  }
  if (!config.supabaseServiceRoleKey) {
    missing.push('SUPABASE_SERVICE_ROLE_KEY (atau SUPABASE_SECRET_KEY)');
  }
  if (!config.databaseUrl) missing.push('DATABASE_URL');

  if (missing.length > 0) {
    throw new Error(
      `Konfigurasi backend belum lengkap. Isi variabel berikut di .env: ${missing.join(
        ', ',
      )}`,
    );
  }
}
