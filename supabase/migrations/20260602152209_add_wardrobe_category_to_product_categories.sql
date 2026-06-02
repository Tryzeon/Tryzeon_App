-- Add wardrobe_category column to product_categories so that each store-facing
-- product category maps to the coarser WardrobeCategory enum shared with the
-- personal wardrobe. Used by chat LLM recommendation flow to look up matching
-- wardrobe items when the LLM picks a productCategory by name.

ALTER TABLE "public"."product_categories"
  ADD COLUMN "wardrobe_category" "public"."wardrobe_category";

UPDATE "public"."product_categories"
  SET "wardrobe_category" = 'top'
  WHERE "name" IN ('短T', '長T', '大學T·連帽T', '針織·毛衣', '襯衫·POLO衫', '背心·無袖上衣');

UPDATE "public"."product_categories"
  SET "wardrobe_category" = 'pants'
  WHERE "name" IN ('短褲', '長褲');

UPDATE "public"."product_categories"
  SET "wardrobe_category" = 'skirt'
  WHERE "name" = '裙裝';

UPDATE "public"."product_categories"
  SET "wardrobe_category" = 'jacket'
  WHERE "name" = '外套';

UPDATE "public"."product_categories"
  SET "wardrobe_category" = 'others'
  WHERE "name" IN ('洋裝', '家居服', '套裝');
