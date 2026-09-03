import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  buildTaskPrompt,
  buildVideoPrompt,
  SYSTEM_INSTRUCTION,
} from "./prompt.ts";

Deno.test("buildTaskPrompt counts the person image plus every garment image", () => {
  const prompt = buildTaskPrompt([["a", "b"], ["c"]]);
  assertStringIncludes(prompt, "You will receive 4 images after this message");
});

Deno.test("buildTaskPrompt numbers garment groups from image 2 onward", () => {
  const prompt = buildTaskPrompt([["a", "b"], ["c"]]);
  assertStringIncludes(prompt, "- Garment 1: images 2-3");
  assertStringIncludes(prompt, "- Garment 2: image 4");
});

Deno.test("buildTaskPrompt omits the scene section when no scene is given", () => {
  const prompt = buildTaskPrompt([["a"]]);
  assertEquals(prompt.includes("SCENE CONTEXT"), false);
  assertStringIncludes(
    prompt,
    "Do not change the background from the first image.",
  );
});

Deno.test("buildTaskPrompt adds the scene section and its invariant caveat", () => {
  const prompt = buildTaskPrompt([["a"]], {
    scenePrompt: "a rooftop at dusk",
  });
  assertStringIncludes(prompt, "SCENE CONTEXT — BACKGROUND ONLY");
  assertStringIncludes(
    prompt,
    "Place the person in this scene: a rooftop at dusk",
  );
  assertStringIncludes(prompt, "(unless overridden by SCENE CONTEXT below)");
});

Deno.test("buildTaskPrompt includes only non-blank garment details", () => {
  const prompt = buildTaskPrompt([["a"], ["b"], ["c"]], {
    garmentDetails: ["Material: Linen", "   ", undefined],
  });
  assertStringIncludes(prompt, "GARMENT DETAILS");
  assertStringIncludes(prompt, "- Garment 1: Material: Linen");
  assertEquals(prompt.includes("- Garment 2:  "), false);
});

Deno.test("buildTaskPrompt omits the details section when all details are blank", () => {
  const prompt = buildTaskPrompt([["a"]], { garmentDetails: [undefined] });
  assertEquals(prompt.includes("GARMENT DETAILS"), false);
});

Deno.test("buildVideoPrompt falls back to the default when no transition is given", () => {
  assertStringIncludes(buildVideoPrompt(), "turning slightly to show the fit");
});

Deno.test("buildVideoPrompt embeds a custom transition style", () => {
  const prompt = buildVideoPrompt("slow dolly in");
  assertStringIncludes(prompt, "Camera and transition style: slow dolly in.");
});

Deno.test("buildTaskPrompt omits the fit section when no fits are given", () => {
  const prompt = buildTaskPrompt([["a"]], {
    garmentDetails: ["Material: Linen"],
  });
  assertEquals(prompt.includes("GARMENT FIT"), false);
});

Deno.test("buildTaskPrompt omits the fit section when every fit is blank", () => {
  const prompt = buildTaskPrompt([["a"], ["b"]], {
    garmentFits: [undefined, "  "],
  });
  assertEquals(prompt.includes("GARMENT FIT"), false);
});

Deno.test("buildTaskPrompt lists only non-blank fits, numbered per garment", () => {
  const prompt = buildTaskPrompt([["a"], ["b"]], {
    garmentFits: [
      undefined,
      "size M: chest 104cm on a 92cm chest (+12cm — fitted, follows the body with a little room)",
    ],
  });

  assertStringIncludes(prompt, "GARMENT FIT — HOW THIS SIZE SITS ON THIS BODY");
  assertStringIncludes(
    prompt,
    "- Garment 2, size M: chest 104cm on a 92cm chest (+12cm — fitted, follows the body with a little room)",
  );
  assertEquals(prompt.includes("- Garment 1,"), false);
});

Deno.test("buildTaskPrompt guards the body against the fit numbers", () => {
  const prompt = buildTaskPrompt([["a"]], {
    garmentFits: ["size M: chest 104cm"],
  });

  assertStringIncludes(
    prompt,
    "NEVER resize, reshape, or re-proportion the person to match these numbers",
  );
});

Deno.test("buildTaskPrompt keeps details, fit, and scene in that order", () => {
  const prompt = buildTaskPrompt([["a"]], {
    garmentDetails: ["Material: Linen"],
    scenePrompt: "a rooftop at dusk",
    garmentFits: ["size M: chest 104cm"],
  });

  assertEquals(
    prompt.indexOf("GARMENT DETAILS") < prompt.indexOf("GARMENT FIT"),
    true,
  );
  assertEquals(
    prompt.indexOf("GARMENT FIT") <
      prompt.indexOf("SCENE CONTEXT — BACKGROUND ONLY"),
    true,
  );
});

Deno.test("buildTaskPrompt omits the styling section when no styling is given", () => {
  const prompt = buildTaskPrompt([["a"]]);
  assertEquals(prompt.includes("STYLING"), false);
});

Deno.test("buildTaskPrompt states the styling as a required property of the output", () => {
  const prompt = buildTaskPrompt([["a"]], {
    stylingPrompt: "tucked into the waistband",
  });
  assertStringIncludes(prompt, "STYLING — HOW THE GARMENT IS WORN");
  assertStringIncludes(
    prompt,
    "In the output image the replaced garment MUST be worn this way: tucked into the waistband",
  );
  assertStringIncludes(
    prompt,
    "Render it even when the first image shows that garment worn differently.",
  );
});

Deno.test("buildTaskPrompt lifts both preservation rules that styling contradicts", () => {
  const prompt = buildTaskPrompt([["a"]], { stylingPrompt: "hem tucked in" });
  // The attribute list and the concrete "do NOT touch the original pants"
  // example are two separate prohibitions: leaving either un-caveated lets the
  // model prefer it over the override.
  assertStringIncludes(
    prompt,
    "except where STYLING below changes how the replaced garment sits against them",
  );
  assertStringIncludes(
    prompt,
    "unless STYLING below requires it",
  );
});

Deno.test("buildTaskPrompt keeps the styling override scoped to the replaced garment", () => {
  const prompt = buildTaskPrompt([["a"]], { stylingPrompt: "hem tucked in" });
  assertStringIncludes(
    prompt,
    "Redraw whatever this reveals or hides on a preserved garment",
  );
  assertStringIncludes(
    prompt,
    "the preserved garment's own color, pattern, cut, and length still must not change",
  );
});

Deno.test("buildTaskPrompt places styling after fit and before scene", () => {
  const prompt = buildTaskPrompt([["a"]], {
    garmentFits: ["size M: chest 104cm"],
    stylingPrompt: "hem tucked in",
    scenePrompt: "a rooftop at dusk",
  });

  assertEquals(
    prompt.indexOf("GARMENT FIT") <
      prompt.indexOf("STYLING — HOW THE GARMENT IS WORN"),
    true,
  );
  assertEquals(
    prompt.indexOf("STYLING — HOW THE GARMENT IS WORN") <
      prompt.indexOf("SCENE CONTEXT — BACKGROUND ONLY"),
    true,
  );
});

Deno.test("SYSTEM_INSTRUCTION authorizes styling edits alongside garment and scene", () => {
  assertStringIncludes(SYSTEM_INSTRUCTION, "garment-styling");
});
