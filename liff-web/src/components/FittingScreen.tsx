import { useEffect, useState } from "react";

// Rotating copy for the ~30s generation wait — a calm "fitting" sequence.
const FITTING_STATUS = [
  "正在讀取你的輪廓",
  "正在讓衣服合身",
  "正在打光與細節",
  "即將完成",
];

export function FittingScreen({ imageUrl }: { imageUrl: string }) {
  const [idx, setIdx] = useState(0);

  useEffect(() => {
    const id = setInterval(
      () => setIdx((i) => Math.min(i + 1, FITTING_STATUS.length - 1)),
      3000,
    );
    return () => clearInterval(id);
  }, []);

  return (
    <div className="fit">
      <div className="frame">
        <img className="frame__img" src={imageUrl} alt="" />
        <div className="fit__scan" />
      </div>
      <div>
        <div className="fit__status">{FITTING_STATUS[idx]}</div>
        <div className="fit__sub">約 15 秒</div>
      </div>
    </div>
  );
}
