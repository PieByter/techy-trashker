import { createClient, type Session, type User } from '@supabase/supabase-js';
import type { Config } from '../config';
import { ApiError } from '../lib/errors';
import type {
  AuthProvider,
  AuthSession,
  AuthUser,
  LoginInput,
  RegisterInput,
} from './types';

function displayName(user: User): string {
  const metadataName =
    user.user_metadata?.name ?? user.user_metadata?.full_name;
  if (typeof metadataName === 'string' && metadataName.trim()) {
    return metadataName.trim();
  }
  return user.email?.split('@')[0] ?? 'Pengguna';
}

function toAuthUser(user: User): AuthUser {
  return {
    id: user.id,
    email: user.email ?? '',
    name: displayName(user),
  };
}

function toAuthSession(session: Session): AuthSession {
  const expiresAt =
    session.expires_at ??
    Math.floor(Date.now() / 1000) + (session.expires_in ?? 3600);

  return {
    user: toAuthUser(session.user),
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    tokenType: session.token_type || 'bearer',
    expiresAt: new Date(expiresAt * 1000).toISOString(),
  };
}

function isDuplicateUserError(error: { code?: string; message?: string }): boolean {
  return (
    error.code === 'email_exists' ||
    error.code === 'user_already_exists' ||
    /already (been )?registered|already exists/i.test(error.message ?? '')
  );
}

export function createSupabaseAuthProvider(config: Config): AuthProvider {
  if (!config.supabaseUrl || !config.supabaseAnonKey || !config.supabaseServiceRoleKey) {
    throw new Error('Konfigurasi Supabase Auth belum lengkap.');
  }

  const clientOptions = {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  } as const;

  const authClient = createClient(
    config.supabaseUrl,
    config.supabaseAnonKey,
    clientOptions,
  );

  const adminClient = createClient(
    config.supabaseUrl,
    config.supabaseServiceRoleKey,
    clientOptions,
  );

  async function signInWithPassword(input: LoginInput): Promise<AuthSession> {
    const { data, error } = await authClient.auth.signInWithPassword({
      email: input.email,
      password: input.password,
    });

    if (error) {
      if (error.code === 'email_not_confirmed') {
        throw new ApiError(
          403,
          'EMAIL_NOT_CONFIRMED',
          'Email belum dikonfirmasi. Cek inbox lalu coba lagi.',
        );
      }

      if (error.status === 429) {
        throw new ApiError(
          429,
          'AUTH_RATE_LIMITED',
          'Terlalu banyak percobaan login. Coba lagi beberapa saat lagi.',
        );
      }

      if ((error.status ?? 0) >= 500) {
        throw new ApiError(
          502,
          'AUTH_UNAVAILABLE',
          'Layanan autentikasi sedang tidak tersedia.',
        );
      }

      throw ApiError.unauthorized(
        'Email atau password salah.',
        'INVALID_CREDENTIALS',
      );
    }

    if (!data.session) {
      throw new ApiError(
        502,
        'AUTH_SESSION_FAILED',
        'Supabase tidak mengembalikan sesi login.',
      );
    }

    return toAuthSession(data.session);
  }

  return {
    async register(input: RegisterInput): Promise<AuthSession> {
      const { data, error } = await adminClient.auth.admin.createUser({
        email: input.email,
        password: input.password,
        email_confirm: true,
        user_metadata: { name: input.name },
      });

      if (error) {
        if (isDuplicateUserError(error)) {
          throw ApiError.conflict(
            'Email sudah terdaftar. Coba login atau pakai email lain.',
            'EMAIL_TAKEN',
          );
        }

        if (error.code === 'weak_password') {
          throw ApiError.badRequest(
            'WEAK_PASSWORD',
            error.message || 'Password terlalu lemah.',
          );
        }

        if (error.status === 429) {
          throw new ApiError(
            429,
            'AUTH_RATE_LIMITED',
            'Terlalu banyak percobaan registrasi. Coba lagi beberapa saat lagi.',
          );
        }

        if ((error.status ?? 0) >= 500) {
          throw new ApiError(
            502,
            'AUTH_UNAVAILABLE',
            'Layanan autentikasi sedang tidak tersedia.',
          );
        }

        throw new ApiError(
          502,
          'AUTH_REGISTER_FAILED',
          'Gagal membuat akun di Supabase.',
        );
      }

      try {
        return await signInWithPassword(input);
      } catch (signInError) {
        // Compensating action: jangan tinggalkan auth user tanpa sesi.
        if (data.user) {
          await adminClient.auth.admin.deleteUser(data.user.id).catch(() => {
            // Best-effort cleanup.
          });
        }
        throw signInError;
      }
    },

    async login(input: LoginInput): Promise<AuthSession> {
      return signInWithPassword(input);
    },

    async refresh(refreshToken: string): Promise<AuthSession> {
      const { data, error } = await authClient.auth.refreshSession({
        refresh_token: refreshToken,
      });

      if (error || !data.session) {
        throw ApiError.unauthorized(
          'Refresh token tidak valid atau sudah kedaluwarsa.',
          'INVALID_REFRESH_TOKEN',
        );
      }

      return toAuthSession(data.session);
    },

    async logout(accessToken: string): Promise<void> {
      const { error } = await adminClient.auth.admin.signOut(accessToken, 'local');
      if (error && error.status !== 401) {
        throw new ApiError(
          502,
          'AUTH_LOGOUT_FAILED',
          'Gagal mengakhiri sesi di Supabase.',
        );
      }
    },

    async verify(accessToken: string): Promise<AuthUser> {
      let result: Awaited<ReturnType<typeof authClient.auth.getUser>>;

      try {
        result = await authClient.auth.getUser(accessToken);
      } catch {
        throw new ApiError(
          502,
          'AUTH_UNAVAILABLE',
          'Layanan autentikasi sedang tidak tersedia.',
        );
      }

      if (result.error || !result.data.user) {
        if (result.error?.status === 429) {
          throw new ApiError(
            429,
            'AUTH_RATE_LIMITED',
            'Terlalu banyak permintaan autentikasi. Coba lagi sebentar lagi.',
          );
        }

        if ((result.error?.status ?? 0) >= 500) {
          throw new ApiError(
            502,
            'AUTH_UNAVAILABLE',
            'Layanan autentikasi sedang tidak tersedia.',
          );
        }

        throw ApiError.unauthorized(
          'Token akses tidak valid atau sudah kedaluwarsa.',
          'INVALID_TOKEN',
        );
      }

      return toAuthUser(result.data.user);
    },

    async deleteUser(userId: string): Promise<void> {
      await adminClient.auth.admin.deleteUser(userId);
    },
  };
}
