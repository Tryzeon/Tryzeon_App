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
  // The avatar and the gallery are mounted here rather than inside each page:
  // both tabs must see the same one, and a trip through the shop and back must
  // leave the try-ons that were just made intact.
  return (
    <AvatarProvider initialPath={avatarPath}>
      <GalleryProvider>
        <Outlet />
      </GalleryProvider>
    </AvatarProvider>
  );
}

/**
 * Switching tabs no longer unmounts and rebuilds, so the avatar is not re-signed
 * on every visit to home and the catalog is not refetched on every return, and
 * each pane is its own scroll container whose position the browser keeps — no
 * manual save/restore. The product page is excluded: it is a detail screen
 * showing a different item each time, so rebuilding it is the right thing.
 */
function TabShell() {
  const { pathname } = useLocation();

  const isHome = pathname === "/home";
  const isProduct = pathname.startsWith("/product/");
  const isShop = !isHome && !isProduct;

  const lastShopPath = useRef("/");
  if (isShop) lastShopPath.current = pathname;

  // The store id comes from the path the shop tab remembers, not the current
  // URL — on home the current URL does not match /store/:storeId, and querying
  // with that would quietly swap the store's catalog for the site-wide one.
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
        {/* TabShell mounts both tabs itself, so these routes only keep the
            paths legal (not swallowed by *) and feed TabShell's useLocation /
            matchPath; the Outlet renders the product page only. */}
        <Route element={<TabShell />}>
          <Route path="/" element={<></>} />
          {/* Where a store QR lands: resolve-link 302s to
              ${LIFF_URL}/store/{store_id}. */}
          <Route path="/store/:storeId" element={<></>} />
          <Route path="/home" element={<></>} />
          <Route path="/product/:id" element={<ProductDetail />} />
        </Route>
        {/* Onboarding is a full-screen flow that sits outside the tab shell,
            same as in the app. */}
        <Route path="/onboard" element={<Onboard />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
