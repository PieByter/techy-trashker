import type {
  FastifyRequest,
  preHandlerHookHandler,
} from 'fastify';
import type { AuthProvider, AuthUser } from '../auth/types';
import type { Config } from '../config';
import type { AppDatabase } from '../db';
import type { Profile, UserRole } from '../db/schema';

declare module 'fastify' {
  interface FastifyInstance {
    config: Config;
    db: AppDatabase;
    auth: AuthProvider;
    authenticate: preHandlerHookHandler;
    optionalAuth: preHandlerHookHandler;
    requireRole: (...roles: UserRole[]) => preHandlerHookHandler;
  }

  interface FastifyRequest {
    profile: Profile | null;
    authUser: AuthUser | null;
  }
}
