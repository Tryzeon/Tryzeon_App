import type { CatalogItem } from "../api/catalog";
import { isExternalUrl, openExternal } from "../lib/liff";

interface Props {
  item: CatalogItem;
  imageUrl: string;
  onBack(): void;
}

export function ResultScreen({ item, imageUrl, onBack }: Props) {
  const buyUrl = item.purchaseLink && isExternalUrl(item.purchaseLink) ? item.purchaseLink : null;

  return (
    <div className="result">
      <img className="result__img" src={imageUrl} alt="試穿結果" />
      <p className="result__caption">試穿 <b>{item.name}</b></p>
      {buyUrl && (
        <button
          type="button"
          className="cta result__buy"
          onClick={() => openExternal(buyUrl)}
        >
          前往購買
        </button>
      )}
      <button type="button" className="btn-outline" onClick={onBack}>再試一件</button>
    </div>
  );
}
