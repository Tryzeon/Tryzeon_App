import { assertEquals } from "jsr:@std/assert";
import { buildCatalogItem } from "./catalog-logic.ts";

const BASE = "https://img.test";

const row = {
  id: "11111111-1111-1111-1111-111111111111",
  name: "亞麻襯衫",
  price: 1280,
  image_paths: ["stores/a/1.jpg", "stores/a/2.jpg"],
  purchase_link: "https://shop.test/p/1",
  store_profiles: { id: "s1", name: "小島選物" },
};

Deno.test("buildCatalogItem projects every image path, not just the first", () => {
  assertEquals(buildCatalogItem(row, BASE).imageUrls, [
    "https://img.test/stores/a/1.jpg",
    "https://img.test/stores/a/2.jpg",
  ]);
});

Deno.test("buildCatalogItem carries purchase link, store name and price", () => {
  const item = buildCatalogItem(row, BASE);
  assertEquals(item.productId, "11111111-1111-1111-1111-111111111111");
  assertEquals(item.name, "亞麻襯衫");
  assertEquals(item.price, 1280);
  assertEquals(item.storeName, "小島選物");
  assertEquals(item.purchaseLink, "https://shop.test/p/1");
});

Deno.test("buildCatalogItem normalizes a blank purchase link to null", () => {
  assertEquals(buildCatalogItem({ ...row, purchase_link: "" }, BASE).purchaseLink, null);
  assertEquals(buildCatalogItem({ ...row, purchase_link: null }, BASE).purchaseLink, null);
});

Deno.test("buildCatalogItem keeps a product with no usable image, with no urls", () => {
  for (const imagePaths of [[], null, [""]]) {
    const item = buildCatalogItem({ ...row, image_paths: imagePaths }, BASE);
    assertEquals(item.imageUrls, []);
    // The product itself still reaches the catalog — only its photos are missing.
    assertEquals(item.name, "亞麻襯衫");
  }
});

Deno.test("buildCatalogItem tolerates a missing store", () => {
  assertEquals(buildCatalogItem({ ...row, store_profiles: null }, BASE).storeName, null);
});
