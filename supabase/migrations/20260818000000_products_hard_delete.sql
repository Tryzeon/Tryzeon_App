-- Products go back to being hard-deleted; analytics stops depending on them.
--
-- 20260814000000 added `deleted_at` to stop DELETE from cascading away a
-- store's reported history. That fixed the symptom at the wrong layer: the
-- problem was never the delete, it was that a fact table hung off a dimension
-- row with ON DELETE CASCADE. `analytics_product_monthly_summary` is where the
-- counters actually accumulate (update_analytics_summary() upserts into it on
-- every event), and the dashboard reports store-level totals by summing those
-- rows at read time — so cascading one product's rows away retroactively shrank
-- months that had already been reported.
--
-- Dropping the constraints instead lets the summary behave like the
-- append-only fact table it is: a row keeps its counts whether or not the
-- product it counted still exists. `product_id` is part of the summary's
-- primary key, so ON DELETE SET NULL is not available — the constraint has to
-- go entirely, and a dangling product_id is the accepted cost. The reports are
-- store-level totals, so nothing needs to resolve that id.
--
-- If per-product reporting is ever wanted, the cheap fix is a denormalised
-- `product_name` written by the summary trigger on insert — a fact table that
-- carries what it needs is the standard shape, and it works for deleted
-- products too. Not added now because nothing reads per-product yet.
--
-- `status` stays. Unlisting a product and deleting it are different things, and
-- only the second one is being reverted here.

ALTER TABLE "public"."analytics_product_monthly_summary"
  DROP CONSTRAINT "analytics_product_monthly_summary_product_id_fkey";

-- The raw event log goes the same way, so the summary can still be rebuilt
-- from it. Leaving this one cascading would have deleted the evidence behind
-- counters that now survive, which is a worse inconsistency than a dangling id.
ALTER TABLE "public"."analytics_events"
  DROP CONSTRAINT "analytics_events_product_id_fkey";

-- Replace the policy before dropping the column: an RLS policy referencing a
-- column is a real dependency and the DROP would otherwise be refused.
DROP POLICY "Public sees active products, owners see their own" ON "public"."products";

CREATE POLICY "Public sees active products, owners see their own"
  ON "public"."products" FOR SELECT
  USING (
    ("status" = 'active'::"text")
    OR ("store_id" IN ( SELECT "store_profiles"."id"
         FROM "public"."store_profiles"
        WHERE ("store_profiles"."owner_id" = "auth"."uid"())))
  );

-- Any row already tombstoned carried a store owner's intent to delete it.
-- Honour that rather than resurrecting it — and do it after the constraints
-- above are gone, so these deletes no longer take the analytics with them.
-- Expected to affect zero rows: the client change that writes `deleted_at`
-- never shipped.
DELETE FROM "public"."products" WHERE "deleted_at" IS NOT NULL;

ALTER TABLE "public"."products" DROP COLUMN "deleted_at";

-- Rebuild list_shop_products without the tombstone predicate. `status` stays:
-- the policy deliberately shows an owner their own unlisted products so the
-- management list can offer them back, while this function is the shopper-
-- facing catalog and must answer the same thing to everyone.
-- Same body as 20260814000000_products_status_and_soft_delete.sql otherwise.
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
      p.category_id,
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
      p.status = 'active'
      AND (p_store_id IS NULL OR p.store_id = p_store_id)
      AND (p_category_ids IS NULL OR p.category_id = ANY((p_category_ids)::uuid[]))
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
