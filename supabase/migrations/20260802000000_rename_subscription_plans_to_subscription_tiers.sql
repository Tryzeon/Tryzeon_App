-- subscription_plans holds no pricing or billing period (those live in RevenueCat),
-- only per-tier quotas keyed by entitlement id. Rename it to what it is.

ALTER TABLE public.subscription_plans RENAME TO subscription_tiers;

ALTER TABLE public.subscription_tiers
  RENAME CONSTRAINT subscription_plans_pkey TO subscription_tiers_pkey;

-- name / sort_order / is_active only ever supported listing plans, and the app
-- never lists: it fetches one row by tier id. is_active is worse than dead —
-- flipping it false on a tier a user occupies makes the client's .single() throw.
ALTER TABLE public.subscription_tiers
  DROP COLUMN name,
  DROP COLUMN sort_order,
  DROP COLUMN is_active;

ALTER TABLE public.subscriptions RENAME COLUMN plan TO tier;

ALTER TABLE public.subscriptions
  RENAME CONSTRAINT fk_subscription_plan TO fk_subscription_tier;

ALTER POLICY "Anyone can read plans" ON public.subscription_tiers
  RENAME TO "Anyone can read subscription tiers";

-- plpgsql bodies are stored as text, so ALTER TABLE ... RENAME does not rewrite
-- them. Both readers must be recreated.

CREATE OR REPLACE FUNCTION public.check_wardrobe_limit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  current_count INTEGER;
  var_wardrobe_limit INTEGER;
BEGIN
  -- 1. Read the wardrobe_limit of the user's tier (defaults to the 'free' tier
  --    when there is no subscription row)
  SELECT wardrobe_limit INTO var_wardrobe_limit
  FROM public.subscription_tiers
  WHERE id = COALESCE(
    (SELECT tier FROM public.subscriptions WHERE user_id = NEW.user_id LIMIT 1),
    'free'
  );

  -- 2. Count the items currently in the wardrobe
  SELECT COUNT(*) INTO current_count
  FROM public.wardrobe_items
  WHERE user_id = NEW.user_id;

  -- 3. Check whether the limit is exceeded
  IF current_count >= var_wardrobe_limit THEN
    RAISE EXCEPTION 'Wardrobe limit exceeded' USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;$$;

CREATE OR REPLACE FUNCTION public.increment_feature_usage("p_user_id" uuid, "p_feature_name" text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_max_limit INT;
  v_today DATE := CURRENT_DATE;
  v_row public.user_daily_usage;
  v_allowed BOOLEAN := FALSE;
BEGIN
  -- 1. Validate feature_name
  IF p_feature_name NOT IN ('chat', 'tryon', 'tryon_video') THEN
    RETURN jsonb_build_object('allowed', false, 'usage', NULL);
  END IF;

  -- 2. Read the limit of the user's current tier
  SELECT
    CASE
      WHEN p_feature_name = 'chat' THEN chat_limit
      WHEN p_feature_name = 'tryon' THEN tryon_limit
      WHEN p_feature_name = 'tryon_video' THEN video_limit
    END INTO v_max_limit
  FROM public.subscription_tiers
  WHERE id = COALESCE(
    (SELECT tier FROM public.subscriptions WHERE user_id = p_user_id LIMIT 1),
    'free'
  );

  -- Optimization A: a tier limit of 0 or no tier at all is rejected outright,
  -- without spending a database write. The current row is still returned (when
  -- one exists) so the client can sync its UI.
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

  -- 3. Atomic check-and-increment (a WHERE condition instead of a rollback),
  --    with RETURNING * so the post-mutation row comes back in the same
  --    statement.
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

  -- 4. Interpret the result, falling back to the current row when blocked
  IF FOUND THEN
    v_allowed := TRUE;
  ELSE
    -- Blocked: fetch the current row so the client can show the quota as full
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
