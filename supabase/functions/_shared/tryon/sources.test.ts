import { assertEquals } from "jsr:@std/assert";
import { loadGarments, makeSourceLoader } from "./sources.ts";
import { USER_AVATARS_BUCKET } from "../storage.ts";
import type { SourceLoader } from "./sources.ts";

// Fake client whose storage download records the bucket and path it was asked
// for and returns bytes spelling out the request.
function fakeClient() {
  const downloads: string[] = [];
  const client = {
    storage: {
      from(bucket: string) {
        return {
          download(path: string) {
            downloads.push(`${bucket}/${path}`);
            return Promise.resolve({
              data: { arrayBuffer: () => Promise.resolve(new Uint8Array([65]).buffer) },
              error: null,
            });
          },
        };
      },
    },
  };
  // deno-lint-ignore no-explicit-any
  return { client: client as any, downloads };
}

Deno.test("makeSourceLoader passes base64 through without touching storage", async () => {
  const { client, downloads } = fakeClient();
  const load = makeSourceLoader(client, USER_AVATARS_BUCKET);
  assertEquals(await load({ base64: "ALREADY" }), "ALREADY");
  assertEquals(downloads, []);
});

Deno.test("makeSourceLoader downloads a path from the loader's bucket", async () => {
  const { client, downloads } = fakeClient();
  const load = makeSourceLoader(client, USER_AVATARS_BUCKET);
  assertEquals(await load({ path: "u1/avatar.jpg" }), "QQ==");
  assertEquals(downloads, [`${USER_AVATARS_BUCKET}/u1/avatar.jpg`]);
});

Deno.test("loadGarments preserves garment grouping and image order", async () => {
  const load: SourceLoader = (source) =>
    Promise.resolve("base64" in source ? source.base64 : `@${source.path}`);
  const groups = await loadGarments(
    [
      { images: [{ base64: "A1" }, { path: "p/a2.jpg" }] },
      { images: [{ base64: "B1" }] },
    ],
    load,
  );
  assertEquals(groups, [["A1", "@p/a2.jpg"], ["B1"]]);
});
