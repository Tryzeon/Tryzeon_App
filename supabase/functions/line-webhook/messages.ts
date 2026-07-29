import { LIMITS } from "../_shared/chat/index.ts";
import {
  clampProductName,
  type LineProduct,
  productInfoContents,
  purchaseAction,
} from "./product-card.ts";
import { CARD_COLOR, primaryButton } from "./card-kit.ts";
import {
  cameraRollChip,
  messageChip,
  postbackChip,
  uriChip,
  withQuickReply,
} from "./quick-reply.ts";
import { tryonPostbackData } from "./postback.ts";

export function processingMessage(): object {
  return { type: "text", text: "收到，正在試穿，請稍等！" };
}

/** liff-web's avatar screen. Its catalog is the app root — see `liff-web/src/router.tsx`. */
const LIFF_ONBOARD_PATH = "/onboard";

/**
 * The gate every try-on hits without a model photo.
 *
 * Both destinations come from one base URL, because both screens are ours:
 * liff-web serves the catalog at `/` and the avatar upload at
 * {@link LIFF_ONBOARD_PATH}. The catalog chip matters more than it looks —
 * uploading a photo of yourself is a real ask, and someone not ready for it can
 * still go see what there is to try on rather than leaving.
 */
export function onboardingMessage(liffUrl: string): object {
  return withQuickReply({
    type: "template",
    altText: "先建立你的 model 照",
    template: {
      type: "buttons",
      text: "想要試穿嗎？先花 3 秒上傳你的 model 照",
      actions: [{
        type: "uri",
        label: "上傳我的 model 照",
        uri: `${liffUrl}${LIFF_ONBOARD_PATH}`,
      }],
    },
  }, [
    uriChip("先逛逛商品", liffUrl),
    messageChip("這是什麼服務", "你是誰，你能幫我做什麼"),
  ]);
}

export function resultMessage(imageUrl: string): object {
  // NOTE: LINE recommends previewImageUrl <= 1MB. v1 reuses the full URL for
  // both; if LINE rejects large previews, generate/upload a downscaled preview.
  return withQuickReply({
    type: "image",
    originalContentUrl: imageUrl,
    previewImageUrl: imageUrl,
  }, [
    cameraRollChip("再試一件"),
    messageChip("找類似的商品", "幫我找類似剛剛那件的商品"),
    messageChip("幫我配這件", "幫我搭配剛剛那件"),
  ]);
}

export function productProcessingMessage(name: string): object {
  return { type: "text", text: `收到，正在幫你試穿「${name}」，請稍等！` };
}

export function productUnavailableMessage(liffUrl: string): object {
  return withQuickReply({ type: "text", text: "這件商品已經下架了，換一件再試試。" }, [
    messageChip("有什麼推薦", "有什麼推薦的商品"),
    uriChip("逛逛其他商品", liffUrl),
    cameraRollChip("試我自己的衣服"),
  ]);
}

/**
 * A try-on of a catalog product, as a card.
 *
 * A bare image would not say which of the carousel's products this was, nor
 * offer a way to buy it — so the product travels back out with its own result.
 * The hero is `9:16` because that is what generation produces (see
 * `_shared/tryon/vertex.ts`), so `cover` crops nothing.
 */
export function productResultMessage(
  imageUrl: string,
  product: LineProduct,
): object {
  const purchase = purchaseAction(product);
  return withQuickReply({
    type: "flex",
    // Clamped: `altText` fails the whole send past 400 characters, and a
    // product name has no length constraint.
    altText: `為你試穿了 ${clampProductName(product.name)}`,
    contents: {
      type: "bubble",
      hero: {
        type: "image",
        url: imageUrl,
        size: "full",
        aspectRatio: "9:16",
        aspectMode: "cover",
        action: { type: "uri", label: "看大圖", uri: imageUrl },
      },
      body: {
        type: "box",
        layout: "vertical",
        paddingAll: "16px",
        contents: productInfoContents(product),
      },
      // Buying is this card's only action, so it takes the primary style here
      // rather than the outlined one it wears on a product card.
      ...(purchase
        ? {
          footer: {
            type: "box",
            layout: "vertical",
            paddingAll: "16px",
            paddingTop: "0px",
            contents: [primaryButton("前往購買", purchase)],
          },
        }
        : {}),
      styles: {
        body: { backgroundColor: CARD_COLOR.surface },
        footer: { backgroundColor: CARD_COLOR.surface },
      },
    },
  }, [
    messageChip("找類似的", "有沒有類似的其他商品"),
    messageChip("幫我配這件", "幫我搭配剛剛試穿的那件"),
    cameraRollChip("試我自己的衣服"),
  ]);
}

