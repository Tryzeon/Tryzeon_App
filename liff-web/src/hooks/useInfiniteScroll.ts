import { useEffect, type RefObject } from "react";

/** How far below the fold the next page starts loading. */
const MARGIN_PX = 600;

export function useInfiniteScroll(
  sentinel: RefObject<HTMLElement | null>,
  onReach: () => void,
  { enabled, itemCount }: { enabled: boolean; itemCount: number },
) {
  useEffect(() => {
    const node = sentinel.current;
    if (!node || !enabled) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) onReach();
      },
      { rootMargin: `${MARGIN_PX}px` },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [sentinel, onReach, enabled]);

  // A page short enough to leave the sentinel on screen would otherwise stall
  // the list: IntersectionObserver reports *changes*, and nothing changed.
  // Measuring outright after each append keeps that case off the observer.
  useEffect(() => {
    const node = sentinel.current;
    if (!node || !enabled) return;
    if (node.getBoundingClientRect().top - MARGIN_PX <= window.innerHeight) onReach();
  }, [sentinel, onReach, enabled, itemCount]);
}
