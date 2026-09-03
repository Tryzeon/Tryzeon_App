


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."product_gender" AS ENUM (
    'male',
    'female',
    'unisex'
);


ALTER TYPE "public"."product_gender" OWNER TO "postgres";


CREATE TYPE "public"."wardrobe_category" AS ENUM (
    'top',
    'pants',
    'skirt',
    'jacket',
    'shoes',
    'accessories',
    'others'
);


ALTER TYPE "public"."wardrobe_category" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_wardrobe_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
  current_count INTEGER;
  var_wardrobe_limit INTEGER;
BEGIN
  -- 1. 取得使用者對應方案的 wardrobe_limit (若無訂閱紀錄則預設為 'free' 方案)
  SELECT wardrobe_limit INTO var_wardrobe_limit
  FROM public.subscription_plans
  WHERE id = COALESCE(
    (SELECT plan FROM public.subscriptions WHERE user_id = NEW.user_id LIMIT 1),
    'free'
  );

  -- 2. 計算目前衣櫥裡的衣服數量
  SELECT COUNT(*) INTO current_count 
  FROM public.wardrobe_items 
  WHERE user_id = NEW.user_id;

  -- 3. 檢查是否超過上限
  IF current_count >= var_wardrobe_limit THEN
    RAISE EXCEPTION 'Wardrobe limit exceeded' USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."check_wardrobe_limit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_old_daily_usage"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- 刪除超過 30 天前的紀錄
  DELETE FROM public.user_daily_usage
  WHERE usage_date < CURRENT_DATE - INTERVAL '30 days';
END;
$$;


ALTER FUNCTION "public"."cleanup_old_daily_usage"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."decrement_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF p_feature_name = 'chat' THEN
    UPDATE public.user_daily_usage
    SET chat_count = chat_count - 1
    WHERE user_id = p_user_id
      AND usage_date = CURRENT_DATE
      AND chat_count > 0;

  ELSIF p_feature_name = 'tryon' THEN
    UPDATE public.user_daily_usage
    SET tryon_count = tryon_count - 1
    WHERE user_id = p_user_id
      AND usage_date = CURRENT_DATE
      AND tryon_count > 0;

  ELSIF p_feature_name = 'tryon_video' THEN
    UPDATE public.user_daily_usage
    SET video_count = video_count - 1
    WHERE user_id = p_user_id
      AND usage_date = CURRENT_DATE
      AND video_count > 0;

  ELSE
    RETURN FALSE;
  END IF;

  RETURN FOUND;
END;
$$;


