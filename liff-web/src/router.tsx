import { useEffect, useRef, useState } from "react";
import { matchPath, Navigate, Outlet, Route, Routes, useLocation } from "react-router-dom";
import { initAndLogin } from "./lib/liff";
import { ensureSession } from "./lib/auth";
import { fetchAvatarPath } from "./api/profile";
import { CatalogSkeleton } from "./components/CatalogSkeleton";
import { Header } from "./components/Header";
import { SearchSortBar } from "./components/SearchSortBar";
import { Shop } from "./pages/Shop";
import { Home } from "./pages/Home";
import { ProductDetail } from "./pages/ProductDetail";
import { Onboard } from "./pages/Onboard";
import { TabBar, type ActiveTab } from "./components/TabBar";
import { AvatarProvider } from "./state/AvatarProvider";
import { GalleryProvider } from "./state/GalleryProvider";

const noop = () => {};

function LiffGate() {
  const [state, setState] = useState<"loading" | "ready" | "error">("loading");
  const [avatarPath, setAvatarPath] = useState<string | null>(null);

  useEffect(() => {
    initAndLogin()
      .then(ensureSession)
      .then(fetchAvatarPath)
      .then(
        (path) => {
          setAvatarPath(path);
          setState("ready");
        },
        (err) => {
          console.error("[liff-gate] bootstrap failed:", err);
          setState("error");
        },
      );
  }, []);

  // The same chrome the catalog renders while it fetches, so opening the gate
  // swaps the placeholders for products without the page jumping.
  if (state === "loading") {
    return (
      <div className="app">
        <Header />
        <main className="main">
          <SearchSortBar sort="latest" disabled onSearch={noop} onSortChange={noop} />
          <CatalogSkeleton />
        </main>
      </div>
    );
  }
  if (state === "error") {
    return (
      <div className="app">
        <Header />
        <main className="main">
          <div className="errorcard">載入失敗,請稍後再試。</div>
          <button className="loadmore" onClick={() => window.location.reload()}>
            重新載入
          </button>
        </main>
      </div>
    );
  }
  // 模特照和 gallery 都掛在這裡而不是各自的頁面裡:兩個分頁看到的要是同一份,
  // 而去試衣間逛一圈再回來,剛剛的試穿還要在。
  return (
    <AvatarProvider initialPath={avatarPath}>
      <GalleryProvider>
        <Outlet />
      </GalleryProvider>
    </AvatarProvider>
  );
}

/**
 * 換分頁不再是卸載重建,所以模特照不會每次進首頁都重簽一次、目錄不會每次回來都
 * 重抓,而每個 pane 自己是一個捲動容器,捲動位置由瀏覽器保管,不必手動存還。
 * 商品頁不在此列:那是一個詳情畫面,每次看的是不同的一件,重建才是對的。
 */
function TabShell() {
  const { pathname } = useLocation();

  const isHome = pathname === "/home";
  const isProduct = pathname.startsWith("/product/");
  const isShop = !isHome && !isProduct;

  const lastShopPath = useRef("/");
  if (isShop) lastShopPath.current = pathname;

  // 店家 id 來自試衣間記得的那個位置,不是目前的網址 —— 人在首頁時目前的網址配
  // 不到 /store/:storeId,拿它去問等於在背後把店家目錄換成全站目錄。
  const storeId =
    matchPath("/store/:storeId", lastShopPath.current)?.params.storeId;

  const active: ActiveTab = isHome ? "home" : isProduct ? null : "shop";

  return (
    <div className="tabshell">
      <div className={paneClass(isShop)}><Shop storeId={storeId} /></div>
      <div className={paneClass(isHome)}><Home /></div>
      <div className={paneClass(isProduct)}><Outlet /></div>
      <TabBar shopPath={lastShopPath.current} active={active} />
    </div>
  );
}

function paneClass(visible: boolean): string {
  return `tabpane${visible ? "" : " is-hidden"}`;
}

export function AppRouter() {
  return (
    <Routes>
      <Route element={<LiffGate />}>
        {/* 兩個分頁由 TabShell 自己掛著,所以這幾條只負責讓路徑合法(不被 *
            吃掉)並餵給 TabShell 的 useLocation / matchPath;Outlet 只載商品頁。 */}
        <Route element={<TabShell />}>
          <Route path="/" element={<></>} />
          {/* 店家 QR 的落點:resolve-link 302 到 ${LIFF_URL}/store/{store_id}。 */}
          <Route path="/store/:storeId" element={<></>} />
          <Route path="/home" element={<></>} />
          <Route path="/product/:id" element={<ProductDetail />} />
        </Route>
        {/* Onboarding 是全螢幕的一段流程,和 app 一樣站在分頁殼之外。 */}
        <Route path="/onboard" element={<Onboard />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
