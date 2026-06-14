-- Reshape product_categories from per-gender rows (Design A, added in
-- 20260614000000) into a genderless garment taxonomy + gender applicability
-- (Design B). Gender becomes a PRODUCT attribute; a category just declares
-- which shopper genders it applies to, plus per-gender model imagery.
--
-- Starting state (Design A): each category exists as separate `male` / `female`
-- rows, distinguished by `gender` and a single `image_path`.

-- The applicability of a category is a single `product_gender`:
--   male    => men-only browse
--   female  => women-only browse
--   unisex  => applies to BOTH (the common case)
-- Since shoppers are binary (male/female), this scalar captures every valid
-- subset with no invalid empty state and stays symmetric with products.gender.

-- 1. Image columns (per-gender model imagery).
ALTER TABLE "public"."product_categories"
  ADD COLUMN "image_male" "text",
  ADD COLUMN "image_female" "text";

-- 2. Female imagery comes from the original female rows.
UPDATE "public"."product_categories" AS "c"
  SET "image_female" = "c"."image_path"
  WHERE "c"."gender" = 'female';

-- 3. Male imagery: copy each male row's image_path onto the matching female row
--    (matched by name).
UPDATE "public"."product_categories" AS "f"
  SET "image_male" = "m"."image_path"
  FROM "public"."product_categories" AS "m"
  WHERE "m"."gender" = 'male'
    AND "f"."gender" = 'female'
    AND "f"."name" = "m"."name";

-- 4. Reshape the surviving (female) rows' gender into applicability:
--    has a male counterpart => unisex (both); otherwise stays female-only.
UPDATE "public"."product_categories"
  SET "gender" = 'unisex'
  WHERE "gender" = 'female' AND "image_male" IS NOT NULL;

-- 5. Drop the duplicated male rows — the canonical taxonomy is the female set.
DELETE FROM "public"."product_categories" WHERE "gender" = 'male';

-- 6. `gender` now means applicability; default new rows to unisex. Replace the
--    Design A index and drop the superseded image_path.
ALTER TABLE "public"."product_categories" ALTER COLUMN "gender" SET DEFAULT 'unisex';
DROP INDEX IF EXISTS "public"."idx_product_categories_gender_priority";
ALTER TABLE "public"."product_categories" DROP COLUMN "image_path";
