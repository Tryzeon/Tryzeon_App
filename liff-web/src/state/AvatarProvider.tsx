import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { avatarUrl, setAvatar } from "../api/avatar";

interface AvatarValue {
  /** 能放進 `<img>` 的網址,還沒簽好或沒有照片時是 null。 */
  url: string | null;
  /** 這個人有沒有 model 照。不等於 [url] 已經備妥 —— 簽章還在路上時仍然是 true。 */
  hasAvatar: boolean;
  status: "loading" | "ready" | "error";
  busy: boolean;
  /** 換一張。回傳 false 代表失敗,舊的那張留著。 */
  replace(file: File): Promise<boolean>;
}

const AvatarContext = createContext<AvatarValue | null>(null);

/**
 * 模特照,整個 app 一份。
 *
 * 掛在分頁之上,所以簽章只求一次,而首頁和商品頁看到的是同一個狀態 —— 在商品頁
 * 補上傳的照片,回到首頁就是那一張。
 */
export function AvatarProvider(
  { initialPath, children }: { initialPath: string | null; children: ReactNode },
) {
  const [path, setPath] = useState(initialPath);
  const [url, setUrl] = useState<string | null>(null);
  const [status, setStatus] = useState<AvatarValue["status"]>(
    initialPath === null ? "ready" : "loading",
  );
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (path === null) {
      setUrl(null);
      setStatus("ready");
      return;
    }

    let live = true;
    setStatus("loading");
    avatarUrl(path).then(
      (signed) => {
        if (!live) return;
        setUrl(signed);
        setStatus("ready");
      },
      () => {
        if (live) setStatus("error");
      },
    );
    return () => {
      live = false;
    };
  }, [path]);

  const replace = useCallback(async (file: File): Promise<boolean> => {
    setBusy(true);
    try {
      setPath(await setAvatar(file));
      return true;
    } catch {
      return false;
    } finally {
      setBusy(false);
    }
  }, []);

  const value = useMemo(
    () => ({ url, hasAvatar: path !== null, status, busy, replace }),
    [url, path, status, busy, replace],
  );

  return <AvatarContext.Provider value={value}>{children}</AvatarContext.Provider>;
}

export function useAvatar(): AvatarValue {
  const value = useContext(AvatarContext);
  if (value === null) throw new Error("useAvatar outside AvatarProvider");
  return value;
}
