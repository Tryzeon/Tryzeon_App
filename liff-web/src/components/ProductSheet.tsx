import type { CatalogItem } from "../api/catalog";
import { isExternalUrl, openExternal } from "../lib/liff";
import type { TryonState } from "../hooks/useTryon";
import { AvatarUploadPrompt } from "./AvatarUploadPrompt";

interface Props {
  item: CatalogItem;
  tryon: TryonState;
  onClose(): void;
  onTryon(): void;
  onPickAvatar(file: File): void;
}

export function ProductSheet({ item, tryon, onClose, onTryon, onPickAvatar }: Props) {
  const needAvatar = tryon.phase === "needAvatar" || tryon.phase === "uploading";
  const buyUrl = item.purchaseLink && isExternalUrl(item.purchaseLink) ? item.purchaseLink : null;

  return (
    <div className="sheet" role="dialog" aria-modal="true" aria-label={item.name}>
      <div className="sheet__backdrop" onClick={onClose} />
      <div className="sheet__panel">
        <button type="button" className="sheet__close" onClick={onClose} aria-label="關閉">
          ✕
        </button>

        <div className="gallery">
          {item.imageUrls.map((url) => (
            <img key={url} className="gallery__img" src={url} alt="" />
          ))}
        </div>

        <div className="sheet__body">
          <h2 className="sheet__name">{item.name}</h2>
          {item.storeName && <p className="sheet__store">{item.storeName}</p>}
          {item.price != null && <p className="sheet__price">NT${item.price}</p>}

          {tryon.phase === "error" && <div className="errorcard">{tryon.message}</div>}

          {needAvatar
            ? <AvatarUploadPrompt busy={tryon.phase === "uploading"} onPick={onPickAvatar} />
            : <button type="button" className="cta" onClick={onTryon}>開始試穿</button>}

          {buyUrl && (
            <button
              type="button"
              className="btn-outline sheet__buy"
              onClick={() => openExternal(buyUrl)}
            >
              前往購買
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
