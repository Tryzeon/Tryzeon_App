/**
 * Does NOT decide which size to recommend — that stays in the app's
 * `FitCalculator`.
 */
import type { BodyMeasurements } from "../user-profile.ts";
import { LIMITS } from "./types.ts";

/**
 * As stored in `product_sizes.measurements`; sparse, since store owners publish
 * only what they actually measured.
 */
export interface SizeMeasurements {
  shoulder_width?: number;
  chest_circumference?: number;
  sleeve_length?: number;
  waist_circumference?: number;
  hip_circumference?: number;
  thigh_circumference?: number;
  length?: number;
}

/**
 * Ease thresholds in centimeters, per body dimension. DERIVED, NOT CALIBRATED:
 * every number is read off
 * `lib/feature/personal/shop/domain/services/ease_table.dart` by flattening its
 * `ProductFit` axis — `slimMin` is the slim band's lower bound, `regularMax`
 * the regular band's upper bound, `looseMax` the loose band's upper bound. If
 * that table is re-calibrated, re-derive these rather than tuning them here.
 *
 * Per-dimension because ease does not normalize across dimensions: `EaseTable`
 * calibrates waist/hips/thigh to trouser ease and chest to top ease, so the
 * same +6cm is ordinary on a chest and generous on a waist. Expressing ease as
 * a percentage of the body dimension was tried and left the two ladders more
 * than 3x apart.
 */
interface EaseLadder {
  slimMin: number;
  regularMax: number;
  looseMax: number;
}

/**
 * Exactly `EaseTable._circumferences` — the only dimensions with bands to
 * derive a ladder from.
 */
const CIRCUMFERENCES: ReadonlyArray<{
  label: string;
  garment: keyof SizeMeasurements;
  body: keyof BodyMeasurements;
  ladder: EaseLadder;
}> = [
  {
    label: "chest",
    garment: "chest_circumference",
    body: "chest",
    ladder: { slimMin: 4, regularMax: 15, looseMax: 24 },
  },
  {
    label: "waist",
    garment: "waist_circumference",
    body: "waist",
    ladder: { slimMin: 0, regularMax: 4, looseMax: 8 },
  },
  {
    label: "hips",
    garment: "hip_circumference",
    body: "hips",
    ladder: { slimMin: 2, regularMax: 9, looseMax: 14 },
  },
  {
    label: "thigh",
    garment: "thigh_circumference",
    body: "thigh",
    ladder: { slimMin: 1, regularMax: 7, looseMax: 12 },
  },
];

/**
 * Waist's `slimMin` is 0, so its skin-close bucket is unreachable — the rule
 * applied uniformly, not a special case.
 */
function easePhrase(ease: number, ladder: EaseLadder): string {
  if (ease < 0) {
    return "compression — the fabric is pulled taut against the body";
  }
  if (ease < ladder.slimMin) {
    return "skin-close, follows the body with no slack";
  }
  if (ease <= ladder.regularMax) {
    return "fitted, follows the body with a little room";
  }
  if (ease <= ladder.looseMax) return "loose, hangs away from the body";
  return "billowy, drapes well clear of the body";
}

function cm(value: number): string {
  return `${Number(value.toFixed(1))}`;
}

function signedCm(value: number): string {
  return value >= 0 ? `+${cm(value)}cm` : `-${cm(Math.abs(value))}cm`;
}

function num(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

/**
 * Truncation is safe here for the same reason it is in
 * `buildProductGarmentDetail`: this text is server-generated, so nobody is told
 * "accepted" while their input was quietly cut short.
 */
export function buildGarmentFitDetail(
  sizeName: string,
  size: SizeMeasurements | null,
  body: BodyMeasurements,
): string | undefined {
  if (!size) return undefined;

  const clauses: string[] = [];

  for (const dim of CIRCUMFERENCES) {
    const garmentValue = num(size[dim.garment]);
    const bodyValue = num(body[dim.body]);
    if (garmentValue === undefined || bodyValue === undefined) continue;
    const ease = garmentValue - bodyValue;
    clauses.push(
      `${dim.label} ${cm(garmentValue)}cm on a ${
        cm(bodyValue)
      }cm ${dim.label} ` +
        `(${signedCm(ease)} — ${easePhrase(ease, dim.ladder)})`,
    );
  }

  // Shoulders are a linear seam, not a circumference: `EaseTable` gives them a
  // band barely wider than the body (-1..2, 0..3), so an adjective ladder would
  // drop every garment into one bucket.
  const shoulderGarment = num(size.shoulder_width);
  const shoulderBody = num(body.shoulder);
  if (shoulderGarment !== undefined && shoulderBody !== undefined) {
    const halfDiff = (shoulderGarment - shoulderBody) / 2;
    const seat = halfDiff === 0
      ? "sitting exactly on the shoulder points"
      : halfDiff > 0
      ? `sitting ${cm(halfDiff)}cm past each shoulder point`
      : `sitting ${cm(-halfDiff)}cm inside each shoulder point`;
    clauses.push(
      `shoulder seams ${cm(shoulderGarment)}cm on ${
        cm(shoulderBody)
      }cm shoulders, ${seat}`,
    );
  }

  // Body length and sleeve length have no body counterpart (see
  // `garment_fit_dimension.dart`, where both map to a null body type): deriving
  // "lands at the high hip" would need torso proportions we do not collect.
  const length = num(size.length);
  if (length !== undefined) {
    const height = num(body.height);
    clauses.push(
      height === undefined
        ? `body length ${cm(length)}cm`
        : `body length ${cm(length)}cm on a ${cm(height)}cm wearer`,
    );
  }

  const sleeve = num(size.sleeve_length);
  if (sleeve !== undefined) clauses.push(`sleeve length ${cm(sleeve)}cm`);

  if (clauses.length === 0) return undefined;

  return `size ${sizeName}: ${clauses.join("; ")}`.slice(
    0,
    LIMITS.MAX_GARMENT_FIT_LENGTH,
  );
}
