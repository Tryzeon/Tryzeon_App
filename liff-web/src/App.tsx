import { useEffect, useState } from "react";
import { getIdToken, initAndLogin } from "./liff";
import { fileToBase64 } from "./image";
import { callTryon, fetchCatalog, type CatalogItem, type TryonError } from "./api";

type Phase = "init" | "ready" | "generating" | "done" | "error";

// Rotating copy for the ~30s generation wait — a calm "fitting" sequence.
const FITTING_STATUS = [
  "正在讀取你的輪廓",
  "正在讓衣服合身",
  "正在打光與細節",
  "即將完成",
];

// Fetch consecutive catalog pages from startOffset until at least one usable
// item is collected or the server reports no more pages. Products with no
// R2-hosted image are filtered out server-side, so a page can come back empty
// while more pages remain — keep paging so those rows never strand the user.
async function collectUntilNonEmpty(
  startOffset: number,
): Promise<{ items: CatalogItem[]; offset: number; hasMore: boolean }> {
  let offset = startOffset;
  let hasMore = false;
  const items: CatalogItem[] = [];
  for (let i = 0; i < 10; i++) {
    const page = await fetchCatalog(offset);
    items.push(...page.items);
    offset = page.nextOffset;
    hasMore = page.hasMore;
    if (items.length > 0 || !hasMore) break;
  }
  return { items, offset, hasMore };
}

export function App() {
  const [phase, setPhase] = useState<Phase>("init");
  const [items, setItems] = useState<CatalogItem[]>([]);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [selected, setSelected] = useState<string | null>(null);
  const [resultUrl, setResultUrl] = useState("");
  const [message, setMessage] = useState("");
  const [statusIdx, setStatusIdx] = useState(0);

  const selectedItem = items.find((i) => i.productId === selected) ?? null;

  useEffect(() => {
    (async () => {
      try {
        await initAndLogin();
      } catch {
        setMessage("請從 LINE 開啟此頁面");
        setPhase("error");
        return;
      }
      try {
        const page = await collectUntilNonEmpty(0);
        setItems(page.items);
        setOffset(page.offset);
        setHasMore(page.hasMore);
        setSelected(page.items[0]?.productId ?? null);
        setPhase("ready");
      } catch {
        setMessage("目錄載入失敗，請稍後再試。");
        setPhase("error");
      }
    })();
  }, []);

  // Cycle the fitting status copy only while generating.
  useEffect(() => {
    if (phase !== "generating") return;
    setStatusIdx(0);
    const id = setInterval(
      () => setStatusIdx((i) => Math.min(i + 1, FITTING_STATUS.length - 1)),
      2600,
    );
    return () => clearInterval(id);
  }, [phase]);

  async function onLoadMore() {
    setLoadingMore(true);
    try {
      const page = await collectUntilNonEmpty(offset);
      if (page.items.length > 0) setItems((prev) => [...prev, ...page.items]);
      setOffset(page.offset);
      setHasMore(page.hasMore);
    } catch {
      // Keep what we have; a load-more failure is non-fatal.
    } finally {
      setLoadingMore(false);
    }
  }

  async function onPick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !selected) return;
    setPhase("generating");
    setMessage("");
    try {
      const avatarBase64 = await fileToBase64(file, 1024);
      const { imageUrl } = await callTryon(getIdToken(), avatarBase64, selected);
      setResultUrl(imageUrl);
      setPhase("done");
    } catch (err) {
      const ex = err as TryonError;
      if (ex.status === 429) setMessage("今日試穿次數已用完，明天再回來試。");
      else if (ex.status === 422) setMessage("這張照片沒能生成，換一張清楚的全身照再試。");
      else setMessage("出了點狀況，請稍後再試。");
      setPhase("error");
    }
  }

  const Header = (
    <header className="header">
      <p className="header__eyebrow">Virtual Try-On</p>
      <h1 className="header__mark">Tryzeon</h1>
    </header>
  );

  // ── init: skeleton ──────────────────────────────────────────────────────
  if (phase === "init") {
    return (
      <div className="app">
        {Header}
        <main className="main">
          <p className="eyebrow">選一件商品試穿</p>
          <div className="grid">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="sk sk--card" />
            ))}
          </div>
        </main>
      </div>
    );
  }

  // ── generating: the fitting ceremony ──────────────────────────────────────
  if (phase === "generating") {
    return (
      <div className="app">
        {Header}
        <div className="fit">
          {selectedItem && (
            <div className="frame">
              <img className="frame__img" src={selectedItem.imageUrl} alt="" />
              <div className="fit__scan" />
            </div>
          )}
          <div>
            <div className="fit__status">{FITTING_STATUS[statusIdx]}</div>
            <div className="fit__sub">約 30 秒</div>
          </div>
        </div>
      </div>
    );
  }

  // ── done: result reveal ───────────────────────────────────────────────────
  if (phase === "done") {
    return (
      <div className="app">
        {Header}
        <div className="result">
          <img className="result__img" src={resultUrl} alt="試穿結果" />
          <p className="result__caption">
            {selectedItem ? <>試穿 <b>{selectedItem.name}</b></> : "你的試穿結果"}
          </p>
          <button className="btn-outline" onClick={() => setPhase("ready")}>
            再試一件
          </button>
        </div>
      </div>
    );
  }

  // ── ready / error: browse catalog ─────────────────────────────────────────
  return (
    <div className="app">
      {Header}
      <main className="main">
        <p className="eyebrow">選一件商品試穿</p>

        {message && <div className="errorcard">{message}</div>}

        {items.length === 0 ? (
          <p className="empty">目前沒有可試穿的商品。</p>
        ) : (
          <div className="grid">
            {items.map((item) => (
              <button
                key={item.productId}
                type="button"
                aria-pressed={selected === item.productId}
                className={`card${selected === item.productId ? " is-selected" : ""}`}
                onClick={() => setSelected(item.productId)}
              >
                <img className="card__img" src={item.imageUrl} alt="" loading="lazy" />
                <span className="card__check" aria-hidden="true">✓</span>
                <span className="card__meta">
                  <span className="card__name">{item.name}</span>
                  {item.price != null && <span className="card__price">NT${item.price}</span>}
                </span>
              </button>
            ))}
          </div>
        )}

        {hasMore && (
          <button className="loadmore" disabled={loadingMore} onClick={onLoadMore}>
            {loadingMore ? "載入中…" : "載入更多"}
          </button>
        )}
      </main>

      {items.length > 0 && (
        <div className="actionbar">
          <label className={`cta${selected ? "" : " is-disabled"}`}>
            {selected ? "上傳照片開始試穿" : "先選一件商品"}
            <input
              key={phase}
              type="file"
              accept="image/*"
              disabled={!selected}
              onChange={onPick}
              style={{ display: "none" }}
            />
          </label>
          <span className="cta__hint">上傳一張全身照，照片不會被保存</span>
        </div>
      )}
    </div>
  );
}