/*
 * Failure text, one table per feature.
 *
 * The kinds a feature can fail with are its own, and so is the wording: both
 * tables have a `quota` arm, but "今日試穿次數已用完" is not what a user who
 * asked for a shirt should read. One shared table would have to name the arms
 * `tryon_quota` / `chat_quota` to keep them apart, which is the same split
 * spelled worse.
 */

const TRYON_ERROR_TEXT = {
  quota: "今日試穿次數已用完，明天再回來試。",
  generation: "這件沒能生成，請換一件或再試一次看看！",
  download: "這張圖讀取失敗，麻煩再傳一次。",
  unknown: "出了點狀況，請稍後再試。",
} as const;

export function tryonErrorMessage(kind: keyof typeof TRYON_ERROR_TEXT): object {
  const message = { type: "text", text: TRYON_ERROR_TEXT[kind] };
  switch (kind) {
    case "quota":
      return withQuickReply(message, [messageChip("找衣服看看", "有什麼推薦的商品")]);
    case "generation":
      return withQuickReply(message, [
        cameraRollChip("換一張再試"),
        messageChip("找類似的商品", "幫我找類似剛剛那件的商品"),
      ]);
    case "download":
      return withQuickReply(message, [cameraRollChip("重新傳一張")]);
    case "unknown":
      return withQuickReply(message, [cameraRollChip("再試一次")]);
  }
}

/**
 * The product-path counterpart of {@link tryonErrorMessage}.
 *
 * Narrower kind union: there is no download step for a catalog product, so
 * `"download"` cannot happen here. And unlike the photo path, `tryonNote` is
 * never written on failure — so the retry can only offer actions that need no
 * transcript, which is why it carries the product id itself rather than a
 * `message` chip asking for "類似的".
 */
export function productTryonErrorMessage(
  kind: "quota" | "generation" | "unknown",
  product: LineProduct,
  liffUrl: string,
): object {
  const message = { type: "text", text: TRYON_ERROR_TEXT[kind] };
  const retry = postbackChip(
    "再試一次",
    tryonPostbackData(product.id),
    `試穿「${clampProductName(product.name)}」`,
  );

  switch (kind) {
    case "quota":
      return withQuickReply(message, [messageChip("找衣服看看", "有什麼推薦的商品")]);
    case "generation":
      return withQuickReply(message, [retry, uriChip("換一件試試", liffUrl)]);
    case "unknown":
      return withQuickReply(message, [retry]);
  }
}

const CHAT_ERROR_TEXT = {
  quota: "今日對話次數已用完，明天再回來找我。",
  too_long: `訊息太長了，請縮短到 ${LIMITS.MAX_TEXT_LENGTH} 字以內再傳一次。`,
  unknown: "出了點狀況，請稍後再試。",
} as const;

export type ChatErrorKind = keyof typeof CHAT_ERROR_TEXT;

export function chatErrorMessage(kind: ChatErrorKind): object {
  const message = { type: "text", text: CHAT_ERROR_TEXT[kind] };
  switch (kind) {
    case "quota":
      return withQuickReply(message, [cameraRollChip("直接傳衣服試穿")]);
    case "too_long":
      return withQuickReply(message, [messageChip("有什麼推薦", "有什麼推薦的商品")]);
    case "unknown":
      return withQuickReply(message, [
        messageChip("有什麼推薦", "有什麼推薦的商品嗎"),
        cameraRollChip("傳衣服照試穿"),
      ]);
  }
}

export function hintMessage(): object {
  return withQuickReply({
    type: "text",
    text: "傳一張衣服的照片給我，我就幫你試穿；想找衣服的話，直接用文字告訴我你想要什麼。",
  }, [
    cameraRollChip("選一張衣服照"),
    messageChip("幫我配一套", "幫我配一套適合我的穿搭"),
    messageChip("有什麼推薦", "有什麼推薦的商品嗎"),
  ]);
}
