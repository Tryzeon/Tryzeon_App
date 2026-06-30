import { useEffect, useState } from "react";
import { getIdToken, initAndLogin } from "./liff";
import { fileToBase64 } from "./image";
import { callTryon, fetchCatalog, type CatalogItem, type TryonError } from "./api";

type Phase = "init" | "ready" | "generating" | "done" | "error";

// Fetch consecutive catalog pages from startOffset until at least one usable
// item is collected or the server reports no more pages. Products with no
// R2-hosted image are filtered out server-side, so a page can legitimately
// come back empty while more pages remain — keep paging so those rows never
// strand the user. Capped to avoid a runaway when many pages are all-filtered.
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
      if (ex.status === 429) setMessage("今日試穿次數已用完，請明天再試。");
      else if (ex.status === 422) setMessage("生成失敗，請換一張清楚的全身照再試。");
      else setMessage("發生錯誤，請稍後再試。");
      setPhase("error");
    }
  }

  if (phase === "init") return <main style={S.wrap}>載入中…</main>;

  if (phase === "done") {
    return (
      <main style={S.wrap}>
        <h1 style={S.h1}>Tryzeon 虛擬試穿</h1>
        <img src={resultUrl} alt="試穿結果" style={S.result} />
        <button style={S.cta} onClick={() => setPhase("ready")}>再試一件</button>
      </main>
    );
  }

  return (
    <main style={S.wrap}>
      <h1 style={S.h1}>Tryzeon 虛擬試穿</h1>
      <p style={S.label}>選一件商品試穿</p>

      {items.length === 0 && <p style={S.label}>目前沒有可試穿的商品。</p>}

      {items.length > 0 && (
        <div style={S.grid}>
          {items.map((item) => (
            <button
              key={item.productId}
              onClick={() => setSelected(item.productId)}
              style={{ ...S.card, ...(selected === item.productId ? S.cardActive : {}) }}
            >
              <img src={item.imageUrl} alt={item.name} style={S.cardImg} />
              <span style={S.cardName}>{item.name}</span>
              {item.price != null && <span style={S.cardPrice}>NT${item.price}</span>}
            </button>
          ))}
        </div>
      )}

      {hasMore && (
        <button style={S.more} disabled={loadingMore} onClick={onLoadMore}>
          {loadingMore ? "載入中…" : "載入更多"}
        </button>
      )}

      {items.length > 0 && (
        <label style={{ ...S.cta, ...(selected ? {} : S.ctaDisabled) }}>
          {phase === "generating" ? "生成中…（約 30 秒）" : "上傳照片開始試穿"}
          <input
            key={phase}
            type="file"
            accept="image/*"
            disabled={phase === "generating" || !selected}
            onChange={onPick}
            style={{ display: "none" }}
          />
        </label>
      )}

      {message && <p style={S.error}>{message}</p>}
    </main>
  );
}

const S: Record<string, React.CSSProperties> = {
  wrap: { padding: 16, fontFamily: "system-ui, sans-serif", maxWidth: 480, margin: "0 auto" },
  h1: { fontSize: 20, fontWeight: 700 },
  label: { marginTop: 12, color: "#555" },
  grid: { display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 },
  card: { display: "flex", flexDirection: "column", alignItems: "center", gap: 4, padding: 6, border: "1px solid #ddd", borderRadius: 8, background: "#fff", cursor: "pointer" },
  cardActive: { borderColor: "#333", borderWidth: 2 },
  cardImg: { width: "100%", aspectRatio: "3/4", objectFit: "cover", borderRadius: 6 },
  cardName: { fontSize: 12, textAlign: "center" },
  cardPrice: { fontSize: 12, fontWeight: 600 },
  more: { display: "block", width: "100%", marginTop: 12, padding: "10px", background: "#fff", border: "1px solid #ccc", borderRadius: 8, cursor: "pointer" },
  cta: { display: "block", textAlign: "center", marginTop: 16, padding: "14px 16px", background: "#333", color: "#fff", borderRadius: 8, border: "none", cursor: "pointer" },
  ctaDisabled: { background: "#bbb", cursor: "not-allowed" },
  result: { width: "100%", borderRadius: 12 },
  error: { marginTop: 12, color: "#c00" },
};
