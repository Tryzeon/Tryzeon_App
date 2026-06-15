-- Collapse the wardrobe_category enum from 7 values to 5:
--   top                -> top        (上衣)
--   pants, skirt       -> bottoms    (下身)
--   jacket             -> outerwear  (外套)
--   (new)              -> sets       (套裝)
--   shoes, accessories -> others     (其他)
--   others             -> others     (其他)
--
-- As of 20260602153428 the enum is referenced by exactly ONE column,
-- product_categories.wardrobe_category (products.wardrobe_category and the
-- get_shop_products() parameter were dropped there). Postgres can't remove or
-- merge enum values in place, so: cast that column to text, remap the data,
-- rebuild the enum, then cast the column back. wardrobe_items.category was a
-- plain text column; this migration also promotes it to the enum type so the DB
-- enforces valid categories.

-- 1. Detach the enum from its only column.
ALTER TABLE "public"."product_categories"
  ALTER COLUMN "wardrobe_category" TYPE "text" USING "wardrobe_category"::"text";

-- 2. Remap existing data to the new value set.
UPDATE "public"."wardrobe_items"
  SET "category" = CASE "category"
    WHEN 'pants'       THEN 'bottoms'
    WHEN 'skirt'       THEN 'bottoms'
    WHEN 'jacket'      THEN 'outerwear'
    WHEN 'shoes'       THEN 'others'
    WHEN 'accessories' THEN 'others'
    ELSE "category"
  END
  WHERE "category" IN ('pants', 'skirt', 'jacket', 'shoes', 'accessories');

UPDATE "public"."product_categories"
  SET "wardrobe_category" = CASE "wardrobe_category"
    WHEN 'pants'       THEN 'bottoms'
    WHEN 'skirt'       THEN 'bottoms'
    WHEN 'jacket'      THEN 'outerwear'
    WHEN 'shoes'       THEN 'others'
    WHEN 'accessories' THEN 'others'
    ELSE "wardrobe_category"
  END
  WHERE "wardrobe_category" IN ('pants', 'skirt', 'jacket', 'shoes', 'accessories');

-- 套裝 now has its own wardrobe category instead of falling into 'others'.
UPDATE "public"."product_categories"
  SET "wardrobe_category" = 'sets'
  WHERE "name" = '套裝';

-- 3. Rebuild the enum with the new value set.
ALTER TYPE "public"."wardrobe_category" RENAME TO "wardrobe_category_old";

CREATE TYPE "public"."wardrobe_category" AS ENUM (
  'top',
  'bottoms',
  'outerwear',
  'sets',
  'others'
);

ALTER TYPE "public"."wardrobe_category" OWNER TO "postgres";

-- 4. Cast the columns to the rebuilt enum, then drop the old type. The index
--    idx_wardrobe_items_category (user_id, category) is rebuilt automatically.
ALTER TABLE "public"."product_categories"
  ALTER COLUMN "wardrobe_category" TYPE "public"."wardrobe_category"
  USING "wardrobe_category"::"public"."wardrobe_category";

ALTER TABLE "public"."wardrobe_items"
  ALTER COLUMN "category" TYPE "public"."wardrobe_category"
  USING "category"::"public"."wardrobe_category";

DROP TYPE "public"."wardrobe_category_old";
