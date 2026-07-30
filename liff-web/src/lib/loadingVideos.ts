const LOADING_VIDEOS = [
  "/videos/tryon-loading-animation-1.mp4",
  "/videos/tryon-loading-animation-2.mp4",
  "/videos/tryon-loading-animation-3.mp4",
  "/videos/tryon-loading-animation-4.mp4",
  "/videos/tryon-loading-animation-5.mp4",
];

let order: string[] | null = null;
let nextIndex = 0;

/** Cycles a session-scoped shuffle so consecutive try-ons never repeat a clip. */
export function nextLoadingVideo(): string {
  if (order === null) {
    order = [...LOADING_VIDEOS];
    for (let i = order.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [order[i], order[j]] = [order[j], order[i]];
    }
  }
  const src = order[nextIndex];
  nextIndex = (nextIndex + 1) % order.length;
  return src;
}
