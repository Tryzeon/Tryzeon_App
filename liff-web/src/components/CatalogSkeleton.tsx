export function CatalogSkeleton() {
  return (
    <div className="grid">
      {Array.from({ length: 6 }).map((_, i) => <div key={i} className="sk sk--card" />)}
    </div>
  );
}