ALTER FUNCTION "public"."decrement_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_orphan_avatar_images"() RETURNS TABLE("image_path" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  RETURN QUERY
  SELECT o.name::TEXT
  FROM storage.objects o
  WHERE o.bucket_id = 'user-avatars'
    AND NOT EXISTS (
      SELECT 1 FROM user_profiles u 
      WHERE u.avatar_path = o.name
    );
END;$$;


ALTER FUNCTION "public"."find_orphan_avatar_images"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_orphan_product_images"() RETURNS TABLE("image_path" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  RETURN QUERY
  SELECT o.name::text AS image_path
  FROM storage.objects o
  WHERE o.bucket_id = 'product-images'
  AND NOT EXISTS (
    SELECT 1 
    FROM public.products p 
    WHERE p.image_path = o.name
  );
END;$$;


ALTER FUNCTION "public"."find_orphan_product_images"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_orphan_store_logos"() RETURNS TABLE("image_path" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  RETURN QUERY
  SELECT o.name::text AS image_path
  FROM storage.objects o
  WHERE o.bucket_id = 'store-logos'
  AND NOT EXISTS (
    SELECT 1 
    FROM public.store_profiles s 
    WHERE s.logo_path = o.name
  );
END;$$;


ALTER FUNCTION "public"."find_orphan_store_logos"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_orphan_wardrobe_images"() RETURNS TABLE("image_path" "text", "bucket_id" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  RETURN QUERY
  SELECT o.name::TEXT, o.bucket_id::TEXT
  FROM storage.objects o
  WHERE o.bucket_id = 'wardrobe-images'
    AND NOT EXISTS (SELECT 1 FROM wardrobe_items w WHERE w.image_path = o.name);
END;$$;


ALTER FUNCTION "public"."find_orphan_wardrobe_images"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_shop_products"("p_store_id" "uuid" DEFAULT NULL::"uuid", "p_search_query" "text" DEFAULT NULL::"text", "p_category_ids" "text"[] DEFAULT NULL::"text"[], "p_min_price" integer DEFAULT NULL::integer, "p_max_price" integer DEFAULT NULL::integer, "p_channels" "text"[] DEFAULT NULL::"text"[], "p_gender" "public"."product_gender" DEFAULT NULL::"public"."product_gender", "p_wardrobe_category" "public"."wardrobe_category" DEFAULT NULL::"public"."wardrobe_category", "p_sort_column" "text" DEFAULT 'created_at'::"text", "p_sort_ascending" boolean DEFAULT false) RETURNS SETOF "jsonb"
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
      p.wardrobe_category,
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
      AND (p_wardrobe_category IS NULL OR p.wardrobe_category = p_wardrobe_category)
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


ALTER FUNCTION "public"."get_shop_products"("p_store_id" "uuid", "p_search_query" "text", "p_category_ids" "text"[], "p_min_price" integer, "p_max_price" integer, "p_channels" "text"[], "p_gender" "public"."product_gender", "p_wardrobe_category" "public"."wardrobe_category", "p_sort_column" "text", "p_sort_ascending" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  INSERT INTO public.user_profiles (user_id, name)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'full_name',
      NULLIF(split_part(NEW.email, '@', 1), ''),
      '使用者'
    )
  );
  
  INSERT INTO public.subscriptions (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_max_limit INT;
  v_today DATE := CURRENT_DATE;
  v_row public.user_daily_usage;
  v_allowed BOOLEAN := FALSE;
BEGIN
  -- 1. 驗證 feature_name
  IF p_feature_name NOT IN ('chat', 'tryon', 'tryon_video') THEN
    RETURN jsonb_build_object('allowed', false, 'usage', NULL);
  END IF;

  -- 2. 獲取該用戶當前方案的最高額度
  SELECT
    CASE
      WHEN p_feature_name = 'chat' THEN chat_limit
      WHEN p_feature_name = 'tryon' THEN tryon_limit
      WHEN p_feature_name = 'tryon_video' THEN video_limit
    END INTO v_max_limit
  FROM public.subscription_plans
  WHERE id = COALESCE(
    (SELECT plan FROM public.subscriptions WHERE user_id = p_user_id LIMIT 1),
    'free'
  );

  -- 優化 A：方案額度為 0 或找不到，直接拒絕，不消耗資料庫寫入效能。
  -- 仍要回傳當前 row（若存在），讓 client 能 sync UI。
  IF v_max_limit IS NULL OR v_max_limit <= 0 THEN
    SELECT * INTO v_row
      FROM public.user_daily_usage
      WHERE user_id = p_user_id AND usage_date = v_today;

    RETURN jsonb_build_object(
      'allowed', false,
      'usage', CASE WHEN v_row.user_id IS NULL
                    THEN NULL
                    ELSE row_to_json(v_row)::jsonb
                END
    );
  END IF;

  -- 3. 原子性檢查與遞增（使用 WHERE 條件限制，取代 rollback）
  --    加上 RETURNING * 讓我們同一條 statement 拿到 post-mutation row。
  IF p_feature_name = 'chat' THEN
    INSERT INTO public.user_daily_usage (user_id, usage_date, chat_count)
    VALUES (p_user_id, v_today, 1)
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET chat_count = user_daily_usage.chat_count + 1
    WHERE user_daily_usage.chat_count < v_max_limit
    RETURNING * INTO v_row;

  ELSIF p_feature_name = 'tryon' THEN
    INSERT INTO public.user_daily_usage (user_id, usage_date, tryon_count)
    VALUES (p_user_id, v_today, 1)
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET tryon_count = user_daily_usage.tryon_count + 1
    WHERE user_daily_usage.tryon_count < v_max_limit
    RETURNING * INTO v_row;

  ELSIF p_feature_name = 'tryon_video' THEN
    INSERT INTO public.user_daily_usage (user_id, usage_date, video_count)
    VALUES (p_user_id, v_today, 1)
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET video_count = user_daily_usage.video_count + 1
    WHERE user_daily_usage.video_count < v_max_limit
    RETURNING * INTO v_row;
  END IF;

  -- 4. 判斷結果並 fallback 取得 current row（被擋下的情況）
  IF FOUND THEN
    v_allowed := TRUE;
  ELSE
    -- 被擋下：撈當前 row 讓 client 能顯示「已滿格」
    SELECT * INTO v_row
      FROM public.user_daily_usage
      WHERE user_id = p_user_id AND usage_date = v_today;
  END IF;

  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'usage', CASE WHEN v_row.user_id IS NULL
                  THEN NULL
                  ELSE row_to_json(v_row)::jsonb
              END
  );
