import { useCallback, useEffect, useRef, useState } from "react";
import {
  fetchCatalog,
  type CatalogItem,
  type CatalogStore,
  type SortOption,
} from "../api/catalog";

type Status = "loading" | "ready" | "error";

export function useCatalog(storeId?: string) {
  const [query, setQuery] = useState<{ q: string; sort: SortOption }>({
    q: "",
    sort: "latest",
  });
  const [items, setItems] = useState<CatalogItem[]>([]);
  const [store, setStore] = useState<CatalogStore | null>(null);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [status, setStatus] = useState<Status>("loading");

  // Only the newest request may write state: two quick searches must not end
  // with the first one's slower response overwriting the second one's results.
  const requestId = useRef(0);

  useEffect(() => {
    const id = ++requestId.current;
    setStatus("loading");
    // A replaced list should not leave the viewport mid-list, so jump back to
    // the top whenever a new query starts (never on loadMore, which appends).
    window.scrollTo(0, 0);
    fetchCatalog({ ...query, storeId, offset: 0 }).then(
      (page) => {
        if (id !== requestId.current) return;
        setItems(page.items);
        setStore(page.store);
        setOffset(page.nextOffset);
        setHasMore(page.hasMore);
        setStatus("ready");
      },
      () => {
        if (id !== requestId.current) return;
        setStatus("error");
      },
    );
  }, [query, storeId]);

  const loadMore = useCallback(() => {
    if (loadingMore) return;
    const id = requestId.current;
    setLoadingMore(true);
    fetchCatalog({ ...query, storeId, offset })
      .then((page) => {
        if (id !== requestId.current) return;
        setItems((prev) => [...prev, ...page.items]);
        setOffset(page.nextOffset);
        setHasMore(page.hasMore);
      })
      // A load-more failure is non-fatal: keep what is already on screen.
      .catch(() => {})
      .finally(() => setLoadingMore(false));
  }, [loadingMore, offset, query, storeId]);

  // Each call makes a fresh query object on purpose: pressing 搜尋 again with
  // the same text is a deliberate reload, not a no-op.
  const search = useCallback((q: string) => setQuery((prev) => ({ ...prev, q })), []);
  const setSort = useCallback(
    (sort: SortOption) => setQuery((prev) => ({ ...prev, sort })),
    [],
  );
  const retry = useCallback(() => setQuery((prev) => ({ ...prev })), []);

  return {
    items,
    store,
    status,
    hasMore,
    loadingMore,
    sort: query.sort,
    search,
    setSort,
    loadMore,
    retry,
  };
}
