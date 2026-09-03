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

class SetupError extends Error {}

const SETUP_FALLBACK = "讀取試穿形象失敗，請稍後再試。";

/** The single entry point for every try-on: those started from the product page
 * and from home all land in the same gallery. */
export function useTryonCoordinator() {
  const { state, dispatch } = useGallery();
  const navigate = useNavigate();

  const run = useCallback(
    async (buildGarment: () => Promise<Garment>, product: TryonProduct | null) => {
      // The placeholder page and the navigation come before any work: preparing a
      // try-on reads a file, downscales it, and with a chosen avatar fetches that
      // image in full. All of it happens after the button is pressed, so doing it
      // first would freeze the screen until it finished — the animation goes up
      // first and the work runs underneath it.
      const id = newId();
      dispatch({ type: "addPending", id, product });
      navigate("/home");

      let garment: Garment;
      let avatarBase64: string | undefined;
      try {
        garment = await buildGarment();

        // The avatar image has to be read back as bytes, which depends on R2
        // allowing CORS from the LIFF origin. Treating a failed read as "no
        // avatar chosen" would be wrong — it would generate against the profile
        // photo, which is not what the user asked for, so stop and say so.
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
        // `fail` rather than remove + notify: the user may already have cancelled
        // the generation, after which this request's fate should not bother them
        // — the reducer decides whether that page is still there.
        dispatch({ type: "fail", id, message: tryonFailureMessage(err) });
      }
    },
    [state, dispatch, navigate],
  );

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
