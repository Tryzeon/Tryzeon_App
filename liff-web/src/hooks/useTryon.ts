import { useCallback, useRef, useState } from "react";
import { getIdToken } from "../lib/liff";
import { setAvatar } from "../api/avatar";
import { ApiError } from "../api/errors";
import { callTryon, NO_AVATAR } from "../api/tryon";
import type { CatalogItem } from "../api/catalog";

export type TryonState =
  | { phase: "idle" }
  | { phase: "needAvatar"; item: CatalogItem }
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
 * The try-on state machine. The client never pre-checks whether the user has a
 * model photo: it calls the endpoint and lets a NO_AVATAR reply open the upload
 * branch, so there is one source of truth for "is this user onboarded".
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
      const imageUrl = await callTryon(getIdToken(), item.productId);
      if (mine !== token.current) return;
      setState({ phase: "done", item, imageUrl });
    } catch (err) {
      if (mine !== token.current) return;
      if (err instanceof ApiError && err.code === NO_AVATAR) {
        setState({ phase: "needAvatar", item });
        return;
      }
      setState({ phase: "error", item, message: failureMessage(err) });
    }
  }, []);

  const uploadAvatarAndGenerate = useCallback(
    async (item: CatalogItem, file: File) => {
      const mine = ++token.current;
      setState({ phase: "uploading", item });
      try {
        await setAvatar(file);
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
