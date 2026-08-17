/**
 * Try-on prompt construction — pure, provider-agnostic, and the product's
 * actual domain logic. Kept apart from `vertex.ts` (which only knows how to
 * talk to Vertex AI) so the wording can be read, diffed, and unit-tested
 * without touching a network client.
 */

export const SYSTEM_INSTRUCTION =
  `You are a photorealistic virtual try-on image editor. Preserve the target person's identity and follow only the garment-replacement and optional scene-edit instructions explicitly authorized by the task. Do not alter anything else.`;

function buildGarmentManifest(garmentGroups: string[][]): string {
  const lines: string[] = [];
  let cursor = 2; // image 1 is the person
  garmentGroups.forEach((group, i) => {
    const start = cursor;
    const end = cursor + group.length - 1;
    const range = group.length === 1
      ? `image ${start}`
      : `images ${start}-${end}`;
    lines.push(`   - Garment ${i + 1}: ${range}`);
    cursor = end + 1;
  });
  return lines.join("\n");
}

function buildGarmentDetailsSection(
  garmentDetails?: (string | undefined)[],
): string {
  if (!garmentDetails) return "";
  const lines: string[] = [];
  garmentDetails.forEach((detail, i) => {
    const text = detail?.trim();
    if (text) lines.push(`   - Garment ${i + 1}: ${text}`);
  });
  if (lines.length === 0) return "";

  return `
GARMENT DETAILS — MATERIAL NOTES
The store's own notes on each garment's material, cut, elasticity, and thickness. Use them to render how the fabric behaves: how it drapes and how much it stretches.
${lines.join("\n")}`;
}

/**
 * Kept apart from `buildGarmentDetailsSection` because the two have different
 * sources: details describe the garment as the store published it, these lines
 * are computed against one wearer's measurements.
 *
 * The wearer stays a hard invariant — without an explicit prohibition the model
 * will happily resize the person to match a number.
 */
function buildGarmentFitSection(garmentFits?: (string | undefined)[]): string {
  if (!garmentFits) return "";
  const lines: string[] = [];
  garmentFits.forEach((fit, i) => {
    const text = fit?.trim();
    if (text) lines.push(`   - Garment ${i + 1}, ${text}`);
  });
  if (lines.length === 0) return "";

  return `
GARMENT FIT — HOW THIS SIZE SITS ON THIS BODY
The published measurements of the size being worn, next to the wearer's own measurements. Use them to judge how tightly the garment sits on this person.
- Negative ease means this body fills the garment past its measured size, so the fabric stretches and pulls taut, with visible tension lines. How far it can stretch is governed by the elasticity noted in GARMENT DETAILS.
- NEVER resize, reshape, or re-proportion the person to match these numbers — the garment changes, the body does not.
${lines.join("\n")}`;
}

/**
 * Optional inputs to {@link buildTaskPrompt}, named rather than positional:
 * `garmentDetails` and `garmentFits` are both `(string | undefined)[]`, so two
 * positional parameters of the same shape would let a caller transpose them
 * and still type-check.
 *
 * `types.ts`'s `ImageGenerator` and `vertex.ts`'s `generateTryonImage` both
 * take THIS type rather than a copy of its shape. That matters more than it
 * looks: every field here is optional, so two independent declarations stay
 * mutually assignable even after one of them renames a field — the compiler
 * accepts the drift, and the renamed input is silently dropped on its way to
 * the prompt.
 */
export interface TaskPromptOptions {
  garmentDetails?: (string | undefined)[];
  scenePrompt?: string;
  garmentFits?: (string | undefined)[];
}

