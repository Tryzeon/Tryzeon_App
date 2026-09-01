import { useEffect, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { fetchProduct, type CatalogItem } from "../api/catalog";
import { AvatarUploadPrompt } from "../components/AvatarUploadPrompt";
import { Header } from "../components/Header";
import { useTryonCoordinator } from "../hooks/useTryonCoordinator";
import { isExternalUrl, openExternal } from "../lib/liff";
import { useAvatar } from "../state/AvatarProvider";

type Load =
  | { status: "loading" }
  | { status: "ready"; item: CatalogItem }
  | { status: "missing" }
  | { status: "error" };

/**
 * 一件商品一個網址(`/product/{id}`)。
 *
 * 從 bottom sheet 改成獨立的頁面,是為了讓商品可以被連結、被分享、被 LINE 訊息
 * 直接指過來 —— sheet 掛在目錄的查詢字串上,那些事一件都做不到。
 *
 * 按下試穿之後這一頁就結束了:coordinator 把人帶去首頁,結果落在那條 gallery 裡,
 * 和 app 一樣。
 */
export function ProductDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const location = useLocation();

  // 從目錄點進來的話那一筆已經跟著換頁帶過來了,直接畫,不必閃一次骨架。直接開
  // 網址(LINE 訊息、分享出去的連結)進來才沒有,那時候才去查。
  const seeded = seededItem(location.state);
  const [load, setLoad] = useState<Load>(
    seeded === null ? { status: "loading" } : { status: "ready", item: seeded },
  );
  const needsFetch = seeded === null;

  useEffect(() => {
    if (id === undefined || !needsFetch) return;

    let live = true;
    setLoad({ status: "loading" });
    fetchProduct(id).then(
      (item) => {
        if (!live) return;
        setLoad(item === null ? { status: "missing" } : { status: "ready", item });
      },
      () => {
        if (live) setLoad({ status: "error" });
      },
    );
    return () => {
      live = false;
    };
  }, [id, needsFetch]);

  // 沒有上一頁可回(從 LINE 訊息直接點進來)就落到目錄,而不是把人留在死路上。
  //
  // 判斷依據是 location.key —— react-router 只會給「進來時就在的那一筆」
  // "default" 這個 key。不用 history.length:LIFF 是經過一串轉址才走到這個網址
  // 的,深連結進來時它早就大於 1,拿它判斷會把人送回轉址頁,直接彈出這個 app。
  function goBack() {
    if (location.key === "default") navigate("/");
    else navigate(-1);
  }

  return (
    <div className="app">
      <Header title={load.status === "ready" ? load.item.storeName : null} />
      <main className="main pdp">
        <button type="button" className="pdp__back" onClick={goBack}>← 返回</button>

        {load.status === "loading" && <DetailSkeleton />}

        {load.status === "missing" && (
          <p className="empty">找不到這件商品，它可能已經下架了。</p>
        )}

        {load.status === "error" && (
          <>
            <div className="errorcard">商品載入失敗，請稍後再試。</div>
            <button className="loadmore" onClick={() => navigate(0)}>重新載入</button>
          </>
        )}

        {load.status === "ready" && <Detail item={load.item} />}
      </main>
    </div>
  );
}

function Detail({ item }: { item: CatalogItem }) {
  const avatar = useAvatar();
  const tryon = useTryonCoordinator();

  const buyUrl = item.purchaseLink && isExternalUrl(item.purchaseLink)
    ? item.purchaseLink
    : null;
  const hasPhotos = item.imageUrls.length > 0;

  // 補上傳的照片存起來之後直接接著試穿,使用者不必再點一次。
  async function pickAvatarAndTryon(file: File) {
    if (await avatar.replace(file)) await tryon.fromProduct(item);
  }

  return (
    <>
      <div className="gallery">
        {hasPhotos
          ? item.imageUrls.map((url) => (
            <img key={url} className="gallery__img" src={url} alt="" />
          ))
          : <div className="gallery__img gallery__img--empty">暫無照片</div>}
      </div>

      <h1 className="pdp__name">{item.name}</h1>
      {item.storeName && <p className="sheet__store">{item.storeName}</p>}
      {item.price != null && <p className="sheet__price">NT${item.price}</p>}

      {!hasPhotos
        ? <p className="sheet__note">這件商品還沒有照片，無法試穿。</p>
        : avatar.hasAvatar
        ? (
          <button
            type="button"
            className="cta"
            onClick={() => tryon.fromProduct(item)}
          >
            開始試穿
          </button>
        )
        : <AvatarUploadPrompt busy={avatar.busy} onPick={pickAvatarAndTryon} />}

      {buyUrl && (
        <button
          type="button"
          className="btn-outline sheet__buy"
          onClick={() => openExternal(buyUrl)}
        >
          前往購買
        </button>
      )}
    </>
  );
}

/** 換頁時一起帶過來的那一筆商品,沒有或形狀不對就是 null。 */
function seededItem(state: unknown): CatalogItem | null {
  if (typeof state !== "object" || state === null) return null;
  const item = (state as { item?: unknown }).item;
  if (typeof item !== "object" || item === null) return null;
  return typeof (item as CatalogItem).productId === "string"
    ? item as CatalogItem
    : null;
}

function DetailSkeleton() {
  return (
    <>
      <div className="sk pdp__skgallery" />
      <div className="sk pdp__skline" />
      <div className="sk pdp__skline pdp__skline--short" />
    </>
  );
}
