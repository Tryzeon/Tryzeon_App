import { useState } from "react";
import { getIdToken } from "./liff";
import { fileToBase64 } from "./image";
import { setAvatar } from "./onboard";

// LIFF is already initialized + logged in by <LiffGate> before this renders.
type Phase = "ready" | "saving" | "done" | "error";

export function OnboardAvatar() {
  const [phase, setPhase] = useState<Phase>("ready");
  const [message, setMessage] = useState("");

  async function onPick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setPhase("saving");
    setMessage("");
    try {
      const avatarBase64 = await fileToBase64(file, 1024);
      await setAvatar(getIdToken(), avatarBase64);
      setPhase("done");
    } catch {
      setMessage("儲存失敗，換一張清楚的全身照再試。");
      setPhase("error");
    }
  }

  const Header = (
    <header className="header">
      <p className="header__eyebrow">Virtual Try-On</p>
      <h1 className="header__mark">Tryzeon</h1>
    </header>
  );

  if (phase === "done") {
    return (
      <div className="app">
        {Header}
        <div className="result">
          <p className="result__caption">model 照已建立 ✓</p>
          <p className="cta__hint">回聊天室再傳一次衣服圖，就會自動幫你試穿。</p>
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      {Header}
      <main className="main">
        <p className="eyebrow">建立你的 model</p>
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
        {message && <div className="errorcard">{message}</div>}
      </main>
      <div className="actionbar">
        <label className={`cta${phase === "saving" ? " is-loading" : ""}`}>
          {phase === "saving" ? (
            <span className="cta__spin">
              <span className="spinner" aria-hidden="true" />
              儲存中…
            </span>
          ) : (
            "上傳我的 model 照"
          )}
          <input
            type="file"
            accept="image/*"
            disabled={phase === "saving"}
            onChange={onPick}
            style={{ display: "none" }}
          />
        </label>
      </div>
    </div>
  );
}
