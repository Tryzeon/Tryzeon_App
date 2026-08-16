import { assertEquals, assertStringIncludes } from "jsr:@std/assert";
import { buildTaskPrompt, buildVideoPrompt } from "./prompt.ts";

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
  assertStringIncludes(
    prompt,
    "If a number disagrees with what the images show, the images win.",
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
