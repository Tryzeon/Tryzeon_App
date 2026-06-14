-- Add a `gender` dimension to product_categories so the personal side can show
-- gender-specific category lists + images (men see menswear categories/images,
-- women see womenswear). Reuses the existing product_gender enum. The store side
-- keeps reading every category (gender IS NULL filter in the app), so it can tag
-- products of any gender.
--
-- Existing 13 rows are womenswear (all `_f` images) -> backfilled to 'female'.
-- Adds 11 menswear rows mirroring the `_m` images that exist in the
-- `product-categories/` R2 bucket.

ALTER TABLE "public"."product_categories"
  ADD COLUMN "gender" "public"."product_gender" NOT NULL DEFAULT 'female';

-- Backfill is covered by the DEFAULT, but state it explicitly for clarity.
UPDATE "public"."product_categories"
  SET "gender" = 'female';

-- Index for the gender + priority read path used by the app.
CREATE INDEX IF NOT EXISTS "idx_product_categories_gender_priority"
  ON "public"."product_categories" USING "btree" ("gender", "priority" DESC);

-- Menswear seed (image_path matches the `_m` assets in R2; note mixed
-- extensions: Tshirt_withhat_m.jpg, coat_m.jpg, trousers_m.jpeg, rest .png).
INSERT INTO "public"."product_categories"
  ("name", "gender", "priority", "image_path", "wardrobe_category")
VALUES
  ('襯衫·POLO衫',   'male', 100, 'product-categories/shirt_m.png',          'top'),
  ('背心·無袖上衣', 'male', 101, 'product-categories/vest_m.png',           'top'),
  ('針織·毛衣',     'male', 102, 'product-categories/sweater_m.png',        'top'),
  ('大學T·連帽T',   'male', 103, 'product-categories/Tshirt_withhat_m.jpg', 'top'),
  ('長T',           'male', 104, 'product-categories/long_shirt_m.png',     'top'),
  ('短T',           'male', 105, 'product-categories/short_shirt_m.png',    'top'),
  ('家居服',        'male', 110, 'product-categories/home_cloth_m.png',     'others'),
  ('長褲',          'male', 111, 'product-categories/trousers_m.jpeg',      'pants'),
  ('短褲',          'male', 112, 'product-categories/short_m.png',          'pants'),
  ('外套',          'male', 130, 'product-categories/coat_m.jpg',           'jacket'),
  ('套裝',          'male', 140, 'product-categories/suit_m.png',           'others');
