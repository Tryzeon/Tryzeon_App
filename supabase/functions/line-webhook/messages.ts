import { LIMITS } from "../_shared/chat/index.ts";
import {
  clampProductName,
  type LineProduct,
  productInfoContents,
  purchaseAction,
} from "./product-card.ts";
import { CARD_COLOR, primaryButton } from "./card-kit.ts";

export function processingMessage(): object {
  return { type: "text", text: "收到，正在試穿，請稍等！" };
}

export function onboardingMessage(liffUrl: string): object {
  return {
    type: "template",
    altText: "先建立你的 model 照",
    template: {
      type: "buttons",
      text: "想要試穿嗎？先花 3 秒上傳你的 model 照",
      actions: [{ type: "uri", label: "上傳我的 model 照", uri: liffUrl }],
    },
  };
}

export function resultMessage(imageUrl: string): object {
  // NOTE: LINE recommends previewImageUrl <= 1MB. v1 reuses the full URL for
  // both; if LINE rejects large previews, generate/upload a downscaled preview.
  return {
    type: "image",
    originalContentUrl: imageUrl,
    previewImageUrl: imageUrl,
  };
}

export function productProcessingMessage(name: string): object {
  return { type: "text", text: `收到，正在幫你試穿「${name}」，請稍等！` };
}

export function productUnavailableMessage(): object {
  return { type: "text", text: "這件商品已經下架了，換一件再試試。" };
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
  return {
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
  };
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
  generation: "這張沒能生成，換一張更清楚的衣服圖再試。",
  download: "這張圖讀取失敗，麻煩再傳一次。",
  unknown: "出了點狀況，請稍後再試。",
} as const;

export function tryonErrorMessage(kind: keyof typeof TRYON_ERROR_TEXT): object {
  return { type: "text", text: TRYON_ERROR_TEXT[kind] };
}

const CHAT_ERROR_TEXT = {
  quota: "今日對話次數已用完，明天再回來找我。",
  too_long: `訊息太長了，請縮短到 ${LIMITS.MAX_TEXT_LENGTH} 字以內再傳一次。`,
  unknown: "出了點狀況，請稍後再試。",
} as const;

export type ChatErrorKind = keyof typeof CHAT_ERROR_TEXT;

export function chatErrorMessage(kind: ChatErrorKind): object {
  return { type: "text", text: CHAT_ERROR_TEXT[kind] };
}

export function hintMessage(): object {
  return {
    type: "text",
    text: "傳一張衣服的照片給我，我就幫你試穿；想找衣服的話，直接用文字告訴我你想要什麼。",
  };
}
