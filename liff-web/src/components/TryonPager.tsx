import { useEffect, useMemo, useRef } from "react";
import { nextLoadingVideo } from "../lib/loadingVideos";
import type { GalleryEntry } from "../state/gallery";

/** 捲動停下來多久才算「使用者選定了這一頁」。 */
const SETTLE_MS = 120;

/** 判斷「已經在這一頁」的容許誤差,吸附後的位置常有次像素殘留。 */
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
 * 首頁那條可以左右滑的相片流,第 0 頁是模特照。
 *
 * 用 CSS scroll-snap 而不是自己算手勢:原生捲動的慣性、回彈和 LINE webview 的
 * 邊緣手勢本來就相容,自己接 touch 事件只會把它們弄壞。
 */
export function TryonPager(
  { entries, avatarUrl, avatarBusy, page, onPageChange, onAvatarTap, onResultTap }: Props,
) {
  const trackRef = useRef<HTMLDivElement>(null);

  // 這兩個 ref 一起把「狀態 → 捲動位置」和「捲動位置 → 狀態」隔開。少了它們,
  // 兩個方向會互相餵食:平滑捲動經過的每一頁都會被回報成一次換頁,把狀態改掉,
  // 下面那條 effect 就再送一次捲動把畫面拉回中途那一頁 —— 一次跨多頁的跳轉
  // (已經有兩筆試穿時再按一次試穿)因此永遠到不了新的那一頁。
  const target = useRef<number | null>(null);
  const settleTimer = useRef(0);

  useEffect(() => () => window.clearTimeout(settleTimer.current), []);

  // 狀態 → 捲動位置。開始一次新試穿時把那一頁帶到眼前,和 app 的 animateToPage
  // 一樣;已經在正確位置就不必再送一次平滑捲動。
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

    // 平滑捲動「經過」的那幾頁不是使用者的選擇,到站之前一律不回報。
    if (target.current !== null) {
      if (Math.abs(track.scrollLeft - target.current) > TOLERANCE_PX) return;
      target.current = null;
    }

    // 停下來才回報。手指還在拖的時候就改狀態,等於在使用者滑到一半時請上面那條
    // effect 送出一次程式化捲動 —— 正是會跟手指打架的那件事。
    window.clearTimeout(settleTimer.current);
    settleTimer.current = window.setTimeout(() => {
      const settled = trackRef.current;
      if (settled === null || settled.clientWidth === 0) return;
      onPageChange(Math.round(settled.scrollLeft / settled.clientWidth));
    }, SETTLE_MS);
  }

  // 使用者一碰就把程式化捲動的目標作廢:他中途插手的話那個目標永遠不會到達,
  // 留著會讓 handleScroll 從此不再回報任何一頁。
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

/** 生成中的那一頁 —— 和試衣間同一組品牌動畫。 */
function LoadingPage() {
  const src = useMemo(nextLoadingVideo, []);
  return (
    <div className="page page--loading">
      <video className="page__img" src={src} muted loop playsInline autoPlay preload="auto" />
    </div>
  );
}
