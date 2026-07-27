/**
 * The prompt, the response schema, and the sanitiser that turns whatever the
 * model said into the response body — the whole contract with the model, kept
 * apart from the HTTP shell in `index.ts` so it can be tested without a network.
 *
 * The three belong together: structured output types every field as a string,
 * so the model has no way to answer "I can't tell" with JSON null. `unknown` is
 * the agreed spelling instead — the prompt teaches it, the schema permits it,
 * and the sanitiser strips it back out. Change one of the three and the other
 * two stop making sense.
 */

/**
 * The controlled vocabularies. Values stay in English because that is what the
 * app's Dart enums parse; the Chinese labels a shopper sees are applied at
 * display time in `product_attributes_extensions.dart` and belong only there.
 */
const STYLE_VALUES = [
  "japanese", "korean", "western", "british", "chinese",
  "minimalist", "casual", "sporty", "lazy", "streetwear",
  "business", "preppy", "functional", "vintage", "artsy",
  "literary", "elegant", "mature", "neutral", "spicy", "sweet",
];
const GENDER_VALUES = ["male", "female", "unisex"];
const SEASON_VALUES = ["spring", "summer", "autumn", "winter"];
const THICKNESS_VALUES = ["low", "medium", "high"];
const ELASTICITY_VALUES = ["none", "low", "medium", "high"];
const FIT_VALUES = ["slim", "regular", "loose", "oversize"];
// The exception, and mirrors `kMaterialPresets` in the app: `products.material`
// is free text, so these Chinese strings are the stored value and the displayed
// value at once. There is no enum behind them and nothing to translate later.
const MATERIAL_VALUES = [
  "棉", "麻", "羊毛", "蠶絲", "聚酯纖維",
  "尼龍", "嫘縈", "天絲", "萊卡", "混紡",
];

/** A vocabulary spelled out for the model: `slim / regular / loose / …`. */
const list = (vocab: string[]): string => vocab.join(" / ");

/** The sentinel every field carries for "the photo doesn't tell me". */
const UNKNOWN = "unknown";

const MAX_NAME_LENGTH = 20;
const MAX_STYLES = 3;

const str = (v: unknown): string | null =>
  typeof v === "string" && v.trim().length > 0 ? v.trim() : null;

/**
 * Like {@link str}, but rejects the `unknown` sentinel. `name` is the one field
 * the schema can't restrict to an enum — any string validates there — so its
 * sentinel is only enforceable on the way back.
 */
const freeText = (v: unknown): string | null => {
  const s = str(v);
  return s === null || s.toLowerCase() === UNKNOWN ? null : s;
};

const inList = (v: unknown, list: string[]): string | null =>
  typeof v === "string" && list.includes(v) ? v : null;

const filterList = (v: unknown, list: string[], cap: number): string[] =>
  Array.isArray(v)
    ? [...new Set(v.filter((x): x is string => typeof x === "string" && list.includes(x)))]
      .slice(0, cap)
    : [];

export function buildPrompt(categoryNames: string[]): string {
  return `You label products for an online clothing store. Analyse the product photo and return JSON.
Every field is required. When the photo does not tell you, answer with the string "${UNKNOWN}" (an empty array for array fields) — never the word "null".
- name: a concise product name in Traditional Chinese (colour + fit + material + garment type, e.g. 「白色寬鬆棉質襯衫」), at most ${MAX_NAME_LENGTH} characters; ${UNKNOWN} if you cannot tell.
- category: exactly one of the following names, or ${UNKNOWN} if you cannot tell: ${
    list(categoryNames)
  }
- gender: ${list(GENDER_VALUES)}; ${UNKNOWN} if you cannot tell.
- styles: at most ${MAX_STYLES} of: ${list(STYLE_VALUES)}.
- seasons: the seasons the garment suits, any number of: ${list(SEASON_VALUES)}.
- material: exactly one of the following Traditional Chinese terms, or ${UNKNOWN} if you cannot tell: ${
    list(MATERIAL_VALUES)
  }
- fit: ${list(FIT_VALUES)}; ${UNKNOWN} if you cannot tell.
- thickness: how thick the fabric is — ${list(THICKNESS_VALUES)}; ${UNKNOWN} if you cannot tell.
- elasticity: how stretchy the fabric is — ${
    list(ELASTICITY_VALUES)
  }; ${UNKNOWN} if you cannot tell.
Return JSON only, with no surrounding text.`;
}

export function buildSchema(categoryNames: string[]): Record<string, unknown> {
  return {
    type: "object",
    properties: {
      name: { type: "string" },
      category: { type: "string", enum: [...categoryNames, UNKNOWN] },
      gender: { type: "string", enum: [...GENDER_VALUES, UNKNOWN] },
      styles: { type: "array", items: { type: "string", enum: STYLE_VALUES } },
      seasons: { type: "array", items: { type: "string", enum: SEASON_VALUES } },
      material: { type: "string", enum: [...MATERIAL_VALUES, UNKNOWN] },
      fit: { type: "string", enum: [...FIT_VALUES, UNKNOWN] },
      thickness: { type: "string", enum: [...THICKNESS_VALUES, UNKNOWN] },
      elasticity: { type: "string", enum: [...ELASTICITY_VALUES, UNKNOWN] },
    },
    // Every field is required. An omitted field and an `unknown` one mean the
    // same thing to the caller, so allowing both only gives the model a third
    // option — writing the *word* "null" into a field typed as a string.
    required: [
      "name", "category", "gender", "styles",
      "seasons", "material", "fit", "thickness", "elasticity",
    ],
  };
}

export interface ProductAnalysisResponse {
  name: string | null;
  categoryId: string | null;
  gender: string | null;
  styles: string[];
  seasons: string[];
  material: string | null;
  fit: string | null;
  thickness: string | null;
  elasticity: string | null;
}

/**
 * Narrows the model's answer to the response body, dropping anything outside
 * the agreed vocabulary — sentinels, hallucinated enum members, over-long
 * names, categories that don't exist. Every unusable field comes back `null`,
 * which the app reads as "leave this input alone".
 */
export function toResponse(
  parsed: Record<string, unknown>,
  idByName: Map<string, string>,
): ProductAnalysisResponse {
  const categoryName = str(parsed.category);
  const name = freeText(parsed.name);

  return {
    name: name ? name.slice(0, MAX_NAME_LENGTH) : null,
    categoryId: categoryName ? (idByName.get(categoryName) ?? null) : null,
    gender: inList(parsed.gender, GENDER_VALUES),
    styles: filterList(parsed.styles, STYLE_VALUES, MAX_STYLES),
    seasons: filterList(parsed.seasons, SEASON_VALUES, SEASON_VALUES.length),
    material: inList(parsed.material, MATERIAL_VALUES),
    fit: inList(parsed.fit, FIT_VALUES),
    thickness: inList(parsed.thickness, THICKNESS_VALUES),
    elasticity: inList(parsed.elasticity, ELASTICITY_VALUES),
  };
}
