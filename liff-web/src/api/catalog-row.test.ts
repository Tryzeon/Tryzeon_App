import { describe, expect, it } from "vitest";
import { buildCatalogItem, publicImageUrl } from "./catalog-row";

const BASE = "https://img.test";

const row = {
  id: "11111111-1111-1111-1111-111111111111",
  name: "亞麻襯衫",
  price: 1280,
  image_paths: ["stores/a/1.jpg", "stores/a/2.jpg"],
  purchase_link: "https://shop.test/p/1",
  store_profiles: { id: "s1", name: "小島選物" },
};

describe("publicImageUrl", () => {
  it("joins base and key with exactly one slash", () => {
    expect(publicImageUrl("https://img.test", "a/1.jpg")).toBe(
      "https://img.test/a/1.jpg",
    );
    expect(publicImageUrl("https://img.test///", "a/1.jpg")).toBe(
      "https://img.test/a/1.jpg",
    );
  });
});

describe("buildCatalogItem", () => {
  it("projects every image path, not just the first", () => {
    expect(buildCatalogItem(row, BASE).imageUrls).toEqual([
      "https://img.test/stores/a/1.jpg",
      "https://img.test/stores/a/2.jpg",
    ]);
  });

  it("carries purchase link, store name and price", () => {
    const item = buildCatalogItem(row, BASE);
    expect(item.productId).toBe("11111111-1111-1111-1111-111111111111");
    expect(item.name).toBe("亞麻襯衫");
    expect(item.price).toBe(1280);
    expect(item.storeName).toBe("小島選物");
    expect(item.purchaseLink).toBe("https://shop.test/p/1");
  });

  it("normalizes a blank purchase link to null", () => {
    expect(buildCatalogItem({ ...row, purchase_link: "" }, BASE).purchaseLink)
      .toBeNull();
    expect(buildCatalogItem({ ...row, purchase_link: null }, BASE).purchaseLink)
      .toBeNull();
  });

  it("keeps a product with no usable image, with no urls", () => {
    for (const imagePaths of [[], null, [""]]) {
      const item = buildCatalogItem({ ...row, image_paths: imagePaths }, BASE);
      expect(item.imageUrls).toEqual([]);
      // 商品本身仍然進得了目錄 —— 缺的只是照片。
      expect(item.name).toBe("亞麻襯衫");
    }
  });

  it("tolerates a missing store", () => {
    expect(buildCatalogItem({ ...row, store_profiles: null }, BASE).storeName)
      .toBeNull();
  });
});
