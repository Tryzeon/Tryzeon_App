import { useRef } from "react";
import { useNavigate } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import { CatalogSkeleton } from "../components/CatalogSkeleton";
import { Header } from "../components/Header";
import { ProductGrid } from "../components/ProductGrid";
import { SearchSortBar } from "../components/SearchSortBar";
import { useCatalog } from "../hooks/useCatalog";
import { useInfiniteScroll } from "../hooks/useInfiniteScroll";

export function Shop({ storeId }: { storeId?: string }) {
  const catalog = useCatalog(storeId);
  const navigate = useNavigate();

  const storeName = catalog.store?.name ?? null;

  const sentinel = useRef<HTMLDivElement>(null);
  useInfiniteScroll(sentinel, catalog.loadMore, {
    enabled: catalog.status === "ready" && catalog.hasMore && !catalog.loadMoreFailed,
    itemCount: catalog.items.length,
  });

  // The catalog row and the detail row are both built by the same
  // buildCatalogItem, so everything the detail page shows is already in hand —
  // pass it along and it need not ask the server for the same data again.
  function openProduct(item: CatalogItem) {
    navigate(`/product/${item.productId}`, { state: { item } });
  }

  function emptyMessage(): string {
    if (catalog.appliedQuery) return `找不到符合「${catalog.appliedQuery}」的商品。`;
    return storeId ? "這家店還沒有上架商品。" : "找不到符合的商品。";
  }

  return (
    <div className="app">
      <Header title={storeName} />
      <main className="main">
        <SearchSortBar
          sort={catalog.sort}
          onSearch={catalog.search}
          onSortChange={catalog.setSort}
        />

        {catalog.status === "loading" && <CatalogSkeleton />}

        {catalog.status === "error" && (
          <>
            <div className="errorcard">目錄載入失敗，請稍後再試。</div>
            <button className="loadmore" onClick={catalog.retry}>重新載入</button>
          </>
        )}

        {catalog.status === "ready" && (catalog.items.length === 0
          ? <p className="empty">{emptyMessage()}</p>
          : <ProductGrid items={catalog.items} onOpen={openProduct} />)}

        {catalog.status === "ready" && catalog.hasMore && (
          catalog.loadMoreFailed
            ? <button className="loadmore" onClick={catalog.loadMore}>載入失敗，點此重試</button>
            : (
              <div ref={sentinel} className="sentinel">
                {catalog.loadingMore && <span className="spinner spinner--ink" aria-hidden="true" />}
              </div>
            )
        )}
      </main>
    </div>
  );
}
