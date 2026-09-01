/**
 * 自訂試穿風格:場景與穿搭細節,兩段會原樣送進 `tryon` 的 prompt 欄位。
 *
 * 存在 localStorage,因為 app 的對應設定也是存在裝置上(SharedPreferences)而不是
 * 伺服器 —— 兩邊各自記各自的,不會互相覆蓋。webview 可能整個禁掉 storage,所以
 * 讀寫都不能讓例外逃出去:風格設定失敗只該讓風格回到預設,不該讓首頁開不起來。
 */
const STORAGE_KEY = "tryzeon.tryonPromptConfig";

export interface PromptConfig {
  scenePrompt: string;
  stylingPrompt: string;
}

export const EMPTY_PROMPT_CONFIG: PromptConfig = { scenePrompt: "", stylingPrompt: "" };

/** 和 app 的 `TryonStyleSheet` 同一組預設值。 */
export const STYLING_PRESETS = ["紮進褲頭", "衣襬放下", "袖子捲起"];
export const SCENE_PRESETS = ["純白攝影棚", "都會街頭", "柔焦自然風景"];

function readString(source: Record<string, unknown>, key: string): string {
  const value = source[key];
  return typeof value === "string" ? value : "";
}

export function loadPromptConfig(): PromptConfig {
  let raw: string | null;
  try {
    raw = localStorage.getItem(STORAGE_KEY);
  } catch {
    return EMPTY_PROMPT_CONFIG;
  }
  if (raw === null) return EMPTY_PROMPT_CONFIG;

  try {
    const parsed: unknown = JSON.parse(raw);
    if (typeof parsed !== "object" || parsed === null) return EMPTY_PROMPT_CONFIG;
    const source = parsed as Record<string, unknown>;
    return {
      scenePrompt: readString(source, "scenePrompt"),
      stylingPrompt: readString(source, "stylingPrompt"),
    };
  } catch {
    return EMPTY_PROMPT_CONFIG;
  }
}

export function savePromptConfig(config: PromptConfig): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(normalizePromptConfig(config)));
  } catch {
    // 存不起來就只有這一次生效,沒有其他補救,也不值得打斷使用者。
  }
}

/** 去掉前後空白;空字串代表「不指定」,送出時整個欄位會被省略。 */
export function normalizePromptConfig(config: PromptConfig): PromptConfig {
  return {
    scenePrompt: config.scenePrompt.trim(),
    stylingPrompt: config.stylingPrompt.trim(),
  };
}
