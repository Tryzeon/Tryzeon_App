import { jsonError } from "../_shared/http.ts";

/// Garment flat measurements — must stay in sync with GarmentMeasurementType
/// in lib/feature/common/product_size/domain/entities/.
export const MEASUREMENT_KEYS = [
  "shoulder_width", "chest_circumference", "sleeve_length", "waist_circumference",
  "hip_circumference", "length",
] as const;

export const UNIT_VALUES = ["centimeter", "cun", "inch"] as const;

export const TO_CM_FACTOR: Record<string, number> = {
  centimeter: 1,
  cun: 3.03,
  inch: 2.54,
};

const MAX_AUDIO_BASE64_LENGTH = 10 * 1024 * 1024; // ~7.5MB binary, well above 60s AAC
const SUPPORTED_MIME = new Set([
  "audio/mp4", "audio/aac", "audio/mpeg", "audio/mp3", "audio/wav", "audio/x-m4a",
]);
const MAX_CM = 300;

export function buildPrompt(): string {
  return [
    "你是服裝尺寸資料整理助手。輸入是一段店家的口語錄音（主要為繁體中文，尺寸代號可能夾雜英文如 M、L、US 10）。",
    "請從語音中萃取每一個尺寸與其量測值，輸出 JSON。",
    "規則：",
    "1. 忽略口頭禪、語助詞、重複與與尺寸無關的閒聊，只保留尺寸資訊（去贅字）。",
    "2. 量測欄位只允許：shoulder_width(肩寬)、chest_circumference(胸圍)、sleeve_length(袖長)、waist_circumference(腰圍)、hip_circumference(臀圍)、length(長度)。沒講到的欄位不要輸出。",
    "2-0. length 是衣服本身的長度，衣長、褲長、裙長、洋裝長一律填 length。",
    "2-1. 這是「衣服」的尺寸，不是人體的尺寸。身高不是衣服的尺寸，絕對不要輸出。",
    "2-2. 胸圍、腰圍、臀圍是該部位一圈的長度。店家若說的是「平放衣服量的胸寬／腰寬／臀寬」（半圈），請乘以 2 後填入對應的圍度欄位。",
    "3. 每個量測輸出 { value, unit }。value 為數字。",
    "4. unit 依口語判斷：公分=centimeter、台寸/寸=cun、英吋/吋/inch=inch。若完全沒提單位，一律填 centimeter。",
    "5. name 原樣保留尺寸代號（例 M、L、US 10）；若聽不出名稱填空字串。",
    "6. 若聽不出任何尺寸，sizes 回空陣列。",
  ].join("\n");
}

export function buildSchema(): Record<string, unknown> {
  const measurement = {
    type: "object",
    properties: {
      value: { type: "number" },
      unit: { type: "string", enum: [...UNIT_VALUES] },
    },
    required: ["value", "unit"],
  };
  const measurementProps: Record<string, unknown> = {};
  for (const key of MEASUREMENT_KEYS) measurementProps[key] = measurement;
  return {
    type: "object",
    properties: {
      sizes: {
        type: "array",
        items: {
          type: "object",
          properties: {
            name: { type: "string" },
            measurements: { type: "object", properties: measurementProps },
          },
          required: ["name", "measurements"],
        },
      },
    },
    required: ["sizes"],
  };
}

export function validateAudio(
  audioBase64: unknown,
  mimeType: unknown,
): { ok: true; base64: string; mimeType: string } | { ok: false; response: Response } {
  if (typeof audioBase64 !== "string" || audioBase64.length < 16) {
    return { ok: false, response: jsonError("Missing or invalid audio", "BAD_REQUEST", 400) };
  }
  if (audioBase64.length > MAX_AUDIO_BASE64_LENGTH) {
    return { ok: false, response: jsonError("Audio payload too large", "PAYLOAD_TOO_LARGE", 413) };
  }
  const mime = typeof mimeType === "string" ? mimeType : "";
  if (!SUPPORTED_MIME.has(mime)) {
    return { ok: false, response: jsonError("Unsupported audio mime type", "BAD_REQUEST", 400) };
  }
  return { ok: true, base64: audioBase64, mimeType: mime };
}

function toNumber(v: unknown): number | null {
  return typeof v === "number" && Number.isFinite(v) ? v : null;
}

export function normalizeParsedSizes(
  raw: unknown,
): Array<{ name: string; measurements: Record<string, { value: number; unit: string }> }> {
  const sizes = (raw as { sizes?: unknown })?.sizes;
  if (!Array.isArray(sizes)) return [];
  const out: Array<{ name: string; measurements: Record<string, { value: number; unit: string }> }> = [];
  for (const s of sizes) {
    if (s === null || typeof s !== "object") continue;
    const nameRaw = (s as Record<string, unknown>).name;
    const name = typeof nameRaw === "string" ? nameRaw.slice(0, 20) : "";
    const measurements: Record<string, { value: number; unit: string }> = {};
    const mRaw = (s as Record<string, unknown>).measurements;
    if (mRaw && typeof mRaw === "object") {
      for (const key of MEASUREMENT_KEYS) {
        const m = (mRaw as Record<string, unknown>)[key];
        if (!m || typeof m !== "object") continue;
        const value = toNumber((m as Record<string, unknown>).value);
        const unitRaw = (m as Record<string, unknown>).unit;
        const unit = (UNIT_VALUES as readonly string[]).includes(unitRaw as string)
          ? (unitRaw as string)
          : "centimeter";
        if (value === null) continue;
        const cm = value * TO_CM_FACTOR[unit];
        if (cm <= 0 || cm > MAX_CM) continue;
        measurements[key] = { value, unit };
      }
    }
    out.push({ name, measurements });
  }
  return out;
}
