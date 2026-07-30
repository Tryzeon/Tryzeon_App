import { readJson } from "./errors";

export type SortOption = "latest" | "price_asc" | "price_desc";

export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrls: string[];
  purchaseLink: string | null;
}

export interface CatalogPage {
  items: CatalogItem[];
  nextOffset: number;
  hasMore: boolean;
}

export interface CatalogQuery {
  q: string;
  sort: SortOption;
  offset: number;
}

export async function fetchCatalog({ q, sort, offset }: CatalogQuery): Promise<CatalogPage> {
  const base = import.meta.env.VITE_LIFF_CATALOG_URL as string;
  const params = new URLSearchParams({ offset: String(offset), sort });
  if (q) params.set("q", q);

  const data = await readJson(await fetch(`${base}?${params}`));
  return {
    items: Array.isArray(data.items) ? (data.items as CatalogItem[]) : [],
    nextOffset: typeof data.nextOffset === "number" ? data.nextOffset : offset,
    hasMore: Boolean(data.hasMore),
  };
}
