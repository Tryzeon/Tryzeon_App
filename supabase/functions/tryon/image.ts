import { detectMimeType } from "../_shared/image-utils.ts";

const SYSTEM_INSTRUCTION =
  `You are a virtual try-on system. Your ONLY job is to dress the person in a new garment while preserving their identity exactly. 

CRITICAL: ALL generated images MUST be in PORTRAIT orientation with 9:16 aspect ratio (vertical format, taller than wide). NEVER generate square or landscape images.

CORE TASK: Replace ONLY the clothing categories shown in the reference garment(s). Think of this as a scoped two-step process:
1. IDENTIFY SCOPE: Determine which clothing category the reference covers (top / bottom / full-body / outerwear)
2. REMOVE & REPLACE: Within that scope ONLY, erase the original clothing and apply the new garment. Outside that scope, keep the person's original clothing EXACTLY as it appears in the first image.

You must NEVER alter the person's face, body, hair, or pose. You must NEVER invent garment details that aren't in the reference image. You must NEVER hallucinate or replace clothing in categories the reference does not cover (e.g., do NOT generate new pants when the reference only shows a top). You must NEVER leave remnants of the original clothing visible WITHIN the replaced scope.`;

function buildGarmentManifest(garmentImageCounts: number[]): string {
  const lines: string[] = [];
  let cursor = 2; // image 1 is the person
  garmentImageCounts.forEach((count, i) => {
    const start = cursor;
    const end = cursor + count - 1;
    const range = count === 1 ? `image ${start}` : `images ${start}-${end}`;
    lines.push(`   - Garment ${i + 1}: ${range}`);
    cursor = end + 1;
  });
  return lines.join("\n");
}

export function buildTaskPrompt(garmentImageCounts: number[], scenePrompt?: string): string {
  const totalClothes = garmentImageCounts.reduce((a, b) => a + b, 0);
  let prompt =
    `You will receive ${totalClothes + 1} images after this message:
1) FIRST image: the PERSON photo — this is the target person. Keep them exactly as-is.
2) ALL SUBSEQUENT IMAGES are grouped by garment. Each group is the SAME garment from different angles — use a group's images together to understand that garment's 3D structure, front/back designs, and patterns. The garment groups are:
${buildGarmentManifest(garmentImageCounts)}
First classify each garment's category (top / bottom / full-body / outerwear / footwear / accessory) using the rules below, then apply ALL garments to the person simultaneously. Each garment replaces ONLY its own category scope; any category not covered by ANY garment is a HARD INVARIANT — copy it pixel-faithfully from the person photo.

GOAL
Create a photorealistic photo of the person from the first image wearing the garment from the reference images.

HARD INVARIANTS — DO NOT CHANGE THESE
- Person's face, expression, hair (color, length, style), skin tone, age, and body shape must be identical to the first image.
- Pose, camera angle, and body proportions must match the first image exactly.
- Do not add, remove, or alter tattoos, jewelry, accessories, hands, or fingers.
- Do not change the background from the first image${scenePrompt ? " (unless overridden by SCENE CONTEXT below)" : ""}.

GARMENT SCOPE — IDENTIFY WHAT TO REPLACE (DO THIS FIRST)
Before generating, classify the reference garment(s) into ONE of these categories:
- TOP: shirt, blouse, t-shirt, tank top, sweater, hoodie (covers upper body only)
- BOTTOM: pants, jeans, shorts, skirt, leggings (covers lower body only)
- FULL-BODY: dress, jumpsuit, overall, robe, gown (covers both upper and lower body)
- OUTERWEAR: jacket, coat, cardigan, blazer, vest (worn OVER existing clothing)
- FOOTWEAR / ACCESSORY: shoes, hats, bags, etc.

REPLACEMENT SCOPE RULES — STRICT
- Replace ONLY the original clothing in the SAME CATEGORY as the reference. Everything else on the person MUST be preserved EXACTLY from the first image — same color, pattern, fabric, length, fit, and styling (e.g., tucked/untucked).
- TOP reference → swap the upper-body garment ONLY. KEEP the original pants/skirt/shorts/footwear unchanged.
- BOTTOM reference → swap the lower-body garment ONLY. KEEP the original top/outerwear/footwear unchanged.
- FULL-BODY reference → replaces both upper and lower body (the dress/jumpsuit covers everything).
- OUTERWEAR reference → add or swap the outer layer ONLY. KEEP the original inner top and bottom unchanged and visible where appropriate.
- If multiple references are provided, treat them as the SAME garment from different angles UNLESS they clearly show different categories (e.g., a top + a bottom set) — in which case replace each respective category.
- NEVER invent, generate, or substitute clothing in a category the reference does not show. If the reference is a top, do NOT change, redesign, or recolor the original pants. If the reference is pants, do NOT alter the original top.
- If the original lower garment is partially occluded in the first image (e.g., by the original top), reconstruct it faithfully based on what IS visible — same color, same type — do NOT invent a different style.

GARMENT TRANSFER — MUST MATCH THE REFERENCE IMAGES EXACTLY
- Copy the garment precisely: silhouette, neckline shape, sleeve length, hem length, seams, stitching, closures (buttons/zippers), pockets, and any logos or text.
- Preserve print/pattern scale, placement, and color exactly — do not simplify or genericize.
- Maintain material properties: sheen, thickness, texture, translucency.
- Fit the garment naturally to this person's body: realistic drape, wrinkles, and tension points for their specific pose.

CRITICAL: ORIGINAL CLOTHING REMOVAL — WITHIN REPLACEMENT SCOPE ONLY
Apply the rules below ONLY to the clothing category being replaced. Clothing in OTHER categories must remain UNTOUCHED.
- Within the replaced scope, COMPLETELY REMOVE all traces of the person's original clothing from the first image.
- If the new garment has shorter sleeves (e.g., sleeveless, short sleeves) than the original, the person's arms MUST be fully visible with natural skin — NO remnants of original sleeves.
- If the new garment has a different neckline (e.g., lower cut, wider), the person's chest/shoulders MUST show natural skin — NO remnants of original collar or fabric.
- If the new garment is shorter in length, the person's torso/legs MUST be visible with natural skin — NO remnants of original hem (unless the original lower garment must remain because it's outside scope — in that case, show the original lower garment cleanly tucked or layered).
- The boundary between the new garment and exposed skin (or preserved original clothing) must be clean, natural, and seamless with proper shadows and skin texture.

EXAMPLE SCENARIOS
- Reference: sleeveless top (TOP scope) → Replace ONLY the upper body. The person's original jeans/skirt/shorts MUST stay exactly as in the first image. Show bare arms with natural skin.
- Reference: a pair of pants (BOTTOM scope) → Replace ONLY the lower body. The person's original shirt/blouse MUST stay exactly as in the first image, including its color, pattern, and how it sits.
- Reference: a short dress (FULL-BODY scope) → Replace BOTH upper and lower body with the dress; show natural legs below the hem.
- Reference: a jacket (OUTERWEAR scope) → Add or swap the jacket only; the original inner top and original pants/skirt MUST remain visible and unchanged where the jacket does not cover them.
- The key principle: treat any clothing category NOT shown in the reference as a HARD INVARIANT — copy it pixel-faithfully from the first image.

SOURCE IMAGE ISOLATION
- Treat the garment reference images as product references ONLY.
- Ignore any model, mannequin, body, background, props, or lighting visible in the garment photos.
- Extract and transfer ONLY the garment itself.

LIGHTING & REALISM
- Match lighting direction, intensity, and color temperature from the person photo.
- Generate realistic shadows where fabric contacts the body.
- Soft diffused lighting, natural skin rendering, no artifacts, no warping, no halos, no double edges.

OUTPUT
- Return ONE image in PORTRAIT orientation with 9:16 aspect ratio (vertical/portrait format, NOT square or landscape).
- The image MUST be taller than it is wide (portrait orientation).
- Sharp garment detail, accurate color reproduction, fashion photography quality.`;

  if (scenePrompt) {
    prompt += `

SCENE CONTEXT — BACKGROUND ONLY
Place the person in this scene: ${scenePrompt}
- Change ONLY the background and adjust lighting to match the new environment.
- DO NOT change the person's identity, face, body, hair, pose, or any garment details.
- The garment must remain exactly as specified above.`;
  }

  return prompt;
}

