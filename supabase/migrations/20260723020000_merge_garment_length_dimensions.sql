-- Merge the three garment length dimensions into one `length`.
--
-- `garment_length` / `pants_length` / `skirt_length` were three names for the
-- same measurement — how long the garment is — split only by garment type. The
-- garment type is already known from the product's categories, and
-- `wardrobe_category` itself no longer separates trousers from skirts (they
-- merged into `bottoms` in 20260616120000), so the split bought nothing and
-- forced a size chart for `bottoms` to carry both a trouser length and a skirt
-- length column.
--
-- `product_sizes.measurements` is jsonb and inherently sparse, so this is a data
-- remap only — no schema change. A row can only ever have carried one of the
-- three in practice (a garment is one type); COALESCE picks the first present
-- one in that order if an older row somehow holds more than one.

UPDATE "public"."product_sizes"
SET "measurements" =
  ("measurements" - 'garment_length' - 'pants_length' - 'skirt_length')
  || "jsonb_strip_nulls"(
       "jsonb_build_object"(
         'length',
         COALESCE(
           "measurements" -> 'garment_length',
           "measurements" -> 'pants_length',
           "measurements" -> 'skirt_length'
         )
       )
     )
WHERE "measurements" ?| ARRAY['garment_length', 'pants_length', 'skirt_length'];
