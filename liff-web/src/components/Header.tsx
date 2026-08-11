export function Header(
  { overlay = false, title }: { overlay?: boolean; title?: string | null },
) {
  return (
    <header className={overlay ? "header header--overlay" : "header"}>
      <p className="header__eyebrow">Virtual Try-On</p>
      <h1 className="header__mark">{title ?? "Tryzeon"}</h1>
    </header>
  );
}