/**
 * Generate a try-on image using Vertex AI Gemini image generation via REST API.
 * Returns the base64-encoded image or null if generation failed.
 */
export async function generateTryonImage(
  avatarImage: string,
  clothesImages: string[],
  garmentImageCounts: number[],
  scenePrompt?: string,
): Promise<string | null> {
  const taskPrompt = buildTaskPrompt(garmentImageCounts, scenePrompt);
  
  const project = Deno.env.get("GOOGLE_CLOUD_PROJECT");
  const location = Deno.env.get("GOOGLE_CLOUD_LOCATION") || "us-central1";
  const model = Deno.env.get("TRYON_MODEL") || "gemini-2.5-flash-image";
  const apiKey = Deno.env.get("VERTEX_API_KEY");

  if (!project || !apiKey) {
    throw new Error("GOOGLE_CLOUD_PROJECT and VERTEX_API_KEY environment variables are required");
  }

  const cleanAvatarBase64 = avatarImage.replace(/^data:image\/[a-z]+;base64,/, '');
  
  const parts: any[] = [
    { text: taskPrompt },
    {
      inlineData: {
        mimeType: detectMimeType(cleanAvatarBase64),
        data: cleanAvatarBase64,
      },
    },
  ];

  for (const img of clothesImages) {
    const cleanImg = img.replace(/^data:image\/[a-z]+;base64,/, '');
    parts.push({
      inlineData: {
        mimeType: detectMimeType(cleanImg),
        data: cleanImg,
      },
    });
  }

  const endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:generateContent`;

  const requestBody = {
    contents: [{
      role: "user",
      parts: parts,
    }],
    systemInstruction: {
      role: "system",
      parts: [{
        text: SYSTEM_INSTRUCTION,
      }],
    },
    generationConfig: {
      responseModalities: ["IMAGE"],
      temperature: 1.0,
      topP: 0.95,
      imageConfig: {
        aspectRatio: "9:16",
      },
    },
  };

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Failed to generate image. Status:", response.status);
      console.error("Error response:", errorText);
      throw new Error(`Failed to generate image: ${response.statusText} - ${errorText}`);
    }

    const data = await response.json();
    
    const candidates = data.candidates ?? [];
    
    for (const candidate of candidates) {
      const parts = candidate.content?.parts ?? [];
      for (const part of parts) {
        if (part.inlineData?.mimeType?.startsWith("image/") && part.inlineData.data) {
          return part.inlineData.data;
        }
      }
    }

    console.error("No image data in response:", JSON.stringify(data));
    return null;
  } catch (error) {
    console.error("Error generating try-on image:", error);
    throw error;
  }
}
