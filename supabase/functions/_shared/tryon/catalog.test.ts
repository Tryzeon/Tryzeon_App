import { assertEquals } from "jsr:@std/assert";
import { buildProductGarmentDetail } from "./catalog.ts";
import { LIMITS } from "./types.ts";

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
