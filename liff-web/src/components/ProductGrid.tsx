import type { CatalogItem } from "../api/catalog";
import { ProductCard } from "./ProductCard";

interface Props {
  items: CatalogItem[];
  onOpen(item: CatalogItem): void;
}

export function ProductGrid({ items, onOpen }: Props) {
  return (
    <div className="grid">
      {items.map((item) => (
        <ProductCard key={item.productId} item={item} onOpen={() => onOpen(item)} />
      ))}
    </div>
  );
}
