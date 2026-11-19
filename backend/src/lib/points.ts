export const WASTE_CATEGORIES = [
  'Plastik',
  'Kertas',
  'Logam',
  'Organik',
  'E-Waste',
  'Kaca',
  'Lainnya',
] as const;

export type WasteCategory = (typeof WASTE_CATEGORIES)[number];

/**
 * Poin per kilogram. Angka mengikuti data demo aplikasi:
 * 2,4 kg plastik = 48 poin, 4,8 kg organik = 18 poin, 0,9 kg e-waste = 26 poin.
 */
export const POINT_RATES: Record<WasteCategory, number> = {
  Plastik: 20,
  Kertas: 10,
  Logam: 20,
  Organik: 3.75,
  'E-Waste': 29,
  Kaca: 5,
  Lainnya: 5,
};

const CATEGORY_ALIASES: Record<string, WasteCategory> = {
  plastik: 'Plastik',
  plastic: 'Plastik',
  kertas: 'Kertas',
  paper: 'Kertas',
  kardus: 'Kertas',
  cardboard: 'Kertas',
  logam: 'Logam',
  metal: 'Logam',
  kaleng: 'Logam',
  organik: 'Organik',
  organic: 'Organik',
  'e-waste': 'E-Waste',
  ewaste: 'E-Waste',
  elektronik: 'E-Waste',
  electronic: 'E-Waste',
  kaca: 'Kaca',
  glass: 'Kaca',
  lainnya: 'Lainnya',
  lain: 'Lainnya',
  other: 'Lainnya',
  campuran: 'Lainnya',
};

export function normalizeCategory(value: string): WasteCategory | null {
  return CATEGORY_ALIASES[value.trim().toLowerCase()] ?? null;
}

export function pointsFor(category: WasteCategory, weightKg: number): number {
  return Math.max(0, Math.round(weightKg * POINT_RATES[category]));
}
