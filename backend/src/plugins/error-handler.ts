import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import {
  ApiError,
  isForeignKeyViolation,
  isUniqueViolation,
} from '../lib/errors';

export function errorHandler(
  error: FastifyError,
  request: FastifyRequest,
  reply: FastifyReply,
): void {
  if (error instanceof ApiError) {
    reply.code(error.statusCode).send({
      error: {
        code: error.code,
        message: error.message,
        ...(error.details !== undefined ? { details: error.details } : {}),
      },
    });
    return;
  }

  if (error.validation) {
    reply.code(400).send({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Data yang dikirim tidak valid.',
        details: error.validation,
      },
    });
    return;
  }

  if (isUniqueViolation(error)) {
    reply.code(409).send({
      error: {
        code: 'CONFLICT',
        message: 'Data dengan nilai unik tersebut sudah ada.',
      },
    });
    return;
  }

  if (isForeignKeyViolation(error)) {
    reply.code(400).send({
      error: {
        code: 'INVALID_REFERENCE',
        message: 'Data referensi tidak ditemukan atau masih dipakai.',
      },
    });
    return;
  }

  if (error.statusCode === 429) {
    reply.code(429).send({
      error: {
        code: 'RATE_LIMITED',
        message: 'Terlalu banyak permintaan. Coba lagi sebentar lagi.',
      },
    });
    return;
  }

  const statusCode = error.statusCode ?? 500;

  if (statusCode < 500) {
    reply.code(statusCode).send({
      error: {
        code: error.code ?? 'REQUEST_ERROR',
        message: error.message,
      },
    });
    return;
  }

  request.log.error({ err: error }, 'Unhandled request error');
  reply.code(500).send({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Terjadi kesalahan pada server.',
    },
  });
}
