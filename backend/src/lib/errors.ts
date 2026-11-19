export class ApiError extends Error {
  readonly statusCode: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(
    statusCode: number,
    code: string,
    message: string,
    details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }

  static badRequest(code: string, message: string, details?: unknown): ApiError {
    return new ApiError(400, code, message, details);
  }

  static unauthorized(
    message = 'Token akses tidak valid atau sudah kedaluwarsa.',
    code = 'UNAUTHENTICATED',
  ): ApiError {
    return new ApiError(401, code, message);
  }

  static forbidden(
    message = 'Kamu tidak punya akses ke resource ini.',
    code = 'FORBIDDEN',
  ): ApiError {
    return new ApiError(403, code, message);
  }

  static notFound(
    message = 'Resource tidak ditemukan.',
    code = 'NOT_FOUND',
  ): ApiError {
    return new ApiError(404, code, message);
  }

  static conflict(message: string, code = 'CONFLICT', details?: unknown): ApiError {
    return new ApiError(409, code, message, details);
  }
}

interface PostgresErrorLike {
  code?: string;
  constraint?: string;
}

export function isUniqueViolation(error: unknown): boolean {
  return (error as PostgresErrorLike | null)?.code === '23505';
}

export function isForeignKeyViolation(error: unknown): boolean {
  return (error as PostgresErrorLike | null)?.code === '23503';
}
