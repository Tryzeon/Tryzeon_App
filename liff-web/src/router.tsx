import { useEffect, useState } from "react";
import { Navigate, Outlet, Route, Routes } from "react-router-dom";
import { initAndLogin } from "./lib/liff";
import { Header } from "./components/Header";
import { Shop } from "./pages/Shop";
import { Onboard } from "./pages/Onboard";

// Initializes LIFF once for the whole app, then renders the matched route.
// Child screens can assume LIFF is ready and the user is logged in.
function LiffGate() {
  const [state, setState] = useState<"loading" | "ready" | "error">("loading");

  useEffect(() => {
    initAndLogin().then(
      () => setState("ready"),
      () => setState("error"),
    );
  }, []);

  if (state === "loading") {
    return <div className="app"><Header /></div>;
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
        <Route path="/onboard" element={<Onboard />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
