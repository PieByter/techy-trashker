export interface AuthUser {
  id: string;
  email: string;
  name: string;
}

export interface AuthSession {
  user: AuthUser;
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresAt: string;
}

export interface RegisterInput {
  name: string;
  email: string;
  password: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

/**
 * Abstraksi identity provider. Produksi memakai Supabase Auth;
 * test memakai implementasi in-memory sehingga tidak butuh kredensial cloud.
 */
export interface AuthProvider {
  register(input: RegisterInput): Promise<AuthSession>;
  login(input: LoginInput): Promise<AuthSession>;
  refresh(refreshToken: string): Promise<AuthSession>;
  logout(accessToken: string): Promise<void>;
  verify(accessToken: string): Promise<AuthUser>;
  deleteUser(userId: string): Promise<void>;
}
