import { createPortal } from "react-dom";
import type { ReactNode } from "react";

/**
 * The pane is position: fixed and therefore its own stacking context — a z-index
 * inside it only competes within that context, and no value is high enough to
 * cover the tab bar outside it.
 */
export function Overlay({ children }: { children: ReactNode }) {
  return createPortal(children, document.body);
}
