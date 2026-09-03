import {
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "jsr:@std/assert";
import { buildProductGarmentDetail, resolveProductGarment } from "./catalog.ts";
import { LIMITS } from "./types.ts";
import { ValidationError } from "./errors.ts";
import type { DbClient } from "../supabase.ts";

const PRODUCT_ID = "11111111-1111-1111-1111-111111111111";
const SIZE_ID = "22222222-2222-2222-2222-222222222222";

interface LookupStub {
  row: Record<string, unknown> | null;
  error?: { message: string };
}

/**
 * `products` is served through `.rpc()`, and `.from("products")` throws, so a
 * regression to a direct, unfiltered table read fails the suite instead of
 * silently widening what a try-on can reach. The rpc arm re-checks `p_id` and
 * `status` against the stub row, modelling what the SQL function does, so the
 * security test below describes a real outcome and not merely a recorded call.
 */
function fakeAdmin(stubs: Record<string, LookupStub>) {
  const filters: Record<string, Array<[string, string]>> = {};
  const rpcCalls: Array<[string, Record<string, unknown>]> = [];
  const admin = {
    rpc: (name: string, params: Record<string, unknown>) => {
      rpcCalls.push([name, params]);
      const stub = stubs.products;
      const row = stub?.row ?? null;
      const visible = row !== null &&
        row.id === params.p_id &&
        row.status === "active";
      return Promise.resolve({
        data: visible ? row : null,
        error: stub?.error ?? null,
      });
    },
    from: (table: string) => {
      if (table === "products") {
        throw new Error(
          "fakeAdmin: the product lookup must go through get_shop_product",
        );
      }
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
  } as unknown as DbClient;
  return { admin, filters, rpcCalls };
}

const PRODUCT_ROW = {
  id: PRODUCT_ID,
  status: "active",
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
    "Product: Linen Shirt. Material: 100% Linen. Cut: regular. Elasticity: low. Thickness: medium",
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
  // The row exists and would produce a fit if read, so this is the test that
  // must fail if `.eq("product_id", productId)` is dropped from
  // `resolveSizeFit`.
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

Deno.test("resolveProductGarment looks the product up through get_shop_product", async () => {
  const { admin, rpcCalls } = fakeAdmin({ products: { row: PRODUCT_ROW } });
  await resolveProductGarment(admin, { productId: PRODUCT_ID }, null);

  assertEquals(rpcCalls, [["get_shop_product", { p_id: PRODUCT_ID }]]);
});

Deno.test("SECURITY: an unlisted product does not resolve", async () => {
  // An archived product keeps its row; what keeps it out of a try-on is
  // `get_shop_product`'s `status = 'active'`, which the fake models.
  const { admin } = fakeAdmin({
    products: { row: { ...PRODUCT_ROW, status: "archived" } },
  });

  await assertRejects(
    () => resolveProductGarment(admin, { productId: PRODUCT_ID }, null),
    ValidationError,
    "no product for productId",
  );
});

Deno.test("resolveProductGarment sends only the product's first image", async () => {
  const { admin } = fakeAdmin({
    products: {
      row: {
        ...PRODUCT_ROW,
        image_paths: ["stores/main.jpg", "stores/label.jpg", "stores/hem.jpg"],
      },
    },
  });

  const garment = await resolveProductGarment(admin, { productId: PRODUCT_ID }, null);

  assertEquals(garment.images, [{ path: "stores/main.jpg" }]);
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

Deno.test("resolveProductGarment ships the cut label alongside real fit numbers", async () => {
  const { admin } = fakeAdmin({
    products: { row: { ...PRODUCT_ROW, fit: "oversize" } },
    product_sizes: {
      row: {
        id: SIZE_ID,
        product_id: PRODUCT_ID,
        name: "M",
        measurements: { chest_circumference: 88 },
      },
    },
  });

  const garment = await resolveProductGarment(
    admin,
    { productId: PRODUCT_ID, sizeId: SIZE_ID },
    { chest: 110 },
  );

  // An oversize cut on a body big enough to fill it: both the cut and the ease
  // numbers reach the model.
  assertEquals(garment.detail, "Product: Shirt. Cut: oversize");
  assertStringIncludes(garment.fit ?? "", "-22cm — compression");
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
  // Validation must not depend on user state, or the bug goes unreported for
  // half the population.
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
