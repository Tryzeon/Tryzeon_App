import { Link } from "react-router-dom";

export type ActiveTab = "home" | "shop" | null;

/**
 * The tab shell decides which tab is active rather than letting NavLink match
 * paths itself: the shop tab links to wherever it was left (possibly
 * /store/:id), and on the product page neither tab should light up.
 *
 * Both links `replace`: switching tabs changes the view, it is not a step
 * forward. With push, every switch would stack a history entry, LINE's back
 * button would bounce between tabs instead of leaving the screen, and
 * re-tapping the current tab would stack yet another.
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
