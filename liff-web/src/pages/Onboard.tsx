import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { setAvatar } from "../api/avatar";
import { setOnboarded } from "../lib/onboarding";
import { Header } from "../components/Header";

// LIFF is already initialized + logged in by <LiffGate> before this renders.
type Phase = "ready" | "saving" | "done" | "error";

const CTA_LABEL: Record<Phase, string> = {
  ready: "上傳我的 model 照",
  saving: "儲存中…",
  done: "前往試衣間",
  error: "換一張再試",
};

export function Onboard() {
  const navigate = useNavigate();
  const [phase, setPhase] = useState<Phase>("ready");
  const [message, setMessage] = useState("");
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const previewRef = useRef<string | null>(null);

  // onPick revokes the previous URL; this covers the last one on unmount.
  useEffect(
    () => () => {
      if (previewRef.current) URL.revokeObjectURL(previewRef.current);
    },
    [],
  );

  async function onPick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (previewRef.current) URL.revokeObjectURL(previewRef.current);
    const url = URL.createObjectURL(file);
    previewRef.current = url;
    setPreviewUrl(url);
    setPhase("saving");
    setMessage("");
    try {
      await setAvatar(file);
      setOnboarded(true);
      setPhase("done");
    } catch {
      // Keep the preview — the photo stays on screen next to the error.
      setMessage("儲存失敗，換一張清楚的全身照再試。");
      setPhase("error");
    }
  }

  return (
    <div className="app">
      <Header />
      <main className="main">
        <p className="eyebrow">建立你的 model</p>

        {previewUrl ? (
          <figure className="preview">
            <div className="frame">
              <img className="frame__img" src={previewUrl} alt="你選擇的 model 照" />
              {phase === "saving" && (
                <div className="frame__veil">
                  <span className="spinner" aria-hidden="true" />
                </div>
              )}
              {phase === "done" && (
                <span className="frame__badge" aria-hidden="true">
                  ✓
                </span>
              )}
            </div>
            {phase === "done" && (
              <figcaption className="frame__caption">model 照已建立</figcaption>
            )}
          </figure>
        ) : (
          <>
            <p className="cta__hint">
              上傳一張清楚的全身照，之後所有試穿都會用它。照片只用於試穿。
            </p>
            <div className="tipcard">
              <span className="tipcard__icon" aria-hidden="true">
                💡
              </span>
              <p className="tipcard__text">
                建議上傳短袖短褲的正面全身照，雙手自然下垂、手上不要拿手機等物品。
              </p>
            </div>
          </>
        )}

        {message && <div className="errorcard">{message}</div>}
      </main>

      <div className="actionbar">
        {phase === "done" ? (
          <button type="button" className="cta" onClick={() => navigate("/")}>
            {CTA_LABEL.done}
          </button>
        ) : (
          <label className={`cta${phase === "saving" ? " is-loading" : ""}`}>
            {phase === "saving" ? (
              <span className="cta__spin">
                <span className="spinner" aria-hidden="true" />
                {CTA_LABEL.saving}
              </span>
            ) : (
              CTA_LABEL[phase]
            )}
            {/* Remount per phase so re-picking the same file still fires onChange. */}
            <input
              key={phase}
              type="file"
              accept="image/*"
              disabled={phase === "saving"}
              onChange={onPick}
              style={{ display: "none" }}
            />
          </label>
        )}
        {phase === "done" && (
          <span className="cta__hint">回聊天室再傳一次衣服圖，就會自動幫你試穿。</span>
        )}
      </div>
    </div>
  );
}
