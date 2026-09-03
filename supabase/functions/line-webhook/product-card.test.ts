import { assertEquals, assertRejects } from "jsr:@std/assert@^1.0.19";
import {
  amountText,
  clampProductName,
  fetchProductInfo,
  fetchProductRows,
  type LineProduct,
  productInfoContents,
  purchaseAction,
  toLineProduct,
} from "./product-card.ts";
import { CARD_COLOR } from "./card-kit.ts";

const BASE = "https://img.example";

const row = (over: Record<string, unknown> = {}) => ({
  id: "p1",
  name: "白襯衫",
  price: 1200,
  image_paths: ["stores/s1/p1.jpg"],
  purchase_link: null,
  store_profiles: { name: "某店" },
  ...over,
});

const product = (over: Partial<LineProduct> = {}): LineProduct => ({
  id: "p1",
  name: "白襯衫",
  price: 1200,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

/**
 * `.from()` throws: the unlisted-product filter lives in `get_shop_product` now,
 * so a direct `products` read is a regression, not an alternative.
 */
// deno-lint-ignore no-explicit-any
function fakeAdmin(result: { data: any; error: any }) {
  const queried: string[] = [];
  const calls: Array<[string, Record<string, unknown>]> = [];
  const client = {
    rpc(name: string, params: Record<string, unknown>) {
      calls.push([name, params]);
      queried.push(params.p_id as string);
      return Promise.resolve(result);
    },
    from() {
      throw new Error(
        "fakeAdmin: fetchProductInfo must go through get_shop_product",
      );
    },
  };
  // deno-lint-ignore no-explicit-any
  return { admin: client as any, queried, calls };
}

// deno-lint-ignore no-explicit-any
function fakeBatchAdmin(result: { data: any; error: any }) {
  const queried: string[][] = [];
  const client = {
    from() {
      return {
        select() {
          return {
            in(_column: string, ids: string[]) {
              queried.push(ids);
              return Promise.resolve(result);
            },
          };
        },
      };
    },
  };
  // deno-lint-ignore no-explicit-any
  return { admin: client as any, queried };
}

Deno.test("toLineProduct joins the image key onto the public base", () => {
  assertEquals(toLineProduct(row(), BASE), {
    id: "p1",
    name: "白襯衫",
    price: 1200,
    imageUrl: "https://img.example/stores/s1/p1.jpg",
    storeName: "某店",
    purchaseUrl: null,
  });
});

Deno.test("toLineProduct drops a product with no image", () => {
  assertEquals(toLineProduct(row({ image_paths: [] }), BASE), null);
  assertEquals(toLineProduct(row({ image_paths: null }), BASE), null);
});

Deno.test("toLineProduct tolerates a product with no store", () => {
  assertEquals(toLineProduct(row({ store_profiles: null }), BASE)?.storeName, null);
});

Deno.test("toLineProduct does not double up a trailing slash on the base", () => {
  assertEquals(
    toLineProduct(row(), `${BASE}/`)?.imageUrl,
    "https://img.example/stores/s1/p1.jpg",
  );
});

Deno.test("fetchProductInfo reads the asked-for id", async () => {
  const { admin, queried } = fakeAdmin({ data: row(), error: null });
  const found = await fetchProductInfo(admin, "p1");

  assertEquals(queried, ["p1"]);
  assertEquals(found?.name, "白襯衫");
});

Deno.test("fetchProductInfo is null for a product that is gone", async () => {
  const { admin } = fakeAdmin({ data: null, error: null });
  assertEquals(await fetchProductInfo(admin, "p1"), null);
});

Deno.test("fetchProductInfo is null for a product with no image", async () => {
  const { admin } = fakeAdmin({ data: row({ image_paths: [] }), error: null });
  assertEquals(await fetchProductInfo(admin, "p1"), null);
});

Deno.test("fetchProductInfo throws when the lookup itself failed", async () => {
  const { admin } = fakeAdmin({ data: null, error: { message: "boom" } });
  await assertRejects(() => fetchProductInfo(admin, "p1"), Error, "boom");
});

Deno.test("fetchProductRows keys the rows by product id", async () => {
  const { admin, queried } = fakeBatchAdmin({
    data: [row(), row({ id: "p2", name: "黑褲" })],
    error: null,
  });
  const rows = await fetchProductRows(admin, ["p1", "p2"], BASE);

  assertEquals(queried, [["p1", "p2"]]);
  assertEquals([...rows.keys()], ["p1", "p2"]);
  assertEquals((rows.get("p2") as LineProduct).name, "黑褲");
});

Deno.test("fetchProductRows leaves out a product with no image", async () => {
  const { admin } = fakeBatchAdmin({
    data: [row(), row({ id: "p2", image_paths: [] })],
    error: null,
  });
  const rows = await fetchProductRows(admin, ["p1", "p2"], BASE);

  // Absent, not present-and-null: the assembler drops it by the missing-row rule.
  assertEquals([...rows.keys()], ["p1"]);
});

Deno.test("fetchProductRows queries nothing for an empty id list", async () => {
  const { admin, queried } = fakeBatchAdmin({ data: null, error: null });
  const rows = await fetchProductRows(admin, [], BASE);

  assertEquals(queried, []);
  assertEquals(rows.size, 0);
});

Deno.test("fetchProductRows throws when the lookup itself failed", async () => {
  const { admin } = fakeBatchAdmin({ data: null, error: { message: "boom" } });
  await assertRejects(() => fetchProductRows(admin, ["p1"], BASE));
});

Deno.test("fetchProductInfo will not act on an unlisted product", async () => {
  const { admin, calls } = fakeAdmin({ data: row(), error: null });
  await fetchProductInfo(admin, "p1");

  assertEquals(calls, [["get_shop_product", { p_id: "p1" }]]);
});

Deno.test("purchaseAction is offered only for an absolute http link", () => {
  assertEquals(purchaseAction(product({ purchaseUrl: "https://shop.example/p1" })), {
    type: "uri",
    label: "前往購買",
    uri: "https://shop.example/p1",
  });
  assertEquals(purchaseAction(product({ purchaseUrl: "shop.example/p1" })), null);
  assertEquals(purchaseAction(product({ purchaseUrl: "" })), null);
  assertEquals(purchaseAction(product()), null);
});

Deno.test("purchaseAction rejects strings a bare startsWith(\"http\") check let through", () => {
  assertEquals(purchaseAction(product({ purchaseUrl: "http" })), null);
  assertEquals(purchaseAction(product({ purchaseUrl: "httpfoo://x" })), null);
  // `new URL` normalizes a single-slash scheme to a valid "https://one-slash/",
  // so a bare protocol check on the parsed result would wave it through.
  assertEquals(purchaseAction(product({ purchaseUrl: "https:/one-slash" })), null);
});

Deno.test("amountText groups thousands and drops cents", () => {
  assertEquals(amountText(1200), "1,200");
  assertEquals(amountText(1199.6), "1,200");
  assertEquals(amountText(0), "0");
});

Deno.test("the info block is name, price and store", () => {
  // deno-lint-ignore no-explicit-any
  const contents = productInfoContents(product({ storeName: "Studio Muji" })) as any[];

  assertEquals(contents.length, 3);
  assertEquals(contents[0].text, "白襯衫");
  assertEquals(contents[0].color, CARD_COLOR.primary);
  assertEquals(contents[2].text, "STUDIO MUJI");
  assertEquals(contents[2].color, CARD_COLOR.muted);
});

Deno.test("a product with no store shows two lines, not an empty third", () => {
  // deno-lint-ignore no-explicit-any
  const contents = productInfoContents(product({ storeName: null })) as any[];
  assertEquals(contents.length, 2);
});

Deno.test("the price splits currency from amount so they read at two levels", () => {
  // deno-lint-ignore no-explicit-any
  const [, price] = productInfoContents(product()) as any[];

  assertEquals(price.contents, [
    { type: "span", text: "NT$ ", size: "xs", color: CARD_COLOR.muted },
    { type: "span", text: "1,200", size: "lg", weight: "bold", color: CARD_COLOR.primary },
  ]);
  // No `text` on the parent: with spans set LINE ignores it, and carrying both
  // invites the two to drift apart.
  assertEquals(price.text, undefined);
});

Deno.test("a Chinese store name is unchanged by uppercasing", () => {
  // deno-lint-ignore no-explicit-any
  const contents = productInfoContents(product({ storeName: "某店" })) as any[];
  assertEquals(contents[2].text, "某店");
});

Deno.test("clampProductName leaves a short name untouched", () => {
  assertEquals(clampProductName("白襯衫"), "白襯衫");
  assertEquals(clampProductName("a".repeat(40)), "a".repeat(40));
});

Deno.test("clampProductName truncates a long name with an ellipsis", () => {
  const long = "a".repeat(41);
  assertEquals(clampProductName(long), `${"a".repeat(40)}…`);
});