export function buildTaskPrompt(
  garmentGroups: string[][],
  opts: TaskPromptOptions = {},
): string {
  const { garmentDetails, scenePrompt, garmentFits } = opts;
  const totalGarmentImages = garmentGroups.reduce((a, g) => a + g.length, 0);
  let prompt = `You will receive ${
    totalGarmentImages + 1
  } images after this message:
1) FIRST image: the PERSON photo — this is the target person.
2) ALL SUBSEQUENT IMAGES are grouped by garment. Each group is the SAME garment from different angles — use a group's images together to understand that garment's 3D structure, front/back designs, and patterns. The garment groups are:
${buildGarmentManifest(garmentGroups)}
First classify each garment's category (top / bottom / full-body / outerwear) using the rules below, then apply ALL garments to the person simultaneously.

HARD INVARIANTS — DO NOT CHANGE THESE
- Person's face, expression, hair (color, length, style), skin tone, age, body shape, pose, camera angle, and framing must be identical to the first image.
- Do not add, remove, or alter tattoos, jewelry, accessories, hands, or fingers.
- Do not change the background from the first image${
    scenePrompt ? " (unless overridden by SCENE CONTEXT below)" : ""
  }.

GARMENT SCOPE — THE CATEGORIES
- TOP: shirt, blouse, t-shirt, tank top, sweater, hoodie (covers upper body only)
- BOTTOM: pants, jeans, shorts, skirt, leggings (covers lower body only)
- FULL-BODY: dress, jumpsuit, overall, robe, gown (covers both upper and lower body)
- OUTERWEAR: jacket, coat, cardigan, blazer, vest (worn OVER existing clothing)

REPLACEMENT SCOPE RULES — STRICT
- Replace ONLY the original clothing in the SAME CATEGORY as the reference. Everything else on the person — including footwear — MUST be preserved EXACTLY from the first image: same color, pattern, fabric, length, fit, and styling (e.g., tucked/untucked). Never redesign or recolor it — e.g., do NOT touch the original pants when the reference is a top.
- FULL-BODY reference → replaces both upper and lower body (the dress/jumpsuit covers everything).
- OUTERWEAR reference → add or swap the outer layer ONLY. KEEP the original inner top and bottom unchanged and visible where appropriate.
- If the original lower garment is partially occluded in the first image (e.g., by the original top), reconstruct it faithfully based on what IS visible — same color, same type — do NOT invent a different style.

GARMENT TRANSFER — MUST MATCH THE REFERENCE IMAGES EXACTLY
- Copy the garment precisely: cut and construction — neckline shape, sleeve length, hem length, seams, stitching, closures (buttons/zippers), pockets — and any logos or text.
- Preserve print/pattern scale, placement, and color exactly — do not simplify or genericize.
- Maintain material properties: sheen, thickness, texture, translucency.
- Fit the garment naturally to this person's body: realistic drape, wrinkles, and tension points for their specific body and pose.

CRITICAL: ORIGINAL CLOTHING REMOVAL
- Within the replaced category, COMPLETELY REMOVE all traces of the person's original clothing from the first image.
- Wherever the new garment covers less than the original (shorter sleeves, lower or wider neckline, shorter hem), whatever lies underneath — the person's bare skin, or a preserved out-of-scope garment — MUST be fully visible and natural. NO remnants of the original sleeves, collar, or hem.
- The boundary between the new garment and exposed skin (or preserved original clothing) must be clean, natural, and seamless, with correct skin texture.

SOURCE IMAGE ISOLATION
- Treat the garment reference images as product references ONLY.
- Ignore any model, mannequin, body, background, props, or lighting visible in the garment photos.
- This includes how the garment FITS in those photos. A reference body is not this person's body, so do NOT carry over how loosely or tightly it sat there.
- Extract and transfer ONLY the garment itself.

LIGHTING & REALISM
- Match lighting direction, intensity, and color temperature from the person photo.
- Generate realistic shadows where fabric contacts the body.
- Natural skin rendering, no artifacts, no warping, no halos, no double edges.

OUTPUT
- Return ONE photorealistic image with sharp garment detail, accurate color reproduction, and fashion photography quality.`;

  prompt += buildGarmentDetailsSection(garmentDetails);
  prompt += buildGarmentFitSection(garmentFits);

  if (scenePrompt) {
    prompt += `

SCENE CONTEXT — BACKGROUND ONLY
Place the person in this scene: ${scenePrompt}
- Change ONLY the background and adjust lighting to match the new environment.
- The person and the garment stay exactly as specified above.`;
  }

  return prompt;
}

const DEFAULT_VIDEO_PROMPT =
  "The person is wearing the new outfit and turning slightly to show the fit of the clothing. Natural movement, professional fashion video style.";

export function buildVideoPrompt(transitionPrompt?: string): string {
  if (!transitionPrompt) {
    return DEFAULT_VIDEO_PROMPT;
  }

  let prompt =
    "The person is wearing the new outfit and showing the fit of the clothing.";
  prompt += ` Camera and transition style: ${transitionPrompt}.`;
  prompt += " Natural movement, professional fashion video style.";

  return prompt;
}
