import { useEffect, useState } from "react";
import { Navigate, Outlet, Route, Routes } from "react-router-dom";
import { initAndLogin } from "./lib/liff";
import { ensureSession } from "./lib/auth";
import { fetchAvatarPath } from "./api/profile";
import { setOnboarded } from "./lib/onboarding";
import { CatalogSkeleton } from "./components/CatalogSkeleton";
import { Header } from "./components/Header";
import { SearchSortBar } from "./components/SearchSortBar";
import { Shop } from "./pages/Shop";
import { Onboard } from "./pages/Onboard";

const noop = () => {};

// Initializes LIFF, opens a Supabase session and learns whether this user has a
// model photo — once, for the whole app — then renders the matched route.
function LiffGate() {
  const [state, setState] = useState<"loading" | "ready" | "error">("loading");

  useEffect(() => {
    initAndLogin()
      .then(ensureSession)
      .then(fetchAvatarPath)
      .then(
        (path) => {
          setOnboarded(path !== null);
          setState("ready");
        },
        () => setState("error"),
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
          <div className="errorcard">請從 LINE 開啟此頁面</div>
        </main>
      </div>
    );
  }
  return <Outlet />;
}

// App route table. Add new screens (wardrobe, chat, results) as sibling
// <Route>s under the LiffGate so they inherit LIFF bootstrap for free.
export function AppRouter() {
  return (
    <Routes>
      <Route element={<LiffGate />}>
        <Route path="/" element={<Shop />} />
        {/* 店家 QR 的落點:resolve-link 302 到 ${LIFF_URL}/store/{store_id}。 */}
        <Route path="/store/:storeId" element={<Shop />} />
        <Route path="/onboard" element={<Onboard />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
