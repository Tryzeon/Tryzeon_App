import { assertEquals } from "jsr:@std/assert";
import { buildCatalogItem } from "./catalog-logic.ts";

const BASE = "https://cdn.example.com";

Deno.test("buildCatalogItem maps a product with a stores/ image", () => {
  const row = {
    id: "p1",
    name: "白襯衫",
    price: 590,
    image_paths: ["stores/s1/products/p1/a.jpg", "stores/s1/products/p1/b.jpg"],
    store_profiles: { name: "Acme" },
  };
  assertEquals(buildCatalogItem(row, BASE), {
    productId: "p1",
    name: "白襯衫",
    price: 590,
    storeName: "Acme",
    imageUrl: "https://cdn.example.com/stores/s1/products/p1/a.jpg",
  });
});

Deno.test("buildCatalogItem returns null when no stores/ image exists", () => {
  const row = { id: "p2", name: "X", price: 1, image_paths: ["product-images/legacy.jpg"], store_profiles: { name: "S" } };
  assertEquals(buildCatalogItem(row, BASE), null);
});

Deno.test("buildCatalogItem returns null when image_paths is empty/missing", () => {
  assertEquals(buildCatalogItem({ id: "p3", name: "X", image_paths: [] }, BASE), null);
  assertEquals(buildCatalogItem({ id: "p4", name: "X" }, BASE), null);
});

Deno.test("buildCatalogItem strips a trailing slash from the base URL", () => {
  const row = { id: "p5", name: "Y", price: null, image_paths: ["stores/x.jpg"], store_profiles: null };
  assertEquals(buildCatalogItem(row, "https://cdn.example.com/")?.imageUrl, "https://cdn.example.com/stores/x.jpg");
});
