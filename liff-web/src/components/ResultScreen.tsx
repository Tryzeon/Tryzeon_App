import { useState } from "react";
import type { CatalogItem } from "../api/catalog";
import { isExternalUrl, openExternal } from "../lib/liff";

interface Props {
  item: CatalogItem;
  imageUrl: string;
  onBack(): void;
}

export function ResultScreen({ item, imageUrl, onBack }: Props) {
  const buyUrl = item.purchaseLink && isExternalUrl(item.purchaseLink) ? item.purchaseLink : null;

  const [status, setStatus] = useState<"loading" | "ready" | "error">("loading");

  return (
    <div className="result">
      <div className={`result__frame${status === "ready" ? "" : " is-pending"}`}>
        <img
          className="result__img"
          src={imageUrl}
          alt="試穿結果"
          onLoad={() => setStatus("ready")}
          onError={() => setStatus("error")}
        />
        {status === "loading" && <div className="sk result__sk" />}
        {status === "error" && <p className="result__failed">圖片載入失敗，請再試一次</p>}
      </div>
      <p className="result__caption">試穿 <b>{item.name}</b></p>
      <p className="result__disclaimer">AI 生成試穿結果，實際商品以賣場為準</p>
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
