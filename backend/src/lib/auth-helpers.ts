import type { FastifyRequest } from 'fastify';
import type { Profile } from '../db/schema';
import { ApiError } from './errors';

export function requireProfile(request: FastifyRequest): Profile {
  if (!request.profile) {
    throw ApiError.unauthorized();
  }
  return request.profile;
}
