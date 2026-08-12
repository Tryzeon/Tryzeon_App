import { useEffect, useRef } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import { CatalogSkeleton } from "../components/CatalogSkeleton";
import { Header } from "../components/Header";
import { ProductGrid } from "../components/ProductGrid";
import { ProductSheet } from "../components/ProductSheet";
import { SearchSortBar } from "../components/SearchSortBar";
import { FittingScreen } from "../components/FittingScreen";
import { ResultScreen } from "../components/ResultScreen";
import { useCatalog } from "../hooks/useCatalog";
import { useInfiniteScroll } from "../hooks/useInfiniteScroll";
import { useTryon } from "../hooks/useTryon";

export function Shop() {
  // /store/:storeId 進來時篩選成單一店家；首頁沒有這個參數就是全站商品。
  const { storeId } = useParams<{ storeId: string }>();
  const catalog = useCatalog(storeId);

  const storeName = catalog.store?.name ?? null;

  const tryon = useTryon();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();

  const openId = params.get("p");
  const openItem = catalog.items.find((i) => i.productId === openId) ?? null;

  // True while the sheet's own history entry is on the stack, so closing pops
  // it instead of stacking a second entry. LINE's back button pops it directly.
  const pushed = useRef(false);

  const sentinel = useRef<HTMLDivElement>(null);
  useInfiniteScroll(sentinel, catalog.loadMore, {
    enabled: catalog.status === "ready" && catalog.hasMore && !catalog.loadMoreFailed,
    itemCount: catalog.items.length,
  });
  const resetTryon = tryon.reset;
  useEffect(() => {
    if (openId === null) {
      pushed.current = false;
      resetTryon();
    }
  }, [openId, resetTryon]);

  function openSheet(item: CatalogItem) {
    tryon.reset();
    setParams({ p: item.productId });
    pushed.current = true;
  }

  function emptyMessage(): string {
    if (catalog.appliedQuery) return `找不到符合「${catalog.appliedQuery}」的商品。`;
    return storeId ? "這家店還沒有上架商品。" : "找不到符合的商品。";
  }

  function closeSheet() {
    tryon.reset();
    if (pushed.current) {
      pushed.current = false;
      navigate(-1);
    } else {
      setParams({}, { replace: true });
    }
  }

  if (tryon.state.phase === "generating") {
    return (
      <div className="app">
        <Header overlay title={storeName} />
        <FittingScreen />
      </div>
    );
  }

  if (tryon.state.phase === "done") {
    return (
      <div className="app">
        <Header title={storeName} />
        <ResultScreen
          item={tryon.state.item}
          imageUrl={tryon.state.imageUrl}
          onBack={closeSheet}
        />
      </div>
    );
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
          : <ProductGrid items={catalog.items} onOpen={openSheet} />)}

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

      {openItem && (
        <ProductSheet
          item={openItem}
          tryon={tryon.state}
          onClose={closeSheet}
          onTryon={() => tryon.generate(openItem)}
          onPickAvatar={(file) => tryon.uploadAvatarAndGenerate(openItem, file)}
        />
      )}
    </div>
  );
}