END;
$$;


ALTER FUNCTION "public"."increment_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."list_migration_objects"("p_buckets" "text"[], "p_offset" integer, "p_limit" integer) RETURNS TABLE("bucket_id" "text", "name" "text")
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'storage'
    AS $$
    select o.bucket_id::text, o.name::text
    from storage.objects o
    where o.bucket_id = any(p_buckets)
    order by o.bucket_id, o.name
    limit p_limit
    offset p_offset;
  $$;


ALTER FUNCTION "public"."list_migration_objects"("p_buckets" "text"[], "p_offset" integer, "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_analytics_events"("p_events" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  -- Insert all events from the JSON array
  insert into analytics_events (product_id, store_id, event_type, user_id)
  select 
    (event->>'product_id')::uuid,
    (event->>'store_id')::uuid,
    event->>'event_type',
    auth.uid()
  from jsonb_array_elements(p_events) as event;
end;
$$;


ALTER FUNCTION "public"."log_analytics_events"("p_events" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_analytics_summary"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$declare
  v_year int;
  v_month int;
begin
  -- Extract date parts
  v_year := extract(year from new.created_at);
  v_month := extract(month from new.created_at);

  -- Upsert (Insert or Update) into the per-product summary
  insert into analytics_product_monthly_summary (
    store_id, 
    product_id, 
    year, 
    month, 
    view_count, 
    tryon_count, 
    purchase_click_count
  )
  values (
    new.store_id, 
    new.product_id,
    v_year, 
    v_month, 
    case when new.event_type = 'view' then 1 else 0 end,
    case when new.event_type = 'try_on' then 1 else 0 end,
    case when new.event_type = 'purchase_click' then 1 else 0 end
  )
  on conflict (store_id, product_id, year, month)
  do update set 
    view_count = analytics_product_monthly_summary.view_count + excluded.view_count,
    tryon_count = analytics_product_monthly_summary.tryon_count + excluded.tryon_count,
    purchase_click_count = analytics_product_monthly_summary.purchase_click_count + excluded.purchase_click_count;

  return new;
end;$$;


ALTER FUNCTION "public"."update_analytics_summary"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."analytics_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "product_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."analytics_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."analytics_product_monthly_summary" (
    "store_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "year" integer NOT NULL,
    "month" integer NOT NULL,
    "view_count" integer DEFAULT 0 NOT NULL,
    "tryon_count" integer DEFAULT 0 NOT NULL,
    "purchase_click_count" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."analytics_product_monthly_summary" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_categories" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "priority" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "image_path" "text"
);


ALTER TABLE "public"."product_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_variants" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "product_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "measurements" "jsonb"
);


ALTER TABLE "public"."product_variants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "price" numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "purchase_link" "text",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "elasticity" "text",
    "fit" "text",
    "material" "text",
    "styles" "text"[],
    "category_ids" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "image_paths" "text"[] DEFAULT '{}'::"text"[],
    "thickness" "text",
    "seasons" "text"[],
    "gender" "public"."product_gender" DEFAULT 'unisex'::"public"."product_gender" NOT NULL,
    "wardrobe_category" "public"."wardrobe_category" NOT NULL,
    CONSTRAINT "check_elasticity" CHECK (("elasticity" = ANY (ARRAY['none'::"text", 'low'::"text", 'medium'::"text", 'high'::"text"]))),
    CONSTRAINT "products_seasons_valid_check" CHECK ((("seasons" IS NULL) OR ("seasons" <@ ARRAY['spring'::"text", 'summer'::"text", 'autumn'::"text", 'winter'::"text"]))),
    CONSTRAINT "products_thickness_check" CHECK (("thickness" = ANY (ARRAY['low'::"text", 'medium'::"text", 'high'::"text"])))
);


