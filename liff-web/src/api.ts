export interface TryonError extends Error {
  code?: string;
  status?: number;
}

export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrl: string;
}

export interface CatalogPage {
  items: CatalogItem[];
  nextOffset: number;
  hasMore: boolean;
}

export async function fetchCatalog(offset = 0): Promise<CatalogPage> {
  const base = import.meta.env.VITE_LIFF_CATALOG_URL as string;
  const resp = await fetch(`${base}?offset=${offset}`);
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    throw new Error(data.error ?? "catalog request failed");
  }
  return {
    items: Array.isArray(data.items) ? data.items : [],
    nextOffset: typeof data.nextOffset === "number" ? data.nextOffset : offset,
    hasMore: Boolean(data.hasMore),
  };
}

export async function callTryon(
  idToken: string,
  avatarBase64: string,
  productId: string,
): Promise<{ imageUrl: string }> {
  const resp = await fetch(import.meta.env.VITE_LIFF_TRYON_URL as string, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken, avatarBase64, productId }),
  });

  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const err = new Error(data.error ?? "request failed") as TryonError;
    err.code = data.code;
    err.status = resp.status;
    throw err;
  }
  if (typeof data.imageUrl !== "string" || data.imageUrl.length === 0) {
    throw new Error("tryon response missing imageUrl");
  }
  return { imageUrl: data.imageUrl as string };
}
