import { assertEquals, assertThrows } from "jsr:@std/assert";
import { parseCatalogQuery } from "./query.ts";
import { ValidationError } from "../_shared/validation.ts";

const url = (qs: string) => new URL(`https://x.test/liff-catalog${qs}`);

Deno.test("parseCatalogQuery defaults to newest-first, no search, offset 0", () => {
  assertEquals(parseCatalogQuery(url("")), {
    offset: 0,
    searchQuery: null,
    sortColumn: "created_at",
    sortAscending: false,
  });
});

Deno.test("parseCatalogQuery maps each sort option to its RPC pair", () => {
  assertEquals(parseCatalogQuery(url("?sort=price_asc")).sortColumn, "price");
  assertEquals(parseCatalogQuery(url("?sort=price_asc")).sortAscending, true);
  assertEquals(parseCatalogQuery(url("?sort=price_desc")).sortColumn, "price");
  assertEquals(parseCatalogQuery(url("?sort=price_desc")).sortAscending, false);
  assertEquals(parseCatalogQuery(url("?sort=latest")).sortColumn, "created_at");
});

Deno.test("parseCatalogQuery rejects an unknown sort rather than defaulting", () => {
  // Silently falling back would hide a client bug behind plausible results.
  assertThrows(() => parseCatalogQuery(url("?sort=created_at")), ValidationError, "sort");
  assertThrows(() => parseCatalogQuery(url("?sort=")), ValidationError, "sort");
});

Deno.test("parseCatalogQuery trims q and treats blank as absent", () => {
  assertEquals(parseCatalogQuery(url("?q=%20%20")).searchQuery, null);
  assertEquals(parseCatalogQuery(url("?q=%20洋裝%20")).searchQuery, "洋裝");
});

Deno.test("parseCatalogQuery clamps a bad offset to 0", () => {
  assertEquals(parseCatalogQuery(url("?offset=30")).offset, 30);
  assertEquals(parseCatalogQuery(url("?offset=-5")).offset, 0);
  assertEquals(parseCatalogQuery(url("?offset=abc")).offset, 0);
});
