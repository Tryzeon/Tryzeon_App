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
  const [loadMoreFailed, setLoadMoreFailed] = useState(false);
  const [status, setStatus] = useState<Status>("loading");

  // Only the newest request may write state: two quick searches must not end
  // with the first one's slower response overwriting the second one's results.
  const requestId = useRef(0);
  // Guards loadMore against re-entry. A ref, not `loadingMore`: the scroll
  // observer can fire twice before a state update commits, and two appends of
  // the same offset would duplicate every item on the page.
  const inFlight = useRef(false);

  useEffect(() => {
    const id = ++requestId.current;
    // The in-flight page belongs to the previous query; its writes are already
    // discarded, so release the guard rather than making the new query wait.
    inFlight.current = false;
    setLoadMoreFailed(false);
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
    if (inFlight.current || !hasMore) return;
    const id = requestId.current;
    inFlight.current = true;
    setLoadingMore(true);
    setLoadMoreFailed(false);
    fetchCatalog({ ...query, storeId, offset })
      .then((page) => {
        if (id !== requestId.current) return;
        setItems((prev) => [...prev, ...page.items]);
        setOffset(page.nextOffset);
        setHasMore(page.hasMore);
      })
      // Keeps what is already on screen, but has to be visible: auto-loading
      // makes a swallowed failure look like the end of the catalog.
      .catch(() => {
        if (id === requestId.current) setLoadMoreFailed(true);
      })
      .finally(() => {
        if (id !== requestId.current) return;
        inFlight.current = false;
        setLoadingMore(false);
      });
  }, [hasMore, offset, query, storeId]);

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
    appliedQuery: query.q,
    status,
    hasMore,
    loadingMore,
    loadMoreFailed,
    sort: query.sort,
    search,
    setSort,
    loadMore,
    retry,
  };
}
