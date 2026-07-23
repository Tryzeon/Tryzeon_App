-- Rename the garment width dimensions to circumferences.
--
-- `chest_width` / `waist_width` / `hip_width` held the flat width across the
-- laid-out garment — half a circumference. Store owners do not measure that
-- way: they read the circumference off their own size chart, and the app then
-- asked them to halve it. The dimension is now the garment's circumference at
-- that point, which is what both the store owner and the shopper already think
-- in. `shoulder_width` and `sleeve_length` stay linear — a garment has no
-- circumference there.
--
-- Keys only: the stored numbers are left untouched by design. Existing rows
-- therefore carry a half-circumference under a circumference key; store owners
-- correct their own charts. Do NOT add a x2 pass on top of this migration
-- later — it would double whatever they have since fixed.

UPDATE "public"."product_sizes"
SET "measurements" =
  ("measurements" - 'chest_width' - 'waist_width' - 'hip_width')
  || "jsonb_strip_nulls"(
       "jsonb_build_object"(
         'chest_circumference', "measurements" -> 'chest_width',
         'waist_circumference', "measurements" -> 'waist_width',
         'hip_circumference',   "measurements" -> 'hip_width'
       )
     )
WHERE "measurements" ?| ARRAY['chest_width', 'waist_width', 'hip_width'];