ALTER TABLE "public"."products" OWNER TO "postgres";


COMMENT ON COLUMN "public"."products"."elasticity" IS 'Elasticity level: none, low, medium, high';



COMMENT ON COLUMN "public"."products"."fit" IS 'Fit type: slim, regular, oversize';



COMMENT ON COLUMN "public"."products"."material" IS 'Material description (e.g. 100% Cotton)';



CREATE TABLE IF NOT EXISTS "public"."store_profiles" (
    "owner_id" "uuid" NOT NULL,
    "name" "text" DEFAULT '店家'::"text" NOT NULL,
    "address" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "logo_path" "text",
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "channels" "text"[] DEFAULT ARRAY['physical'::"text", 'online'::"text"] NOT NULL,
    CONSTRAINT "store_profiles_channels_check" CHECK ((("channels" <@ ARRAY['physical'::"text", 'online'::"text"]) AND ("array_length"("channels", 1) >= 1)))
);


ALTER TABLE "public"."store_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscription_plans" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "wardrobe_limit" integer NOT NULL,
    "tryon_limit" integer NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "chat_limit" integer NOT NULL,
    "video_limit" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."subscription_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "user_id" "uuid" NOT NULL,
    "plan" "text" DEFAULT 'free'::"text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_daily_usage" (
    "user_id" "uuid" NOT NULL,
    "usage_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "chat_count" integer DEFAULT 0 NOT NULL,
    "tryon_count" integer DEFAULT 0 NOT NULL,
    "video_count" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."user_daily_usage" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "avatar_path" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text",
    "measurements" "jsonb",
    "gender" "text",
    "style_preferences" "text"[],
    "is_onboarded" boolean DEFAULT false NOT NULL,
    "age" smallint,
    CONSTRAINT "user_profiles_age_check" CHECK ((("age" >= 0) AND ("age" <= 120)))
);


ALTER TABLE "public"."user_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wardrobe_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "category" "text" NOT NULL,
    "image_path" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."wardrobe_items" OWNER TO "postgres";


ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."analytics_product_monthly_summary"
    ADD CONSTRAINT "analytics_product_monthly_summary_pkey" PRIMARY KEY ("store_id", "product_id", "year", "month");



ALTER TABLE ONLY "public"."product_categories"
    ADD CONSTRAINT "product_categories_image_path_key" UNIQUE ("image_path");



ALTER TABLE ONLY "public"."product_variants"
    ADD CONSTRAINT "product_sizes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_categories"
    ADD CONSTRAINT "product_types_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_profiles"
    ADD CONSTRAINT "store_profile_owner_id_key" UNIQUE ("owner_id");



ALTER TABLE ONLY "public"."store_profiles"
    ADD CONSTRAINT "store_profile_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscribe_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."subscription_plans"
    ADD CONSTRAINT "subscription_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_daily_usage"
    ADD CONSTRAINT "user_daily_usage_pkey" PRIMARY KEY ("user_id", "usage_date");



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."wardrobe_items"
    ADD CONSTRAINT "wardrobe_items_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_apms_store_time" ON "public"."analytics_product_monthly_summary" USING "btree" ("store_id", "year", "month");



CREATE INDEX "idx_product_sizes_product_id" ON "public"."product_variants" USING "btree" ("product_id");



