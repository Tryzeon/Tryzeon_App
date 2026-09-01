import { createPortal } from "react-dom";
import type { ReactNode } from "react";

/**
 * 把彈出層掛到 <body>,而不是留在分頁 pane 裡面。
 *
 * pane 是 position: fixed,它自己就是一個 stacking context —— 留在裡面的 z-index
 * 只在那個 context 內部比大小,再高也蓋不過外面的分頁列。
 */
export function Overlay({ children }: { children: ReactNode }) {
  return createPortal(children, document.body);
}
