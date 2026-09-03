import { Link } from "react-router-dom";

export type ActiveTab = "home" | "shop" | null;

/**
 * 哪一格是 active 由分頁殼說了算,不用 NavLink 自己比對路徑:試衣間那格連到的
 * 是它上次停的位置(可能是 /store/:id),而在商品頁時兩格都不該亮。
 *
 * 兩格都是 `replace`:換分頁是換視角,不是往前走一步。用 push 的話切幾次分頁就
 * 疊幾筆歷史,LINE 的返回鍵會在分頁之間來回倒退而不是離開這個畫面,重複點目前
 * 這一格還會再疊一筆。
 */
export function TabBar({ shopPath, active }: { shopPath: string; active: ActiveTab }) {
  return (
    <nav className="tabbar">
      <Link to="/home" replace className={tabClass(active === "home")}>首頁</Link>
      <Link to={shopPath} replace className={tabClass(active === "shop")}>試衣間</Link>
    </nav>
  );
}

function tabClass(isActive: boolean): string {
  return `tabbar__tab${isActive ? " is-active" : ""}`;
}
