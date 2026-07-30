export function Header({ overlay = false }: { overlay?: boolean }) {
  return (
    <header className={overlay ? "header header--overlay" : "header"}>
      <p className="header__eyebrow">Virtual Try-On</p>
      <h1 className="header__mark">Tryzeon</h1>
    </header>
  );
}
