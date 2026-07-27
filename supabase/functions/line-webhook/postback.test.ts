import { assertEquals } from "jsr:@std/assert";
import { parsePostback, tryonPostbackData } from "./postback.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

Deno.test("what a card encodes is what the webhook reads back", () => {
  assertEquals(parsePostback(tryonPostbackData(PID)), {
    kind: "tryon",
    productId: PID,
  });
});

Deno.test("an unknown action is not ours to handle", () => {
  assertEquals(parsePostback(`a=save&pid=${PID}`), null);
  assertEquals(parsePostback(`pid=${PID}`), null);
  assertEquals(parsePostback(""), null);
});

Deno.test("a pid Postgres would reject never reaches Postgres", () => {
  assertEquals(parsePostback("a=tryon&pid=not-a-uuid"), null);
  assertEquals(parsePostback("a=tryon&pid="), null);
  assertEquals(parsePostback("a=tryon"), null);
});

Deno.test("a data field that is not even a string is not a postback", () => {
  assertEquals(parsePostback(undefined), null);
  assertEquals(parsePostback(null), null);
  assertEquals(parsePostback({ a: "tryon" }), null);
});
