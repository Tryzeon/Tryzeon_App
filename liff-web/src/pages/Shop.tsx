import { useEffect, useRef } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import { Header } from "../components/Header";
import { ProductGrid } from "../components/ProductGrid";
import { ProductSheet } from "../components/ProductSheet";
import { SearchSortBar } from "../components/SearchSortBar";
import { FittingScreen } from "../components/FittingScreen";
import { ResultScreen } from "../components/ResultScreen";
import { useCatalog } from "../hooks/useCatalog";
import { useTryon } from "../hooks/useTryon";

export function Shop() {
  const catalog = useCatalog();

  const tryon = useTryon();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();

  const openId = params.get("p");
  const openItem = catalog.items.find((i) => i.productId === openId) ?? null;

  // True while the sheet's own history entry is on the stack, so closing pops
  // it instead of stacking a second entry. LINE's back button pops it directly.
  const pushed = useRef(false);
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
        <Header />
        <FittingScreen imageUrl={tryon.state.item.imageUrls[0]} />
      </div>
    );
  }

  if (tryon.state.phase === "done") {
    return (
      <div className="app">
        <Header />
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
      <Header />
      <main className="main">
        <SearchSortBar
          sort={catalog.sort}
          onSearch={catalog.search}
          onSortChange={catalog.setSort}
        />

        {catalog.status === "loading" && (
          <div className="grid">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="sk sk--card" />)}
          </div>
        )}

        {catalog.status === "error" && (
          <>
            <div className="errorcard">目錄載入失敗，請稍後再試。</div>
            <button className="loadmore" onClick={catalog.retry}>重新載入</button>
          </>
        )}

        {catalog.status === "ready" && (catalog.items.length === 0
          ? <p className="empty">找不到符合的商品。</p>
          : <ProductGrid items={catalog.items} onOpen={openSheet} />)}

        {catalog.status === "ready" && catalog.hasMore && (
          <button className="loadmore" disabled={catalog.loadingMore} onClick={catalog.loadMore}>
            {catalog.loadingMore ? "載入中…" : "載入更多"}
          </button>
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
