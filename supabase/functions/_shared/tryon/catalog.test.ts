import { assertEquals, assertRejects } from "jsr:@std/assert";
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { buildProductGarmentDetail, resolveProductGarment } from "./catalog.ts";
import { LIMITS } from "./types.ts";
import { ValidationError } from "./errors.ts";

const PRODUCT_ID = "11111111-1111-1111-1111-111111111111";
const SIZE_ID = "22222222-2222-2222-2222-222222222222";

interface LookupStub {
  row: Record<string, unknown> | null;
  error?: { message: string };
}

/**
 * Fake client recording every `.eq()` applied per table (keyed by table name,
 * since `resolveProductGarment` queries both `products` and `product_sizes`),
 * so a test can prove a filter actually reached the query rather than merely
 * trusting the code. `maybeSingle()` re-checks the recorded filters against the
 * row instead of just recording them — without that, deleting a filter would
 * leave a security test still passing. Same property as `wardrobe.test.ts`'s
 * `fakeAdmin`, generalized to more than one table.
 */
function fakeAdmin(stubs: Record<string, LookupStub>) {
  const filters: Record<string, Array<[string, string]>> = {};
  const admin = {
    from: (table: string) => {
      const tableFilters: Array<[string, string]> = [];
      filters[table] = tableFilters;
      return {
        select: () => {
          const chain = {
            eq: (column: string, value: string) => {
              tableFilters.push([column, value]);
              return chain;
            },
            maybeSingle: () => {
              const stub = stubs[table];
              const row = stub?.row ?? null;
              const match = row !== null &&
                tableFilters.every(([column, value]) => row[column] === value);
              return Promise.resolve({
                data: match ? row : null,
                error: stub?.error ?? null,
              });
            },
          };
          return chain;
        },
      };
    },
  } as unknown as SupabaseClient;
  return { admin, filters };
}

const PRODUCT_ROW = {
  id: PRODUCT_ID,
  image_paths: ["stores/a.jpg"],
  name: "Shirt",
  material: null,
  fit: null,
  elasticity: null,
  thickness: null,
};

Deno.test("buildProductGarmentDetail joins present fields in fixed order", () => {
  const detail = buildProductGarmentDetail({
    image_paths: ["stores/x.jpg"],
    name: "Linen Shirt",
    material: "100% Linen",
    fit: "regular",
    elasticity: "low",
    thickness: "medium",
  });
  assertEquals(
    detail,
    "Product: Linen Shirt. Material: 100% Linen. Fit: regular. Elasticity: low. Thickness: medium",
  );
});

Deno.test("buildProductGarmentDetail skips empty and missing fields", () => {
  const detail = buildProductGarmentDetail({
    image_paths: [],
    name: "  Tee  ",
    material: "",
    fit: null,
    elasticity: undefined,
    thickness: "high",
  });
  assertEquals(detail, "Product: Tee. Thickness: high");
});

Deno.test("buildProductGarmentDetail returns undefined when all empty", () => {
  const detail = buildProductGarmentDetail({
    image_paths: [],
    name: null,
    material: null,
    fit: null,
    elasticity: null,
    thickness: null,
  });
  assertEquals(detail, undefined);
});

Deno.test("buildProductGarmentDetail caps overlong detail at the limit", () => {
  const detail = buildProductGarmentDetail({
    image_paths: [],
    name: "x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH + 200),
    material: null,
    fit: null,
    elasticity: null,
    thickness: null,
  });
  assertEquals(detail?.length, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
});

Deno.test("SECURITY: a sizeId belonging to a different product does not attach a fit", async () => {
  // The row exists and would produce a fit if read — the point is that the
  // `product_id` filter must be what keeps it from matching, not the row's
  // absence. This is the test that must fail if `.eq("product_id", productId)`
  // is ever dropped from `resolveSizeFit`.
  const { admin } = fakeAdmin({
    products: { row: PRODUCT_ROW },
    product_sizes: {
      row: {
        id: SIZE_ID,
        product_id: "99999999-9999-9999-9999-999999999999",
        name: "M",
        measurements: { chest_circumference: 100 },
      },
    },
  });

  const garment = await resolveProductGarment(
    admin,
    { productId: PRODUCT_ID, sizeId: SIZE_ID },
    { chest: 90 },
  );

  assertEquals("fit" in garment, false);
});

Deno.test("resolveProductGarment skips the fit description for a sizeId that matches no row", async () => {
  const { admin } = fakeAdmin({
    products: { row: PRODUCT_ROW },
    product_sizes: { row: null },
  });

  const garment = await resolveProductGarment(
    admin,
    { productId: PRODUCT_ID, sizeId: SIZE_ID },
    { chest: 90 },
  );

  assertEquals("fit" in garment, false);
});

Deno.test("resolveProductGarment survives a failed product_sizes lookup", async () => {
  // The fit sentence is a prompt enhancement; a transient read failure must not
  // fail a generation that has already been charged.
  const { admin } = fakeAdmin({
    products: { row: PRODUCT_ROW },
    product_sizes: { row: null, error: { message: "connection reset" } },
  });

  const garment = await resolveProductGarment(
    admin,
    { productId: PRODUCT_ID, sizeId: SIZE_ID },
    { chest: 90 },
  );

  assertEquals("fit" in garment, false);
  assertEquals(garment.images.length, 1);
});

Deno.test("resolveProductGarment attaches the fit description for a matching sizeId", async () => {
  const { admin } = fakeAdmin({
    products: { row: PRODUCT_ROW },
    product_sizes: {
      row: {
        id: SIZE_ID,
        product_id: PRODUCT_ID,
        name: "M",
        measurements: { chest_circumference: 104 },
      },
    },
  });

  const garment = await resolveProductGarment(
    admin,
    { productId: PRODUCT_ID, sizeId: SIZE_ID },
    { chest: 90 },
  );

  assertEquals(
    garment.fit,
    "size M: chest 104cm on a 90cm chest (+14cm — fitted, follows the body with a little room)",
  );
});

Deno.test("resolveProductGarment skips the product_sizes lookup entirely when there is no body", async () => {
  const { admin, filters } = fakeAdmin({
    products: { row: PRODUCT_ROW },
    product_sizes: {
      row: {
        id: SIZE_ID,
        product_id: PRODUCT_ID,
        name: "M",
        measurements: { chest_circumference: 104 },
      },
    },
  });

  const garment = await resolveProductGarment(
    admin,
    { productId: PRODUCT_ID, sizeId: SIZE_ID },
    null,
  );

  assertEquals("fit" in garment, false);
  assertEquals("product_sizes" in filters, false);
});

Deno.test("resolveProductGarment rejects a malformed sizeId", async () => {
  const { admin } = fakeAdmin({ products: { row: PRODUCT_ROW } });

  await assertRejects(
    () =>
      resolveProductGarment(
        admin,
        { productId: PRODUCT_ID, sizeId: "not-a-uuid" },
        { chest: 90 },
      ),
    ValidationError,
    "invalid sizeId",
  );
});

Deno.test("resolveProductGarment rejects a malformed sizeId even with no body", async () => {
  // Same caller bug, shopper with no measurements: validation must not depend
  // on user state, or the bug goes unreported for half the population.
  const { admin } = fakeAdmin({ products: { row: PRODUCT_ROW } });

  await assertRejects(
    () =>
      resolveProductGarment(
        admin,
        { productId: PRODUCT_ID, sizeId: "not-a-uuid" },
        null,
      ),
    ValidationError,
    "invalid sizeId",
  );
});
