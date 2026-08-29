-- user_profiles.gender and analytics_events.event_type: bare text -> native enums.
--
-- Unlike the product attributes in 20260828000000, these two never had a CHECK
-- at all. `event_type` in particular is compared as a string literal by
-- update_analytics_summary() to decide which counter to increment, so a typo
-- has always been able to write a row that increments nothing and is invisible
-- in every report. The enum is the first thing that makes that impossible.
--
-- Each conversion is preceded by a validation block. `ALTER COLUMN ... USING`
-- would fail on a bad row anyway, but it fails with a cast error that names the
-- value and nothing else; this names the column and lists every offender at
-- once, which is what someone reading a failed deploy needs.

CREATE TYPE "public"."user_gender" AS ENUM ('female', 'male');
CREATE TYPE "public"."analytics_event_type" AS ENUM ('view', 'try_on', 'purchase_click');

-- `female` and `male` were not the whole vocabulary until 4058231d
-- (2026-04-22, "simplify gender enum to binary options"): before that, the
-- app's `Gender` enum also shipped `non_binary` and `undisclosed`, and this
-- column has never had a CHECK to stop either from being written. Every read
-- since has gone through `Gender.tryFromString`, which returns null for both,
-- so a profile carrying one of these has already been treated as having no
-- gender on every path that reads it. Writing that into the column changes
-- nothing anyone can observe.
UPDATE "public"."user_profiles" SET "gender" = NULL
WHERE "gender" IS NOT NULL AND "gender" NOT IN ('female', 'male');

DO $$
DECLARE
  bad "text";
BEGIN
  SELECT string_agg(DISTINCT quote_literal("gender"), ', ') INTO bad
  FROM "public"."user_profiles"
  WHERE "gender" IS NOT NULL AND "gender" NOT IN ('female', 'male');

  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'user_profiles.gender holds values outside user_gender: %', bad;
  END IF;
END $$;

ALTER TABLE "public"."user_profiles"
  ALTER COLUMN "gender" TYPE "public"."user_gender"
  USING "gender"::"public"."user_gender";

DO $$
DECLARE
  bad "text";
BEGIN
  SELECT string_agg(DISTINCT quote_literal("event_type"), ', ') INTO bad
  FROM "public"."analytics_events"
  WHERE "event_type" NOT IN ('view', 'try_on', 'purchase_click');

  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'analytics_events.event_type holds values outside analytics_event_type: %', bad;
  END IF;
END $$;

ALTER TABLE "public"."analytics_events"
  ALTER COLUMN "event_type" TYPE "public"."analytics_event_type"
  USING "event_type"::"public"."analytics_event_type";

-- update_analytics_summary() needs no change: `new.event_type = 'view'` resolves
-- the untyped literal against the column's type, enum or text.

-- log_analytics_events does. `event->>'event_type'` is text, and casting it
-- straight into the enum column would make one unrecognised value abort the
-- whole client batch. 20260819000000 chose the opposite behaviour deliberately
-- ("a product deleted between view and flush is a normal race that should not
-- discard the rest of the batch"), so an unknown event type is filtered out the
-- same way an unknown product id already is: quietly, one row at a time.
CREATE OR REPLACE FUNCTION "public"."log_analytics_events"("p_events" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" = "public"
    AS $$
begin
  insert into analytics_events (product_id, store_id, event_type, user_id)
  select
    p.id,
    p.store_id,
    (event->>'event_type')::analytics_event_type,
    auth.uid()
  from jsonb_array_elements(p_events) as event
  join products p
    on p.id = (event->>'product_id')::uuid
   and p.store_id = (event->>'store_id')::uuid
  where event->>'event_type' = ANY(enum_range(NULL::analytics_event_type)::text[]);
end;
$$;
