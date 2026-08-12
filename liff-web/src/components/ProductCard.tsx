import type { CatalogItem } from "../api/catalog";

export function ProductCard({ item, onOpen }: { item: CatalogItem; onOpen(): void }) {
  return (
    <button type="button" className="card" onClick={onOpen}>
      {item.imageUrls.length > 0
        ? <img className="card__img" src={item.imageUrls[0]} alt="" loading="lazy" />
        : <span className="card__img card__img--empty">暫無照片</span>}
      <span className="card__meta">
        <span className="card__name">{item.name}</span>
        {item.storeName && <span className="card__store">{item.storeName}</span>}
        {item.price != null && <span className="card__price">NT${item.price}</span>}
      </span>
    </button>
  );
}
