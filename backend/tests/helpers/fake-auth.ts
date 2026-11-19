import { randomUUID } from 'node:crypto';
import type {
  AuthProvider,
  AuthSession,
  AuthUser,
  LoginInput,
  RegisterInput,
} from '../../src/auth/types';
import { ApiError } from '../../src/lib/errors';

interface FakeUser {
  id: string;
  email: string;
  password: string;
  name: string;
}

export interface FakeUserSeed {
  id: string;
  email: string;
  password: string;
  name: string;
}

export class FakeAuthProvider implements AuthProvider {
  private readonly usersByEmail = new Map<string, FakeUser>();
  private readonly usersById = new Map<string, FakeUser>();
  private readonly accessTokens = new Map<string, string>();
  private readonly refreshTokens = new Map<string, string>();

  constructor(users: FakeUserSeed[]) {
    for (const user of users) {
      const record: FakeUser = { ...user, email: user.email.toLowerCase() };
      this.usersByEmail.set(record.email, record);
      this.usersById.set(record.id, record);
    }
  }

  async register(input: RegisterInput): Promise<AuthSession> {
    const email = input.email.toLowerCase();

    if (this.usersByEmail.has(email)) {
      throw ApiError.conflict('Email sudah terdaftar.', 'EMAIL_TAKEN');
    }

    const user: FakeUser = {
      id: randomUUID(),
      email,
      password: input.password,
      name: input.name,
    };

    this.usersByEmail.set(email, user);
    this.usersById.set(user.id, user);
    return this.issueSession(user);
  }

  async login(input: LoginInput): Promise<AuthSession> {
    const user = this.usersByEmail.get(input.email.toLowerCase());
    if (!user || user.password !== input.password) {
      throw ApiError.unauthorized(
        'Email atau password salah.',
        'INVALID_CREDENTIALS',
      );
    }

    return this.issueSession(user);
  }

  async refresh(refreshToken: string): Promise<AuthSession> {
    const userId = this.refreshTokens.get(refreshToken);
    if (!userId) {
      throw ApiError.unauthorized(
        'Refresh token tidak valid atau sudah kedaluwarsa.',
        'INVALID_REFRESH_TOKEN',
      );
    }

    this.refreshTokens.delete(refreshToken);
    const user = this.usersById.get(userId);
    if (!user) {
      throw ApiError.unauthorized('User tidak ditemukan.', 'INVALID_TOKEN');
    }

    return this.issueSession(user);
  }

  async logout(accessToken: string): Promise<void> {
    this.accessTokens.delete(accessToken);
  }

  async verify(accessToken: string): Promise<AuthUser> {
    const userId = this.accessTokens.get(accessToken);
    if (!userId) {
      throw ApiError.unauthorized(
        'Token akses tidak valid atau sudah kedaluwarsa.',
        'INVALID_TOKEN',
      );
    }

    const user = this.usersById.get(userId);
    if (!user) {
      throw ApiError.unauthorized('User tidak ditemukan.', 'INVALID_TOKEN');
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
    };
  }

  async deleteUser(userId: string): Promise<void> {
    const user = this.usersById.get(userId);
    if (!user) return;

    this.usersById.delete(userId);
    this.usersByEmail.delete(user.email);

    for (const [token, id] of this.accessTokens) {
      if (id === userId) this.accessTokens.delete(token);
    }
    for (const [token, id] of this.refreshTokens) {
      if (id === userId) this.refreshTokens.delete(token);
    }
  }

  private issueSession(user: FakeUser): AuthSession {
    const accessToken = `test_access_${randomUUID()}`;
    const refreshToken = `test_refresh_${randomUUID()}`;

    this.accessTokens.set(accessToken, user.id);
    this.refreshTokens.set(refreshToken, user.id);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
      accessToken,
      refreshToken,
      tokenType: 'bearer',
      expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    };
  }
}
