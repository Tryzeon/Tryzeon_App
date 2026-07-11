export function processingMessage(): object {
  return { type: "text", text: "👗 收到！試穿中，大約 30 秒…" };
}

export function onboardingMessage(liffUrl: string): object {
  return {
    type: "template",
    altText: "先建立你的 model 照",
    template: {
      type: "buttons",
      text: "先花 30 秒建立你的 model：上傳一張清楚全身照，之後試穿都用它。",
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
    quickReply: {
      items: [
        {
          type: "action",
          action: { type: "message", label: "再試一件", text: "再傳一張衣服圖給我" },
        },
      ],
    },
  };
}

const ERROR_TEXT: Record<string, string> = {
  quota: "今日試穿次數已用完，明天再回來試。",
  generation: "這張沒能生成，換一張更清楚的衣服圖再試。",
  download: "這張圖讀取失敗，麻煩再傳一次。",
  unknown: "出了點狀況，請稍後再試。",
};

export function errorMessage(
  kind: "quota" | "generation" | "download" | "unknown",
): object {
  return { type: "text", text: ERROR_TEXT[kind] };
}

export function hintMessage(): object {
  return { type: "text", text: "傳一張衣服的照片給我，我就幫你試穿 👗" };
}
