-- Convert products.fit from a free-text field into a closed enum-coded column,
-- consistent with elasticity/thickness (English codes in DB, translated in UI).
--
-- Old values were the store-facing Chinese/mixed presets (合身, 常規, 大尺碼,
-- oversize) plus any free-text the owner typed. Remap the known presets to the
-- new codes and drop everything else to NULL — free-text fit was never
-- filterable (list_shop_products does exact `= ANY`), so nothing of value is
-- lost. 大尺碼 (a size concept) folds into oversize, its closest fit meaning.
UPDATE "public"."products"
SET "fit" = CASE "fit"
  WHEN '合身' THEN 'slim'
  WHEN '常規' THEN 'regular'
  WHEN '大尺碼' THEN 'oversize'
  WHEN 'oversize' THEN 'oversize'
  ELSE NULL
END
WHERE "fit" IS NOT NULL;

ALTER TABLE "public"."products"
  ADD CONSTRAINT "products_fit_check"
  CHECK (("fit" = ANY (ARRAY['slim'::"text", 'regular'::"text", 'loose'::"text", 'oversize'::"text"])));

COMMENT ON COLUMN "public"."products"."fit" IS 'Fit type: slim, regular, loose, oversize';
