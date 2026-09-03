/**
 * Stored in localStorage because the app's counterpart also lives on the device
 * (SharedPreferences) rather than on the server — each side remembers its own
 * and neither overwrites the other. A webview may disable storage entirely, so
 * neither read nor write may let an exception escape: a failed style setting
 * should fall back to the defaults, not stop the home page from opening.
 */
const STORAGE_KEY = "tryzeon.tryonPromptConfig";

export interface PromptConfig {
  scenePrompt: string;
  stylingPrompt: string;
}

export const EMPTY_PROMPT_CONFIG: PromptConfig = { scenePrompt: "", stylingPrompt: "" };

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
    // If it cannot be stored the setting just applies to this session; there is
    // no other remedy, and none worth interrupting the user for.
  }
}

export function normalizePromptConfig(config: PromptConfig): PromptConfig {
  return {
    scenePrompt: config.scenePrompt.trim(),
    stylingPrompt: config.stylingPrompt.trim(),
  };
}
