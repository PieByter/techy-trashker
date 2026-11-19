import type { FastifyReply, FastifyRequest } from 'fastify';
import { ApiError } from '../lib/errors';
import { ensureProfile } from '../services/profiles';
import type { UserRole } from '../db/schema';

function bearerToken(request: FastifyRequest): string | null {
  const header = request.headers.authorization;
  if (!header) return null;

  const [scheme, ...rest] = header.split(' ');
  if (scheme?.toLowerCase() !== 'bearer') return null;

  const token = rest.join(' ').trim();
  return token || null;
}

export async function authenticate(request: FastifyRequest): Promise<void> {
  const token = bearerToken(request);
  if (!token) {
    throw ApiError.unauthorized(
      'Header Authorization dengan Bearer token diperlukan.',
    );
  }

  const authUser = await request.server.auth.verify(token);
  request.authUser = authUser;
  request.profile = await ensureProfile(request.server, authUser);
}

/**
 * Untuk endpoint publik yang ingin menampilkan data personal bila login
 * (mis. canRedeem pada daftar reward, highlight leaderboard).
 */
export async function optionalAuth(request: FastifyRequest): Promise<void> {
  const token = bearerToken(request);
  if (!token) return;

  try {
    const authUser = await request.server.auth.verify(token);
    request.authUser = authUser;
    request.profile = await ensureProfile(request.server, authUser);
  } catch (error) {
    if (error instanceof ApiError && error.statusCode === 401) return;
    throw error;
  }
}

export function requireRole(...roles: UserRole[]) {
  return async function roleGuard(
    request: FastifyRequest,
    _reply: FastifyReply,
  ): Promise<void> {
    const profile = request.profile;
    if (!profile) {
      throw ApiError.unauthorized();
    }

    if (!roles.includes(profile.role)) {
      throw ApiError.forbidden(
        `Endpoint ini hanya untuk role: ${roles.join(', ')}.`,
      );
    }
  };
}
