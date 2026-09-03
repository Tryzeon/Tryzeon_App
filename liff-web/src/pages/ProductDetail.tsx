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

/** This page is done the moment try-on is tapped: the coordinator moves the
 * user to home, and the result lands in that gallery. */
export function ProductDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const location = useLocation();

  // Arriving from the catalog, the row travelled along with the navigation, so
  // render it straight away instead of flashing a skeleton. Only a direct URL
  // (a LINE message, a shared link) has none, and that is when we fetch.
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

  // Decided by location.key — react-router only gives the key "default" to the
  // entry that was already there on arrival. Not history.length: LIFF reaches
  // this URL through a chain of redirects, so on a deep link it is already
  // greater than 1, and using it would send the user back to a redirect page,
  // straight out of this app.
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
