import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import { tryonFailureMessage } from "../api/errors";
import { runTryon, type Garment } from "../api/tryon";
import { downscaleToBase64, urlToBase64 } from "../lib/image";
import { newId } from "../lib/id";
import { loadPromptConfig } from "../lib/promptConfig";
import { customAvatarUrl, type TryonProduct } from "../state/gallery";
import { useGallery } from "../state/GalleryProvider";

/** 送出前的準備失敗,帶著要對使用者說的那句話。 */
class SetupError extends Error {}

const SETUP_FALLBACK = "讀取試穿形象失敗，請稍後再試。";

/**
 * 所有試穿的唯一入口,對應 app 的 `TryonCoordinator`:先把人帶到首頁,再把工作
 * 交出去。從商品頁按下的試穿和從首頁按下的落在同一條 gallery,所以「看結果的
 * 地方」只有一個。
 */
export function useTryonCoordinator() {
  const { state, dispatch } = useGallery();
  const navigate = useNavigate();

  const run = useCallback(
    async (buildGarment: () => Promise<Garment>, product: TryonProduct | null) => {
      // 佔位頁和換頁擺在所有工作之前:準備一次試穿要讀檔、縮圖,選了形象還要把
      // 那張圖整個抓回來。這些全都發生在按下按鈕之後,擺在前面等於讓畫面靜止到
      // 它們做完為止 —— 動畫要先出來,工作才在它底下跑。
      const id = newId();
      dispatch({ type: "addPending", id, product });
      navigate("/home");

      let garment: Garment;
      let avatarBase64: string | undefined;
      try {
        garment = await buildGarment();

        // 形象圖要重新讀回位元組,這一步依賴 R2 對 LIFF 的 origin 開 CORS。讀不到
        // 就當成沒選過形象是錯的 —— 那會拿 profile 上的模特照生成,和使用者要的
        // 不是同一件事,所以寧可停下來說。
        const chosen = customAvatarUrl(state);
        if (chosen !== null) avatarBase64 = await urlToBase64(chosen);
      } catch (err) {
        dispatch({
          type: "fail",
          id,
          message: err instanceof SetupError ? err.message : SETUP_FALLBACK,
        });
        return;
      }

      try {
        const imageUrl = await runTryon(garment, {
          ...loadPromptConfig(),
          avatarBase64,
        });
        dispatch({ type: "complete", id, imageUrl });
      } catch (err) {
        // `fail` 而不是 remove + notify:使用者可能已經按過「取消生成」,那之後
        // 這次請求的下場不該再打擾他 —— 由 reducer 判斷那一頁還在不在。
        dispatch({ type: "fail", id, message: tryonFailureMessage(err) });
      }
    },
    [state, dispatch, navigate],
  );

  /** 首頁:使用者自己拍的衣服照。 */
  const fromGarmentPhoto = useCallback(
    (file: File) =>
      run(async () => {
        try {
          return { images: [{ base64: await downscaleToBase64(file) }] };
        } catch {
          throw new SetupError("讀取照片失敗，換一張再試。");
        }
      }, null),
    [run],
  );

  /** 商品頁:目錄裡的一件商品,後端自己去解析它的圖與描述。 */
  const fromProduct = useCallback(
    (item: CatalogItem) =>
      run(async () => ({ productId: item.productId }), {
        productId: item.productId,
        name: item.name,
      }),
    [run],
  );

  return { fromGarmentPhoto, fromProduct };
}
