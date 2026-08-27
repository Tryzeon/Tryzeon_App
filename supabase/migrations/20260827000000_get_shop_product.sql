-- One definition of "a product a shopper can act on".
--
-- `list_shop_products` already states it in its body (`p.status = 'active'`),
-- and two single-row read sites restated it as `.eq("status", "active")` on
-- the caller — `_shared/tryon/catalog.ts` and `line-webhook/product-card.ts`.
-- One rule, three knowers.
--
-- RLS cannot be that one place. The `products` SELECT policy is
-- `status = 'active' OR I own the store`, and the second arm is deliberate: a
-- store owner must see their own unlisted products so the management list can
-- offer them back. A shopper-facing read must answer the same thing to
-- everyone, owner included — the same reason `list_shop_products` carries the
-- predicate in its body rather than leaning on the policy. And `line-webhook`
-- reads on the service-role client, where RLS does not apply at all.
--
-- So the single knower is a function. SECURITY INVOKER (the default): the
-- policy still bounds what a caller may read, this body decides what the
-- function means.
--
-- Returns a scalar `jsonb`, not `SETOF`: a miss is SQL NULL, so `.rpc()` hands
-- back `data: null` and both callers keep the shape their `.maybeSingle()`
-- had.
--
-- The column list is the union of what the two callers project. Deliberately
-- not `list_shop_products`'s projection: its `product_sizes` aggregate and geo
-- columns are dead weight on a single-row lookup, and its parameter list is
-- already nineteen long.

CREATE OR REPLACE FUNCTION "public"."get_shop_product"("p_id" "uuid")
RETURNS "jsonb"
LANGUAGE "sql" STABLE
AS $$
  SELECT to_jsonb(t) FROM (
    SELECT
      p.id,
      p.name,
      p.price,
      p.image_paths,
      p.purchase_link,
      p.material,
      p.elasticity,
      p.fit,
      p.thickness,
      jsonb_build_object('name', s.name) AS store_profiles
    FROM products p
    JOIN store_profiles s ON s.id = p.store_id
    WHERE p.id = p_id
      AND p.status = 'active'
  ) t;
$$;

COMMENT ON FUNCTION "public"."get_shop_product"("uuid") IS
  'One shopper-visible product by id, or NULL. The single definition of "active" for single-row reads.';

GRANT ALL ON FUNCTION "public"."get_shop_product"("uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_shop_product"("uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_shop_product"("uuid") TO "service_role";
