-- Products: publication status + soft delete.
--
-- Until now the only way for a store to take a product down was DELETE, and
-- analytics_events / analytics_product_monthly_summary both hang off products
-- with ON DELETE CASCADE — so removing one product silently rewrote that
-- store's historical view / try-on / purchase-click numbers, including months
-- already reported. Products referenced by historical records must not be hard
-- deleted.
--
-- Two columns, not one: `status` is the store owner's intent as a mutually
-- exclusive state (a product is either listed or not), `deleted_at` is a
-- timestamped fact that also dates the tombstone for any future purge. Folding
-- delete into `status` would lose the time; splitting `status` into nullable
-- timestamps would allow contradictory states no CHECK could express.
--
-- `status` is text + CHECK rather than a native enum deliberately: it is the
-- column most likely to gain values later (draft, scheduled), and per
-- supabase/CLAUDE.md an enum cannot take a value change in place. Adding a
-- value here is one constraint swap. 'sold_out' is intentionally NOT a value —
-- visible-but-unbuyable is a separate axis from listed-vs-unlisted, and mixing
-- them forces every read site to re-decide whether sold-out rows are included.
--
-- This migration is behaviour-neutral on its own: every existing row defaults
-- to 'active' with a NULL deleted_at, and the app still hard-deletes until the
-- client change ships. It only makes the states representable and makes sure
-- every read path already honours them.

ALTER TABLE "public"."products"
  ADD COLUMN "status" "text" NOT NULL DEFAULT 'active',
  ADD COLUMN "deleted_at" timestamp with time zone,
  ADD CONSTRAINT "products_status_check"
    CHECK (("status" = ANY (ARRAY['active'::"text", 'archived'::"text"])));

COMMENT ON COLUMN "public"."products"."status" IS 'Publication state: active, archived';
COMMENT ON COLUMN "public"."products"."deleted_at" IS 'Soft-delete tombstone; NULL means the product exists';

-- Shoppers see listed products; a store owner additionally sees their own
-- unlisted ones so the management list can offer them back. `deleted_at IS
-- NULL` sits outside the OR on purpose — a tombstone is invisible to its owner
-- too, which is what keeps the store-side listProducts query unchanged.
DROP POLICY "Anyone can view all products" ON "public"."products";

CREATE POLICY "Public sees active products, owners see their own"
  ON "public"."products" FOR SELECT
  USING (
    ("deleted_at" IS NULL)
    AND (
      ("status" = 'active'::"text")
      OR ("store_id" IN ( SELECT "store_profiles"."id"
           FROM "public"."store_profiles"
          WHERE ("store_profiles"."owner_id" = "auth"."uid"())))
    )
  );

-- The predicate goes in the body as well as the policy, and not because RLS
-- might be bypassed: every caller of this function reaches it on a client RLS
-- covers (`chat` on the caller's own, `liff-catalog` on anon). It is there
-- because the policy deliberately shows a store owner their own unlisted
-- products so the management list can offer them back — and this function is
-- the shopper-facing catalog, which must answer the same thing to everyone. An
-- owner browsing their own shop should not meet a product they took down.
--
-- So the two are not one rule stated twice: the policy decides what a caller
-- may read from the table, the body decides what this function means.
-- Same body as 20260724010000_products_single_category.sql otherwise.
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
      AND p.deleted_at IS NULL
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