CREATE INDEX "idx_products_category_ids" ON "public"."products" USING "gin" ("category_ids");



CREATE INDEX "idx_products_gender" ON "public"."products" USING "btree" ("gender");



CREATE INDEX "idx_products_store_id" ON "public"."products" USING "btree" ("store_id");



CREATE INDEX "idx_products_wardrobe_category" ON "public"."products" USING "btree" ("wardrobe_category");



CREATE INDEX "idx_user_daily_usage_date" ON "public"."user_daily_usage" USING "btree" ("usage_date");



CREATE INDEX "idx_wardrobe_items_category" ON "public"."wardrobe_items" USING "btree" ("user_id", "category");



CREATE INDEX "idx_wardrobe_items_created_at" ON "public"."wardrobe_items" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "store_profiles_channels_idx" ON "public"."store_profiles" USING "gin" ("channels");



CREATE OR REPLACE TRIGGER "enforce_wardrobe_limit" BEFORE INSERT ON "public"."wardrobe_items" FOR EACH ROW EXECUTE FUNCTION "public"."check_wardrobe_limit"();



CREATE OR REPLACE TRIGGER "on_analytics_event_inserted" AFTER INSERT ON "public"."analytics_events" FOR EACH ROW EXECUTE FUNCTION "public"."update_analytics_summary"();



CREATE OR REPLACE TRIGGER "trg_product_variants_updated_at" BEFORE UPDATE ON "public"."product_variants" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_products_updated_at" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_store_profiles_updated_at" BEFORE UPDATE ON "public"."store_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_subscriptions_updated_at" BEFORE UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_user_profiles_updated_at" BEFORE UPDATE ON "public"."user_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_wardrobe_items_updated_at" BEFORE UPDATE ON "public"."wardrobe_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."store_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analytics_product_monthly_summary"
    ADD CONSTRAINT "analytics_product_monthly_summary_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analytics_product_monthly_summary"
    ADD CONSTRAINT "analytics_product_monthly_summary_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."store_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "fk_subscription_plan" FOREIGN KEY ("plan") REFERENCES "public"."subscription_plans"("id");



ALTER TABLE ONLY "public"."product_variants"
    ADD CONSTRAINT "product_sizes_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."store_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."store_profiles"
    ADD CONSTRAINT "store_profile_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscribe_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_daily_usage"
    ADD CONSTRAINT "user_daily_usage_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wardrobe_items"
    ADD CONSTRAINT "wardrobe_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Anyone can read plans" ON "public"."subscription_plans" FOR SELECT USING (true);



CREATE POLICY "Anyone can read product types" ON "public"."product_categories" FOR SELECT USING (true);



CREATE POLICY "Anyone can view all product sizes" ON "public"."product_variants" FOR SELECT USING (true);



CREATE POLICY "Anyone can view all products" ON "public"."products" FOR SELECT USING (true);



CREATE POLICY "Anyone can view store info" ON "public"."store_profiles" FOR SELECT USING (true);



CREATE POLICY "Store owners can read their own product analytics" ON "public"."analytics_product_monthly_summary" FOR SELECT USING (("store_id" IN ( SELECT "store_profiles"."id"
   FROM "public"."store_profiles"
  WHERE ("store_profiles"."owner_id" = "auth"."uid"()))));



CREATE POLICY "Stores can delete products from their store" ON "public"."products" FOR DELETE USING (("store_id" IN ( SELECT "store_profiles"."id"
   FROM "public"."store_profiles"
  WHERE ("store_profiles"."owner_id" = "auth"."uid"()))));



CREATE POLICY "Stores can delete sizes for their products" ON "public"."product_variants" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM ("public"."products"
     JOIN "public"."store_profiles" ON (("products"."store_id" = "store_profiles"."id")))
  WHERE (("products"."id" = "product_variants"."product_id") AND ("store_profiles"."owner_id" = "auth"."uid"())))));



