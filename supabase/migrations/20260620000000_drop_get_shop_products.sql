-- Drop the legacy get_shop_products function. It was superseded by
-- list_shop_products (see 20260617010000_rename_list_shop_products.sql) and was
-- intentionally retained so the previous app build kept working during store
-- review. The new client now calls list_shop_products, so the old function is
-- safe to remove.
--
-- Signature matches the last definition in 20260603000000_chat_search_query_tokens.sql
-- (p_wardrobe_category was already dropped in 20260602153428).

DROP FUNCTION IF EXISTS "public"."get_shop_products"(
  "p_store_id" "uuid",
  "p_search_query" "text",
  "p_category_ids" "text"[],
  "p_min_price" integer,
  "p_max_price" integer,
  "p_channels" "text"[],
  "p_gender" "public"."product_gender",
  "p_sort_column" "text",
  "p_sort_ascending" boolean
);
