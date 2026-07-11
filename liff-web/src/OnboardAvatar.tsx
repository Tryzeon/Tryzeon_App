import { useEffect, useState } from "react";
import { getIdToken, initAndLogin } from "./liff";
import { fileToBase64 } from "./image";
import { setAvatar } from "./onboard";

type Phase = "init" | "ready" | "saving" | "done" | "error";

export function OnboardAvatar() {
  const [phase, setPhase] = useState<Phase>("init");
  const [message, setMessage] = useState("");

  useEffect(() => {
    (async () => {
      try {
        await initAndLogin();
        setPhase("ready");
      } catch {
        setMessage("請從 LINE 開啟此頁面");
        setPhase("error");
      }
    })();
  }, []);

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
        {message && <div className="errorcard">{message}</div>}
      </main>
      <div className="actionbar">
        <label className={`cta${phase === "saving" ? " is-disabled" : ""}`}>
          {phase === "saving" ? "儲存中…" : "上傳我的 model 照"}
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
