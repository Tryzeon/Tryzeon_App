-- Rename product_categories.priority -> "order" and switch the app's read path
-- to ascending order (smallest "order" first). Existing values are preserved as
-- requested; only the column name and sort direction change.
--
-- Note: `order` is a SQL reserved word, so the column must always be quoted as
-- "order" in queries (PostgREST/Supabase handles this for the .order() call).

ALTER TABLE "public"."product_categories"
  RENAME COLUMN "priority" TO "order";

-- Recreate the gender + sort-key index for the read path (the Design A
-- gender+priority DESC index was dropped in 20260615000000). Ascending now,
-- matching the new smallest-first ordering used by the app.
CREATE INDEX IF NOT EXISTS "idx_product_categories_gender_order"
  ON "public"."product_categories" USING "btree" ("gender", "order");
