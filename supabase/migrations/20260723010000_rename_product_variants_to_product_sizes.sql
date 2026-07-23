-- Rename `product_variants` → `product_sizes`.
--
-- The table has always modeled one size of a product (S/M/L + garment flat
-- measurements) — a size-chart row, not an e-commerce variant. A "variant" is a
-- purchasable SKU (own price / stock / barcode), none of which this table has.
-- Everything else already says "sizes": the pkey (`product_sizes_pkey`), the fkey
-- (`product_sizes_product_id_fkey`), the index (`idx_product_sizes_product_id`),
-- the RLS policy names, and the app's `ProductSize` entity. The table name was
-- the one holdout; this aligns it.
--
-- Constraints, indexes, RLS policies, grants, and triggers follow a table rename
-- automatically — only the trigger *name* needs a manual touch-up, and
-- `list_shop_products` must be recreated since its body references the table and
-- its result exposes the embedded array under the old name.

ALTER TABLE "public"."product_variants" RENAME TO "product_sizes";

ALTER TRIGGER "trg_product_variants_updated_at" ON "public"."product_sizes"
  RENAME TO "trg_product_sizes_updated_at";

-- Same body as 20260712000000_store_order_contacts.sql, with the size subquery
-- reading from the renamed table and aliased `product_sizes` (the JSON key the
-- app decodes).
CREATE OR REPLACE FUNCTION "public"."list_shop_products"(
  "p_store_id" "uuid" DEFAULT NULL::"uuid",
  "p_search_query" "text" DEFAULT NULL::"text",
  "p_category_ids" "text"[] DEFAULT NULL::"text"[],
  "p_min_price" integer DEFAULT NULL::integer,
  "p_max_price" integer DEFAULT NULL::integer,
  "p_channels" "text"[] DEFAULT NULL::"text"[],
  "p_gender" "public"."product_gender" DEFAULT NULL::"public"."product_gender",
  "p_materials" "text"[] DEFAULT NULL::"text"[],
  "p_elasticities" "text"[] DEFAULT NULL::"text"[],
  "p_fits" "text"[] DEFAULT NULL::"text"[],
  "p_thicknesses" "text"[] DEFAULT NULL::"text"[],
  "p_styles" "text"[] DEFAULT NULL::"text"[],
  "p_seasons" "text"[] DEFAULT NULL::"text"[],
  "p_sort_column" "text" DEFAULT 'created_at'::"text",
  "p_sort_ascending" boolean DEFAULT false,
  "p_user_lat" double precision DEFAULT NULL::double precision,
  "p_user_lng" double precision DEFAULT NULL::double precision,
  "p_limit" integer DEFAULT NULL::integer,
  "p_offset" integer DEFAULT 0
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
          FROM product_sizes v
          WHERE v.product_id = p.id
        ),
        '[]'::jsonb
      ) AS product_sizes,
      jsonb_build_object(
        'id',             s.id,
        'name',           s.name,
        'address',        s.address,
        'logo_path',      s.logo_path,
        'channels',       s.channels,
        'order_contacts', COALESCE(s.order_contacts, '[]'::jsonb)
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
        p_materials IS NULL
        OR EXISTS (
            SELECT 1 FROM unnest(p_materials) AS m
            WHERE p.material ILIKE '%' || m || '%'
        )
      )
      AND (p_elasticities IS NULL OR p.elasticity = ANY(p_elasticities))
      AND (p_fits IS NULL OR p.fit = ANY(p_fits))
      AND (p_thicknesses IS NULL OR p.thickness = ANY(p_thicknesses))
      AND (p_styles IS NULL OR p.styles && p_styles)
      AND (p_seasons IS NULL OR p.seasons && p_seasons)
      AND (
        p_search_query IS NULL
        OR s.name ILIKE '%' || p_search_query || '%'
        OR COALESCE(
            (
                SELECT bool_and(p.name ILIKE '%' || token || '%')
                FROM unnest(string_to_array(trim(p_search_query), ' ')) AS token
                WHERE token <> ''
            ),
            false
        )
      )
    ORDER BY
      CASE
        WHEN p_sort_column = 'proximity'
             AND p_user_lat IS NOT NULL AND p_user_lng IS NOT NULL
             AND s.latitude IS NOT NULL AND s.longitude IS NOT NULL
        THEN 2 * 6371000 * asin(
               sqrt(
                 power(sin(radians(s.latitude - p_user_lat) / 2), 2)
                 + cos(radians(p_user_lat)) * cos(radians(s.latitude))
                   * power(sin(radians(s.longitude - p_user_lng) / 2), 2)
               )
             )
      END ASC NULLS LAST,
      CASE WHEN p_sort_column = 'price' AND     p_sort_ascending THEN p.price END ASC  NULLS LAST,
      CASE WHEN p_sort_column = 'price' AND NOT p_sort_ascending THEN p.price END DESC NULLS LAST,
      p.created_at DESC,
      p.id DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
$$;