CREATE POLICY "Stores can insert products for their store" ON "public"."products" FOR INSERT WITH CHECK (("store_id" IN ( SELECT "store_profiles"."id"
   FROM "public"."store_profiles"
  WHERE ("store_profiles"."owner_id" = "auth"."uid"()))));



CREATE POLICY "Stores can insert sizes for their products" ON "public"."product_variants" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."products"
     JOIN "public"."store_profiles" ON (("products"."store_id" = "store_profiles"."id")))
  WHERE (("products"."id" = "product_variants"."product_id") AND ("store_profiles"."owner_id" = "auth"."uid"())))));



CREATE POLICY "Stores can update products from their store" ON "public"."products" FOR UPDATE USING (("store_id" IN ( SELECT "store_profiles"."id"
   FROM "public"."store_profiles"
  WHERE ("store_profiles"."owner_id" = "auth"."uid"()))));



CREATE POLICY "Stores can update sizes for their products" ON "public"."product_variants" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM ("public"."products"
     JOIN "public"."store_profiles" ON (("products"."store_id" = "store_profiles"."id")))
  WHERE (("products"."id" = "product_variants"."product_id") AND ("store_profiles"."owner_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete their own wardrobe items" ON "public"."wardrobe_items" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own wardrobe items" ON "public"."wardrobe_items" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own profile" ON "public"."user_profiles" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own profile" ON "public"."user_profiles" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own store" ON "public"."store_profiles" FOR UPDATE USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "Users can update their own wardrobe items" ON "public"."wardrobe_items" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own daily usage" ON "public"."user_daily_usage" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own subscription" ON "public"."subscriptions" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own wardrobe items" ON "public"."wardrobe_items" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."analytics_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."analytics_product_monthly_summary" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_variants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscription_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_daily_usage" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wardrobe_items" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";














































































































































































GRANT ALL ON FUNCTION "public"."check_wardrobe_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_wardrobe_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_wardrobe_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_daily_usage"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_daily_usage"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_daily_usage"() TO "service_role";



GRANT ALL ON FUNCTION "public"."decrement_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."decrement_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrement_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."find_orphan_avatar_images"() TO "anon";
GRANT ALL ON FUNCTION "public"."find_orphan_avatar_images"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_orphan_avatar_images"() TO "service_role";



GRANT ALL ON FUNCTION "public"."find_orphan_product_images"() TO "anon";
GRANT ALL ON FUNCTION "public"."find_orphan_product_images"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_orphan_product_images"() TO "service_role";



GRANT ALL ON FUNCTION "public"."find_orphan_store_logos"() TO "anon";
GRANT ALL ON FUNCTION "public"."find_orphan_store_logos"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_orphan_store_logos"() TO "service_role";



GRANT ALL ON FUNCTION "public"."find_orphan_wardrobe_images"() TO "anon";
GRANT ALL ON FUNCTION "public"."find_orphan_wardrobe_images"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_orphan_wardrobe_images"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_shop_products"("p_store_id" "uuid", "p_search_query" "text", "p_category_ids" "text"[], "p_min_price" integer, "p_max_price" integer, "p_channels" "text"[], "p_gender" "public"."product_gender", "p_wardrobe_category" "public"."wardrobe_category", "p_sort_column" "text", "p_sort_ascending" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."get_shop_products"("p_store_id" "uuid", "p_search_query" "text", "p_category_ids" "text"[], "p_min_price" integer, "p_max_price" integer, "p_channels" "text"[], "p_gender" "public"."product_gender", "p_wardrobe_category" "public"."wardrobe_category", "p_sort_column" "text", "p_sort_ascending" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_shop_products"("p_store_id" "uuid", "p_search_query" "text", "p_category_ids" "text"[], "p_min_price" integer, "p_max_price" integer, "p_channels" "text"[], "p_gender" "public"."product_gender", "p_wardrobe_category" "public"."wardrobe_category", "p_sort_column" "text", "p_sort_ascending" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."increment_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_feature_usage"("p_user_id" "uuid", "p_feature_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_migration_objects"("p_buckets" "text"[], "p_offset" integer, "p_limit" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_migration_objects"("p_buckets" "text"[], "p_offset" integer, "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."log_analytics_events"("p_events" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_analytics_events"("p_events" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_analytics_events"("p_events" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_analytics_summary"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_analytics_summary"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_analytics_summary"() TO "service_role";
























GRANT ALL ON TABLE "public"."analytics_events" TO "anon";
GRANT ALL ON TABLE "public"."analytics_events" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_events" TO "service_role";



GRANT ALL ON TABLE "public"."analytics_product_monthly_summary" TO "anon";
GRANT ALL ON TABLE "public"."analytics_product_monthly_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_product_monthly_summary" TO "service_role";



GRANT ALL ON TABLE "public"."product_categories" TO "anon";
GRANT ALL ON TABLE "public"."product_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."product_categories" TO "service_role";



GRANT ALL ON TABLE "public"."product_variants" TO "anon";
GRANT ALL ON TABLE "public"."product_variants" TO "authenticated";
GRANT ALL ON TABLE "public"."product_variants" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."store_profiles" TO "anon";
GRANT ALL ON TABLE "public"."store_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."store_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."subscription_plans" TO "anon";
GRANT ALL ON TABLE "public"."subscription_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."subscription_plans" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."user_daily_usage" TO "anon";
GRANT ALL ON TABLE "public"."user_daily_usage" TO "authenticated";
GRANT ALL ON TABLE "public"."user_daily_usage" TO "service_role";



GRANT ALL ON TABLE "public"."user_profiles" TO "anon";
GRANT ALL ON TABLE "public"."user_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."wardrobe_items" TO "anon";
GRANT ALL ON TABLE "public"."wardrobe_items" TO "authenticated";
GRANT ALL ON TABLE "public"."wardrobe_items" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































drop extension if exists "pg_net";

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


  create policy "Give users access to own folder 1oj01fe_0"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Give users access to own folder 1oj01fe_1"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Give users access to own folder 1oj01fe_2"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Give users access to own folder 1oj01fe_3"
  on "storage"."objects"
  as permissive
  for update
  to public
using (((bucket_id = 'avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Owner Access Logos"
  on "storage"."objects"
  as permissive
  for all
  to public
using (((bucket_id = 'store_logos'::text) AND (auth.role() = 'authenticated'::text) AND ((storage.foldername(name))[1] IN ( SELECT (store_profiles.id)::text AS id
   FROM public.store_profiles
  WHERE (store_profiles.owner_id = auth.uid())))));



  create policy "Owner Access Products"
  on "storage"."objects"
  as permissive
  for all
  to public
using (((bucket_id = 'store_products'::text) AND (auth.role() = 'authenticated'::text) AND ((storage.foldername(name))[1] IN ( SELECT (store_profiles.id)::text AS id
   FROM public.store_profiles
  WHERE (store_profiles.owner_id = auth.uid())))));



  create policy "Product Images - Owner Access"
  on "storage"."objects"
  as permissive
  for all
  to public
using (((bucket_id = 'product-images'::text) AND (auth.role() = 'authenticated'::text) AND ((storage.foldername(name))[1] IN ( SELECT (store_profiles.id)::text AS id
   FROM public.store_profiles
  WHERE (store_profiles.owner_id = auth.uid())))));



  create policy "Product Images - Public Read"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'product-images'::text));



  create policy "Public Access Logos"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'store_logos'::text));



  create policy "Public Access Products"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'store_products'::text));



  create policy "User Avatars - Delete Own"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'user-avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "User Avatars - Insert Own"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'user-avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "User Avatars - Select Own"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'user-avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "User Avatars - Update Own"
  on "storage"."objects"
  as permissive
  for update
  to public
using (((bucket_id = 'user-avatars'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Wardrobe - Delete Own"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'wardrobe-images'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Wardrobe - Insert Own"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'wardrobe-images'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Wardrobe - Select Own"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'wardrobe-images'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



  create policy "Wardrobe - Update Own"
  on "storage"."objects"
  as permissive
  for update
  to public
using (((bucket_id = 'wardrobe-images'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1])));



