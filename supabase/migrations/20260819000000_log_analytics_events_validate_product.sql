-- Move the product check that the dropped FKs were doing into the RPC.
--
-- 20260818000000 dropped analytics_events_product_id_fkey so summary rows can
-- outlive the products they counted. That also removed the only thing checking
-- that an event named a real product: log_analytics_events is SECURITY DEFINER
-- and inserted (event->>'product_id')::uuid straight from the client payload.
-- Since product_id is part of analytics_product_monthly_summary's primary key,
-- every unrecognised id minted a fresh summary row under a real store_id and
-- inflated that store's dashboard totals.
--
-- Validating at write time keeps 20260818's intent intact: the product has to
-- exist when the event is logged, and deleting it later still leaves the
-- counters alone. Joining on the pair also makes products the authority on
-- store_id, so a payload can no longer attribute one store's product to
-- another. Invalid rows are dropped rather than raising: events arrive in
-- client batches, and a product deleted between view and flush is a normal
-- race that should not discard the rest of the batch.
--
-- No backfill: after 20260818 a dangling product_id is the intended state for a
-- legitimately deleted product, so existing orphans can't be told apart from
-- junk and are left alone.

CREATE OR REPLACE FUNCTION "public"."log_analytics_events"("p_events" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" = "public"
    AS $$
begin
  insert into analytics_events (product_id, store_id, event_type, user_id)
  select
    p.id,
    p.store_id,
    event->>'event_type',
    auth.uid()
  from jsonb_array_elements(p_events) as event
  join products p
    on p.id = (event->>'product_id')::uuid
   and p.store_id = (event->>'store_id')::uuid;
end;
$$;
