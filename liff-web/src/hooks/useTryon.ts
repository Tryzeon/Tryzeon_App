import { useCallback, useRef, useState } from "react";
import { ApiError } from "../api/errors";
import { callTryon } from "../api/tryon";
import { setAvatar } from "../api/avatar";
import { setOnboarded } from "../lib/onboarding";
import type { CatalogItem } from "../api/catalog";

export type TryonState =
  | { phase: "idle" }
  | { phase: "uploading"; item: CatalogItem }
  | { phase: "generating"; item: CatalogItem }
  | { phase: "done"; item: CatalogItem; imageUrl: string }
  | { phase: "error"; item: CatalogItem; message: string };

function failureMessage(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.status === 429) return "今日試穿次數已用完，明天再回來試。";
    if (err.status === 422) return "這張照片沒能生成，請稍後再試。";
  }
  return "出了點狀況，請稍後再試。";
}

/**
 * 試衣的狀態機。
 *
 * 沒有 model 照這件事不再由回應告訴我們 —— `toApiError` 只取 status,而每一種
 * 要分開講的失敗(429 額度、422 生成失敗)光看 status 就夠了。補照片的分支在
 * Task 8 由路由層的強制 onboarding 取代。
 */
export function useTryon() {
  const [state, setState] = useState<TryonState>({ phase: "idle" });

  // Bumped by reset() so a generation the user has already backed out of can't
  // land a state write after the fact (e.g. the try-on response arriving late).
  const token = useRef(0);

  const generate = useCallback(async (item: CatalogItem) => {
    const mine = ++token.current;
    setState({ phase: "generating", item });
    try {
      const imageUrl = await callTryon(item.productId);
      if (mine !== token.current) return;
      setState({ phase: "done", item, imageUrl });
    } catch (err) {
      if (mine !== token.current) return;
      setState({ phase: "error", item, message: failureMessage(err) });
    }
  }, []);

  // 上傳完直接接著試穿剛剛選的那件,使用者不必再點一次,也不會回到目錄後找不到
  // 原本看的商品。
  const uploadAvatarAndGenerate = useCallback(
    async (item: CatalogItem, file: File) => {
      const mine = ++token.current;
      setState({ phase: "uploading", item });
      try {
        await setAvatar(file);
        setOnboarded(true);
      } catch {
        if (mine !== token.current) return;
        setState({
          phase: "error",
          item,
          message: "照片上傳失敗，換一張清楚的全身照再試。",
        });
        return;
      }
      if (mine !== token.current) return;
      await generate(item);
    },
    [generate],
  );

  const reset = useCallback(() => {
    token.current += 1;
    setState({ phase: "idle" });
  }, []);

  return { state, generate, uploadAvatarAndGenerate, reset };
}
