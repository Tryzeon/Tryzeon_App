-- Drop products.wardrobe_category — replaced by joining through
-- product_categories.wardrobe_category (added in
-- 20260602152209_add_wardrobe_category_to_product_categories.sql).
-- The wardrobe_category enum type itself is retained, still used by
-- product_categories.wardrobe_category.

DROP INDEX IF EXISTS "public"."idx_products_wardrobe_category";

-- Recreate get_shop_products without p_wardrobe_category. CREATE OR REPLACE
-- cannot change a function's parameter list, so drop the old signature first.
DROP FUNCTION IF EXISTS "public"."get_shop_products"(
  "uuid", "text", "text"[], integer, integer, "text"[],
  "public"."product_gender", "public"."wardrobe_category", "text", boolean
);

CREATE OR REPLACE FUNCTION "public"."get_shop_products"(
  "p_store_id" "uuid" DEFAULT NULL::"uuid",
  "p_search_query" "text" DEFAULT NULL::"text",
  "p_category_ids" "text"[] DEFAULT NULL::"text"[],
  "p_min_price" integer DEFAULT NULL::integer,
  "p_max_price" integer DEFAULT NULL::integer,
  "p_channels" "text"[] DEFAULT NULL::"text"[],
  "p_gender" "public"."product_gender" DEFAULT NULL::"public"."product_gender",
  "p_sort_column" "text" DEFAULT 'created_at'::"text",
  "p_sort_ascending" boolean DEFAULT false
) RETURNS SETOF "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT to_jsonb(t) FROM (
    SELECT
      p.id,
      p.store_id,
      p.name,
      p.category_ids,
      p.price,
      p.image_paths,
      p.created_at,
      p.updated_at,
      p.purchase_link,
      p.material,
      p.elasticity,
      p.fit,
      p.thickness,
      p.styles,
      p.seasons,
      p.gender,
      COALESCE(
        (
          SELECT jsonb_agg(v)
          FROM product_variants v
          WHERE v.product_id = p.id
        ),
        '[]'::jsonb
      ) AS product_variants,
      jsonb_build_object(
        'id',         s.id,
        'name',       s.name,
        'address',    s.address,
        'logo_path',  s.logo_path,
        'channels',   s.channels
      ) AS store_profiles
    FROM products p
    JOIN store_profiles s ON s.id = p.store_id
    WHERE
      (p_store_id IS NULL OR p.store_id = p_store_id)
      AND (p_category_ids IS NULL OR p.category_ids && p_category_ids)
      AND (p_min_price IS NULL OR p.price >= p_min_price)
      AND (p_max_price IS NULL OR p.price <= p_max_price)
      AND (p_channels  IS NULL OR s.channels && p_channels)
      AND (p_gender IS NULL OR p.gender = p_gender OR p.gender = 'unisex')
      AND (
        p_search_query IS NULL
        OR p.name ILIKE '%' || p_search_query || '%'
        OR s.name ILIKE '%' || p_search_query || '%'
      )
    ORDER BY
      CASE WHEN p_sort_column = 'price'      AND     p_sort_ascending THEN p.price       END ASC  NULLS LAST,
      CASE WHEN p_sort_column = 'price'      AND NOT p_sort_ascending THEN p.price       END DESC NULLS LAST,
      CASE WHEN p_sort_column = 'created_at'                          THEN p.created_at  END DESC NULLS LAST
  ) t;
$$;

ALTER FUNCTION "public"."get_shop_products"(
  "uuid", "text", "text"[], integer, integer, "text"[],
  "public"."product_gender", "text", boolean
) OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."get_shop_products"(
  "uuid", "text", "text"[], integer, integer, "text"[],
  "public"."product_gender", "text", boolean
) TO "anon";

GRANT ALL ON FUNCTION "public"."get_shop_products"(
  "uuid", "text", "text"[], integer, integer, "text"[],
  "public"."product_gender", "text", boolean
) TO "authenticated";

GRANT ALL ON FUNCTION "public"."get_shop_products"(
  "uuid", "text", "text"[], integer, integer, "text"[],
  "public"."product_gender", "text", boolean
) TO "service_role";

ALTER TABLE "public"."products" DROP COLUMN IF EXISTS "wardrobe_category";
