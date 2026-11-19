import { createHash, randomBytes, randomInt } from 'node:crypto';

export function generateQrToken(): string {
  return `ttqr_${randomBytes(32).toString('base64url')}`;
}

export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export function generateDepositCode(): string {
  return `TT-${randomInt(10_000, 100_000)}`;
}

export function generateMemberCode(now = new Date()): string {
  return `TT-${now.getFullYear()}-${randomInt(10_000, 100_000)}`;
}
