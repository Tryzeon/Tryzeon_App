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
  assertStringIncludes(prompt, "Do not change the background from the first image.");
});

Deno.test("buildTaskPrompt adds the scene section and its invariant caveat", () => {
  const prompt = buildTaskPrompt([["a"]], "a rooftop at dusk");
  assertStringIncludes(prompt, "SCENE CONTEXT — BACKGROUND ONLY");
  assertStringIncludes(prompt, "Place the person in this scene: a rooftop at dusk");
  assertStringIncludes(prompt, "(unless overridden by SCENE CONTEXT below)");
});

Deno.test("buildTaskPrompt includes only non-blank garment details", () => {
  const prompt = buildTaskPrompt([["a"], ["b"], ["c"]], undefined, [
    "Material: Linen",
    "   ",
    undefined,
  ]);
  assertStringIncludes(prompt, "GARMENT DETAILS");
  assertStringIncludes(prompt, "- Garment 1: Material: Linen");
  assertEquals(prompt.includes("- Garment 2:  "), false);
});

Deno.test("buildTaskPrompt omits the details section when all details are blank", () => {
  const prompt = buildTaskPrompt([["a"]], undefined, [undefined]);
  assertEquals(prompt.includes("GARMENT DETAILS"), false);
});

Deno.test("buildVideoPrompt falls back to the default when no transition is given", () => {
  assertStringIncludes(buildVideoPrompt(), "turning slightly to show the fit");
});

Deno.test("buildVideoPrompt embeds a custom transition style", () => {
  const prompt = buildVideoPrompt("slow dolly in");
  assertStringIncludes(prompt, "Camera and transition style: slow dolly in.");
});
