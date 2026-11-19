import type {
  Deposit,
  DepositItem,
  NewsItem,
  PointTransaction,
  Profile,
  Redemption,
  Reward,
  WasteBank,
} from '../db/schema';
import { levelFor } from './levels';
import { round } from './numbers';

export interface ProfileStats {
  deposits: number;
  completedDeposits: number;
  rewardsRedeemed: number;
}

export function absoluteUrl(baseUrl: string, value: string | null): string | null {
  if (!value) return null;
  if (/^https?:\/\//i.test(value)) return value;
  const suffix = value.startsWith('/') ? value : `/${value}`;
  return `${baseUrl.replace(/\/$/, '')}${suffix}`;
}

function iso(value: Date | null): string | null {
  return value ? value.toISOString() : null;
}

function indonesianDate(value: Date): string {
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    timeZone: 'Asia/Jakarta',
  }).format(value);
}

export function serializeProfile(
  profile: Profile,
  baseUrl: string,
  stats?: ProfileStats,
) {
  const level = levelFor(profile.points);

  return {
    id: profile.id,
    memberCode: profile.memberCode,
    name: profile.name,
    email: profile.email,
    role: profile.role,
    avatarUrl: absoluteUrl(baseUrl, profile.avatarUrl),
    points: profile.points,
    totalWeightKg: round(profile.totalWeightKg, 2),
    level: level.level,
    nextLevel: level.nextLevel,
    nextLevelPoints: level.nextLevelPoints,
    levelProgress: level.levelProgress,
    ...(stats ? { stats } : {}),
    createdAt: profile.createdAt.toISOString(),
  };
}

export function serializeMember(profile: Profile, baseUrl: string) {
  return {
    id: profile.id,
    memberCode: profile.memberCode,
    name: profile.name,
    avatarUrl: absoluteUrl(baseUrl, profile.avatarUrl),
    points: profile.points,
    level: levelFor(profile.points).level,
  };
}

export function serializeNews(
  item: NewsItem,
  baseUrl: string,
  includeContent = false,
) {
  return {
    id: item.id,
    title: item.title,
    slug: item.slug,
    category: item.category,
    summary: item.summary,
    ...(includeContent ? { content: item.content } : {}),
    imageUrl: absoluteUrl(baseUrl, item.imageUrl),
    publishedAt: item.publishedAt.toISOString(),
    date: indonesianDate(item.publishedAt),
  };
}

export function serializeWasteBank(bank: WasteBank, distanceKm: number) {
  return {
    id: bank.id,
    name: bank.name,
    slug: bank.slug,
    address: bank.address,
    phone: bank.phone,
    latitude: bank.latitude,
    longitude: bank.longitude,
    distanceKm: Math.round(distanceKm * 10) / 10,
    rating: round(bank.rating, 1),
    isOpen: bank.isOpen,
    openHours: bank.openHours,
    mapX: round(bank.mapX, 3),
    mapY: round(bank.mapY, 3),
  };
}

export function serializeDepositItem(item: DepositItem) {
  return {
    id: item.id,
    material: item.material,
    category: item.category,
    weightKg: round(item.weightKg, 2),
    points: item.points,
  };
}

export function serializeDeposit(
  deposit: Deposit,
  items: DepositItem[],
  wasteBankName: string | null = null,
) {
  return {
    id: deposit.id,
    code: deposit.code,
    method: deposit.method,
    status: deposit.status,
    material: deposit.material,
    category: deposit.category,
    weightKg: round(deposit.weightKg, 2),
    points: deposit.points,
    wasteBankId: deposit.wasteBankId,
    wasteBankName,
    address: deposit.address,
    scheduledAt: iso(deposit.scheduledAt),
    completedAt: iso(deposit.completedAt),
    notes: deposit.notes,
    createdAt: deposit.createdAt.toISOString(),
    updatedAt: deposit.updatedAt.toISOString(),
    items: items.map(serializeDepositItem),
  };
}

export function serializeReward(
  reward: Reward,
  baseUrl: string,
  canRedeem = false,
) {
  return {
    id: reward.id,
    slug: reward.slug,
    title: reward.title,
    description: reward.description,
    pointsCost: reward.pointsCost,
    stock: reward.stock,
    imageUrl: absoluteUrl(baseUrl, reward.imageUrl),
    isActive: reward.isActive,
    canRedeem,
  };
}

export function serializeRedemption(
  redemption: Redemption,
  reward: Reward,
  baseUrl: string,
  user?: Profile,
) {
  return {
    id: redemption.id,
    status: redemption.status,
    pointsSpent: redemption.pointsSpent,
    createdAt: redemption.createdAt.toISOString(),
    fulfilledAt: iso(redemption.fulfilledAt),
    reward: serializeReward(reward, baseUrl, false),
    ...(user ? { user: serializeMember(user, baseUrl) } : {}),
  };
}

export function serializePointTransaction(transaction: PointTransaction) {
  return {
    id: transaction.id,
    amount: transaction.amount,
    type: transaction.type,
    description: transaction.description,
    depositId: transaction.depositId,
    redemptionId: transaction.redemptionId,
    createdAt: transaction.createdAt.toISOString(),
  };
}

export function serializeQrSession(input: {
  token: string;
  qrPayload: string;
  expiresAt: Date;
  expiresInSeconds: number;
  profile: Profile;
  baseUrl: string;
}) {
  return {
    token: input.token,
    qrPayload: input.qrPayload,
    expiresAt: input.expiresAt.toISOString(),
    expiresInSeconds: input.expiresInSeconds,
    member: serializeMember(input.profile, input.baseUrl),
  };
}

export function serializeLeaderboardEntry(
  rank: number,
  profile: Profile,
  baseUrl: string,
  isCurrentUser: boolean,
) {
  return {
    rank,
    user: serializeMember(profile, baseUrl),
    isCurrentUser,
  };
}
