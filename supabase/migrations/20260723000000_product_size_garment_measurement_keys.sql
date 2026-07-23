-- Product sizes now carry *garment* flat measurements, not body measurements.
--
-- The app used to share one `Measurements` type between the shopper's body and
-- a product's size chart, so `product_variants.measurements` was keyed with
-- body vocabulary (chest / waist / hips / shoulder / sleeve / height). The two
-- concepts are now separate types, and the garment side uses its own keys plus
-- the hem lengths a size chart actually needs.
--
-- `product_variants` is the table behind the app's `ProductSize` entity — the
-- Dart name and the table name diverged historically; the pkey is still called
-- `product_sizes_pkey`. The shopper's own measurements live on
-- `user_profiles.measurements` and are deliberately untouched here.
--
-- This renames the jsonb keys in place. It deliberately does NOT rescale any
-- value: the numbers stay exactly as store owners entered them. `height` is
-- dropped — a garment has no height, and it never fed the fit calculation.
--
-- Idempotent: rows already using garment keys carry none of the legacy keys and
-- are skipped by the WHERE clause.

UPDATE "public"."product_variants"
SET "measurements" = "jsonb_strip_nulls"(
  "jsonb_build_object"(
    'shoulder_width', "measurements" -> 'shoulder',
    'chest_width',    "measurements" -> 'chest',
    'sleeve_length',  "measurements" -> 'sleeve',
    'waist_width',    "measurements" -> 'waist',
    'hip_width',      "measurements" -> 'hips'
  )
)
WHERE "measurements" IS NOT NULL
  -- function form of the `?|` operator: `?` is a parameter placeholder for some
  -- drivers, so spelling it out keeps the migration safe to run anywhere.
  AND "jsonb_exists_any"(
    "measurements",
    ARRAY['height', 'shoulder', 'chest', 'sleeve', 'waist', 'hips']
  );
