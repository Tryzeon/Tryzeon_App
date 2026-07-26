import { LIMITS } from "../_shared/chat/index.ts";

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
