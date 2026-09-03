import { describe, expect, it } from "vitest";
import {
  InvalidStoreIdError,
  normalizeUuid,
  parseStoreId,
  searchParam,
  SORT_OPTIONS,
  sortParams,
} from "./catalog-query";

describe("sortParams", () => {
  it("maps each sort option to its RPC pair", () => {
    expect(sortParams("latest")).toEqual({
      sortColumn: "created_at",
      sortAscending: false,
    });
    expect(sortParams("price_asc")).toEqual({
      sortColumn: "price",
      sortAscending: true,
    });
    expect(sortParams("price_desc")).toEqual({
      sortColumn: "price",
      sortAscending: false,
    });
  });

  // 守的是:白名單長出新成員時不會忘記給它一組對應。
  it("covers every SORT_OPTIONS member", () => {
    for (const sort of SORT_OPTIONS) {
      expect(sortParams(sort).sortColumn).toBeTruthy();
    }
  });
});

describe("searchParam", () => {
  it("trims the query and treats blank as absent", () => {
    expect(searchParam("  ")).toBeNull();
    expect(searchParam("")).toBeNull();
    expect(searchParam(" 洋裝 ")).toBe("洋裝");
  });
});

describe("parseStoreId", () => {
  const id = "d01f159f-ef0a-48d7-965f-6da518ee76c4";

  it("accepts a store uuid and normalizes case", () => {
    expect(parseStoreId(id)).toBe(id);
    expect(parseStoreId(id.toUpperCase())).toBe(id);
  });

  it("is null when there is no store segment at all", () => {
    expect(parseStoreId(undefined)).toBeNull();
  });

  it("rejects a malformed store id instead of falling back to the full catalog", () => {
    expect(() => parseStoreId("nope")).toThrow(InvalidStoreIdError);
    expect(() => parseStoreId("")).toThrow(InvalidStoreIdError);
  });
});

describe("normalizeUuid", () => {
  it("lowercases a uuid", () => {
    expect(normalizeUuid("A1B2C3D4-1111-2222-3333-444455556666"))
      .toBe("a1b2c3d4-1111-2222-3333-444455556666");
  });

  it("trims surrounding whitespace", () => {
    expect(normalizeUuid(" a1b2c3d4-1111-2222-3333-444455556666 "))
      .toBe("a1b2c3d4-1111-2222-3333-444455556666");
  });

  it("rejects anything that is not a uuid", () => {
    expect(normalizeUuid("not-a-uuid")).toBeNull();
    expect(normalizeUuid("")).toBeNull();
    expect(normalizeUuid("a1b2c3d4-1111-2222-3333-44445555666")).toBeNull();
  });
});
