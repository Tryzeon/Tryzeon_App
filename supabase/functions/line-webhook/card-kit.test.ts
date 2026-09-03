import { assertEquals } from "jsr:@std/assert";
import { CARD_COLOR, primaryButton, secondaryButton } from "./card-kit.ts";

const action = { type: "postback", label: "試穿這件", data: "a=tryon&pid=p1" };

Deno.test("the palette is the design system's, not an approximation", () => {
  assertEquals(CARD_COLOR, {
    primary: "#1A1A1A",
    onPrimary: "#FFFFFF",
    muted: "#9E9E9E",
    outline: "#E5E5E5",
    surface: "#FFFFFF",
  });
});

Deno.test("a button's action is on the box, so the whole button is tappable", () => {
  for (
    const button of [
      primaryButton("試穿這件", action),
      secondaryButton("前往購買", action),
    ]
  ) {
    // deno-lint-ignore no-explicit-any
    const b = button as any;
    assertEquals(b.type, "box");
    assertEquals(b.action, action);
    assertEquals(b.contents[0].action, undefined);
  }
});

Deno.test("the primary button is filled charcoal with white type", () => {
  // deno-lint-ignore no-explicit-any
  const b = primaryButton("試穿這件", action) as any;
  assertEquals(b.backgroundColor, CARD_COLOR.primary);
  assertEquals(b.cornerRadius, "8px");
  assertEquals(b.borderWidth, undefined);
  assertEquals(b.contents[0].text, "試穿這件");
  assertEquals(b.contents[0].color, CARD_COLOR.onPrimary);
  assertEquals(b.contents[0].align, "center");
});

Deno.test("the secondary button is outlined, with no fill", () => {
  // deno-lint-ignore no-explicit-any
  const b = secondaryButton("前往購買", action) as any;
  assertEquals(b.backgroundColor, undefined);
  assertEquals(b.borderWidth, "1px");
  assertEquals(b.borderColor, CARD_COLOR.outline);
  assertEquals(b.cornerRadius, "8px");
  assertEquals(b.contents[0].color, CARD_COLOR.primary);
});
