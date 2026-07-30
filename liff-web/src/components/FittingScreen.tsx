import { useState } from "react";
import { nextLoadingVideo } from "../lib/loadingVideos";

const prefersReducedMotion = () =>
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/** Full-bleed brand animation for the ~15s generation wait. */
export function FittingScreen() {
  const [src] = useState(nextLoadingVideo);
  const [autoPlay] = useState(() => !prefersReducedMotion());

  return (
    <div className="fit">
      <video
        className="fit__video"
        src={src}
        muted
        loop
        playsInline
        autoPlay={autoPlay}
        preload="auto"
      />
    </div>
  );
}
