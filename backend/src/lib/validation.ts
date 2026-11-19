import { z } from 'zod';
import {
  WASTE_CATEGORIES,
  normalizeCategory,
  type WasteCategory,
} from './points';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const emailSchema = z
  .string()
  .trim()
  .toLowerCase()
  .min(3, 'Email wajib diisi.')
  .max(254, 'Email terlalu panjang.')
  .refine((value) => EMAIL_PATTERN.test(value), 'Format email tidak valid.');

export const passwordSchema = z
  .string()
  .min(8, 'Password minimal 8 karakter.')
  .max(72, 'Password maksimal 72 karakter.');

export const nameSchema = z
  .string()
  .trim()
  .min(2, 'Nama minimal 2 karakter.')
  .max(80, 'Nama maksimal 80 karakter.');

export const paginationQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const uuidParamSchema = z.object({
  id: z.string().uuid('ID tidak valid.'),
});

export const booleanQuerySchema = z.preprocess((value) => {
  if (value === 'true' || value === true) return true;
  if (value === 'false' || value === false) return false;
  return value;
}, z.boolean());

export const wasteCategorySchema = z.preprocess((value) => {
  if (typeof value !== 'string') return value;
  return normalizeCategory(value) ?? value;
}, z.enum(WASTE_CATEGORIES));

export const weightKgSchema = z
  .number()
  .positive('Berat harus lebih dari 0 kg.')
  .max(500, 'Berat maksimal 500 kg per item.');

export const wasteItemSchema = z.object({
  material: z.string().trim().min(2, 'Nama material wajib diisi.').max(80),
  category: wasteCategorySchema,
  weightKg: weightKgSchema,
});

export const wasteItemsSchema = z
  .array(wasteItemSchema)
  .min(1, 'Minimal satu item setoran.')
  .max(20, 'Maksimal 20 item per setoran.');

export interface ComputedWasteItem {
  material: string;
  category: WasteCategory;
  weightKg: number;
  points: number;
}

export interface ComputedWaste {
  items: ComputedWasteItem[];
  totalWeightKg: number;
  totalPoints: number;
  primaryMaterial: string;
  primaryCategory: string;
}

export function computeWaste(
  rawItems: Array<{
    material: string;
    category: WasteCategory;
    weightKg: number;
  }>,
  pointsFor: (category: WasteCategory, weightKg: number) => number,
): ComputedWaste {
  const items = rawItems.map((item) => ({
    ...item,
    points: pointsFor(item.category, item.weightKg),
  }));

  const totalWeightKg = items.reduce((sum, item) => sum + item.weightKg, 0);
  const totalPoints = items.reduce((sum, item) => sum + item.points, 0);

  return {
    items,
    totalWeightKg: Math.round(totalWeightKg * 100) / 100,
    totalPoints,
    primaryMaterial:
      items.length === 1 ? items[0].material : `${items.length} jenis sampah`,
    primaryCategory: items.length === 1 ? items[0].category : 'Campuran',
  };
}
