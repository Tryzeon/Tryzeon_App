/**
 * Turns "this size, on this body" into one sentence the image model can act on.
 *
 * Pure and database-free on purpose: `catalog.ts` reads the rows, this module
 * decides what they mean. That split is what makes the wording unit-testable
 * without a Supabase client.
 *
 * The module does NOT decide which size to recommend — that stays in the app's
 * `FitCalculator`. All it does is subtract, then pick a word.
 */
import type { BodyMeasurements } from "../user-profile.ts";
import { LIMITS } from "./types.ts";

/**
 * One size's published garment measurements, as stored in
 * `product_sizes.measurements`. Sparse by nature: a skirt has no sleeve length,
 * and store owners publish only what they actually measured.
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
 * Ease thresholds in centimeters, per body dimension.
 *
 * DERIVED, NOT CALIBRATED. Every number is read straight off
 * `lib/feature/personal/shop/domain/services/ease_table.dart` by flattening its
 * `ProductFit` axis: `slimMin` is the slim band's lower bound, `regularMax` the
 * regular band's upper bound, `looseMax` the loose band's upper bound. If that
 * table is ever re-calibrated, re-derive these rather than tuning them here.
 *
 * They are per-dimension because ease does not normalize across dimensions —
 * `EaseTable` calibrates waist/hips/thigh to trouser ease (a waistband sits on
 * the body) and chest to top ease (fabric hangs off the torso), so the same
 * +6cm is ordinary on a chest and generous on a waist. Expressing ease as a
 * percentage of the body dimension does NOT fix this; it was tried and the two
 * ladders still came out more than 3x apart.
 */
interface EaseLadder {
  slimMin: number;
  regularMax: number;
  looseMax: number;
}

/**
 * Circumference dimensions, in the order they are reported. These four are
 * exactly `EaseTable._circumferences` — the only dimensions with bands to
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
 * The adjective for one dimension's ease. Waist's `slimMin` is 0, so its
 * skin-close bucket is unreachable — that is the rule applied uniformly, not a
 * special case.
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

/** Centimeters with at most one decimal, and no trailing `.0`. */
function cm(value: number): string {
  return `${Number(value.toFixed(1))}`;
}

/** Signed centimeters, so a positive ease reads as `+12cm`. */
function signedCm(value: number): string {
  return value >= 0 ? `+${cm(value)}cm` : `-${cm(Math.abs(value))}cm`;
}

function num(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

/**
 * The model-facing description of how one size sits on one body, or undefined
 * when the two sides share no dimension worth describing.
 *
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
  // drop every garment into one bucket. A seam position says more and needs no
  // thresholds at all.
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

  // Body length and sleeve length have no body counterpart at all (see
  // `garment_fit_dimension.dart`, where both map to a null body type). State
  // the centimeters and let the model place the hem from the photo — deriving
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
