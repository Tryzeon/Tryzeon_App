import { useEffect, useMemo, useRef } from "react";
import { nextLoadingVideo } from "../lib/loadingVideos";
import type { GalleryEntry } from "../state/gallery";

/** How long scrolling must be still before the page counts as the user's
 * choice. */
const SETTLE_MS = 120;

/** Tolerance for deciding we are already on a page; snapping often leaves a
 * sub-pixel remainder. */
const TOLERANCE_PX = 2;

interface Props {
  entries: GalleryEntry[];
  avatarUrl: string | null;
  avatarBusy: boolean;
  page: number;
  onPageChange(page: number): void;
  onAvatarTap(): void;
  onResultTap(imageUrl: string): void;
}

/**
 * CSS scroll-snap rather than hand-rolled gesture math: native scrolling's
 * momentum and rubber-banding already coexist with LINE's webview edge
 * gestures, and handling touch events ourselves would only break them.
 */
export function TryonPager(
  { entries, avatarUrl, avatarBusy, page, onPageChange, onAvatarTap, onResultTap }: Props,
) {
  const trackRef = useRef<HTMLDivElement>(null);

  // Together these two refs keep state → scroll position and scroll position →
  // state apart. Without them the two directions feed each other: every page a
  // smooth scroll passes through gets reported as a page change, which rewrites
  // the state, and the effect below then scrolls back to that intermediate page
  // — so a multi-page jump (tapping try-on again with two try-ons already
  // there) would never reach the new page.
  const target = useRef<number | null>(null);
  const settleTimer = useRef(0);

  useEffect(() => () => window.clearTimeout(settleTimer.current), []);

  // State → scroll position: bring the new page into view when a try-on starts.
  useEffect(() => {
    const track = trackRef.current;
    if (track === null || track.clientWidth === 0) return;
    const left = page * track.clientWidth;
    if (Math.abs(track.scrollLeft - left) < TOLERANCE_PX) {
      target.current = null;
      return;
    }
    target.current = left;
    track.scrollTo({ left, behavior: "smooth" });
  }, [page]);

  function handleScroll() {
    const track = trackRef.current;
    if (track === null || track.clientWidth === 0) return;

    // Pages a smooth scroll merely passes through are not the user's choice, so
    // report nothing until it arrives.
    if (target.current !== null) {
      if (Math.abs(track.scrollLeft - target.current) > TOLERANCE_PX) return;
      target.current = null;
    }

    // Only report once it settles. Changing state while a finger is still
    // dragging would ask the effect above to fire a programmatic scroll
    // mid-swipe — exactly the thing that fights the finger.
    window.clearTimeout(settleTimer.current);
    settleTimer.current = window.setTimeout(() => {
      const settled = trackRef.current;
      if (settled === null || settled.clientWidth === 0) return;
      onPageChange(Math.round(settled.scrollLeft / settled.clientWidth));
    }, SETTLE_MS);
  }

  // Any touch invalidates the programmatic scroll target: once the user takes
  // over, that target is never reached, and keeping it would stop handleScroll
  // from ever reporting a page again.
  function releaseTarget() {
    target.current = null;
  }

  return (
    <div
      className="pager"
      ref={trackRef}
      onScroll={handleScroll}
      onPointerDown={releaseTarget}
      onTouchStart={releaseTarget}
    >
      <div className="page" onClick={onAvatarTap}>
        {avatarUrl === null
          ? (
            <div className="page__empty">
              <p className="page__emptytitle">還沒有 model 照</p>
              <p className="page__emptyhint">點一下上傳一張清楚的全身照</p>
            </div>
          )
          : <img className="page__img" src={avatarUrl} alt="你的 model 照" />}
        {avatarBusy && (
          <div className="page__veil">
            <span className="spinner" aria-hidden="true" />
          </div>
        )}
      </div>

      {entries.map((entry) =>
        entry.kind === "pending"
          ? <LoadingPage key={entry.id} />
          : (
            <div
              className="page"
              key={entry.id}
              onClick={() => onResultTap(entry.imageUrl)}
            >
              <img className="page__img" src={entry.imageUrl} alt="試穿結果" />
            </div>
          )
      )}
    </div>
  );
}

function LoadingPage() {
  const src = useMemo(nextLoadingVideo, []);
  return (
    <div className="page page--loading">
      <video className="page__img" src={src} muted loop playsInline autoPlay preload="auto" />
    </div>
  );
}
