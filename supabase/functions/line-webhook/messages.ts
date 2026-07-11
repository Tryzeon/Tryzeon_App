export function processingMessage(): object {
  return { type: "text", text: "正在試穿中，請稍等！" };
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
