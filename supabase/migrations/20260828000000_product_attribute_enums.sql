-- products / store_profiles closed vocabularies: text + CHECK -> native enums.
--
-- These five vocabularies are facts, not policy: there are four seasons, a
-- garment is stretchy or it is not, a store sells in a shop or online. None of
-- them is expected to gain a value, which is the only property that makes an
-- enum the right shape here — `products.status` is deliberately left as text +
-- CHECK for exactly the opposite reason (see 20260814000000).
--
-- Declaration order is the semantic order, not alphabetical, so `ORDER BY
-- elasticity` reads none -> high for free.
--
-- The payoff is not in the database. The same vocabularies are written out by
-- hand in the app's Dart enums and in the edge functions; a native enum is what
-- `supabase gen types typescript` can turn into a union type, which collapses
-- the TypeScript copy into a derived one.

CREATE TYPE "public"."product_elasticity" AS ENUM ('none', 'low', 'medium', 'high');
CREATE TYPE "public"."product_thickness"  AS ENUM ('low', 'medium', 'high');
CREATE TYPE "public"."product_fit"        AS ENUM ('slim', 'regular', 'loose', 'oversize');
CREATE TYPE "public"."product_season"     AS ENUM ('spring', 'summer', 'autumn', 'winter');
CREATE TYPE "public"."store_channel"      AS ENUM ('physical', 'online');

-- Dropped before the columns change, recreated after. A `LANGUAGE sql` body
-- written as a string literal is not a tracked dependency, so the ALTERs below
-- would succeed and leave a function that fails at its next call. The signature
-- has to change regardless: five parameters become enum arrays.
DROP FUNCTION "public"."list_shop_products"(
  "uuid", "text", "text"[], integer, integer, "text"[],
  "public"."product_gender", "text"[], "text"[], "text"[], "text"[],
  "text"[], "text"[], "text", boolean, double precision, double precision, integer, integer
);

ALTER TABLE "public"."products" DROP CONSTRAINT "check_elasticity";
ALTER TABLE "public"."products" DROP CONSTRAINT "products_thickness_check";
ALTER TABLE "public"."products" DROP CONSTRAINT "products_fit_check";
ALTER TABLE "public"."products" DROP CONSTRAINT "products_seasons_valid_check";

ALTER TABLE "public"."products"
  ALTER COLUMN "elasticity" TYPE "public"."product_elasticity"
    USING "elasticity"::"public"."product_elasticity",
  ALTER COLUMN "thickness" TYPE "public"."product_thickness"
    USING "thickness"::"public"."product_thickness",
  ALTER COLUMN "fit" TYPE "public"."product_fit"
    USING "fit"::"public"."product_fit",
  ALTER COLUMN "seasons" TYPE "public"."product_season"[]
    USING "seasons"::"public"."product_season"[];

-- The column comments spelled the vocabulary out a fourth time. The type is now
-- the documentation, and a comment that can drift from it is worse than none.
COMMENT ON COLUMN "public"."products"."elasticity" IS NULL;
COMMENT ON COLUMN "public"."products"."fit" IS NULL;

-- channels carries a DEFAULT, so the order is forced: a default expression of
-- the old type blocks the type change.
ALTER TABLE "public"."store_profiles" ALTER COLUMN "channels" DROP DEFAULT;
ALTER TABLE "public"."store_profiles" DROP CONSTRAINT "store_profiles_channels_check";

ALTER TABLE "public"."store_profiles"
  ALTER COLUMN "channels" TYPE "public"."store_channel"[]
  USING "channels"::"public"."store_channel"[];

ALTER TABLE "public"."store_profiles"
  ALTER COLUMN "channels"
  SET DEFAULT ARRAY['physical', 'online']::"public"."store_channel"[];

-- The old constraint carried two rules. The enum takes over the value domain;
-- the length rule has no other home and a store with zero channels is still
-- meaningless.
ALTER TABLE "public"."store_profiles"
  ADD CONSTRAINT "store_profiles_channels_nonempty_check"
  CHECK (("array_length"("channels", 1) >= 1));

-- Same body as 20260818000000_products_hard_delete.sql. Only the five filter
-- parameter types change; every predicate is unchanged. PostgREST sends RPC
-- arguments as JSON strings and Postgres casts them, so no caller changes.
CREATE OR REPLACE FUNCTION "public"."list_shop_products"(
  "p_store_id" "uuid" DEFAULT NULL::"uuid",
  "p_search_query" "text" DEFAULT NULL::"text",
  "p_category_ids" "text"[] DEFAULT NULL::"text"[],
  "p_min_price" integer DEFAULT NULL::integer,
  "p_max_price" integer DEFAULT NULL::integer,
  "p_channels" "public"."store_channel"[] DEFAULT NULL::"public"."store_channel"[],
  "p_gender" "public"."product_gender" DEFAULT NULL::"public"."product_gender",
  "p_materials" "text"[] DEFAULT NULL::"text"[],
  "p_elasticities" "public"."product_elasticity"[] DEFAULT NULL::"public"."product_elasticity"[],
  "p_fits" "public"."product_fit"[] DEFAULT NULL::"public"."product_fit"[],
  "p_thicknesses" "public"."product_thickness"[] DEFAULT NULL::"public"."product_thickness"[],
  "p_styles" "text"[] DEFAULT NULL::"text"[],
  "p_seasons" "public"."product_season"[] DEFAULT NULL::"public"."product_season"[],
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

-- DROP FUNCTION took the owner and grants with it.
ALTER FUNCTION "public"."list_shop_products"(
  "uuid", "text", "text"[], integer, integer, "public"."store_channel"[],
  "public"."product_gender", "text"[], "public"."product_elasticity"[], "public"."product_fit"[],
  "public"."product_thickness"[], "text"[], "public"."product_season"[], "text", boolean,
  double precision, double precision, integer, integer
) OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."list_shop_products"(
  "uuid", "text", "text"[], integer, integer, "public"."store_channel"[],
  "public"."product_gender", "text"[], "public"."product_elasticity"[], "public"."product_fit"[],
  "public"."product_thickness"[], "text"[], "public"."product_season"[], "text", boolean,
  double precision, double precision, integer, integer
) TO "anon";

GRANT ALL ON FUNCTION "public"."list_shop_products"(
  "uuid", "text", "text"[], integer, integer, "public"."store_channel"[],
  "public"."product_gender", "text"[], "public"."product_elasticity"[], "public"."product_fit"[],
  "public"."product_thickness"[], "text"[], "public"."product_season"[], "text", boolean,
  double precision, double precision, integer, integer
) TO "authenticated";

GRANT ALL ON FUNCTION "public"."list_shop_products"(
  "uuid", "text", "text"[], integer, integer, "public"."store_channel"[],
  "public"."product_gender", "text"[], "public"."product_elasticity"[], "public"."product_fit"[],
  "public"."product_thickness"[], "text"[], "public"."product_season"[], "text", boolean,
  double precision, double precision, integer, integer
) TO "service_role";
