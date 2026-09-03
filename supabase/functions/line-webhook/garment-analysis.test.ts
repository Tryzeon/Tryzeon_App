import { assertEquals } from "jsr:@std/assert@^1.0.19";
import {
  ANALYSIS_PROMPT,
  ANALYSIS_SCHEMA,
  describeGarment,
  type DescribeGarmentDeps,
} from "./garment-analysis.ts";

const USER = "user-1";
const B64 = "aGVsbG8=";

const seams = (over: DescribeGarmentDeps = {}): DescribeGarmentDeps => ({
  analyze: () => Promise.resolve({ description: "淺藍色寬鬆棉質抽繩長褲" }),
  checkLimit: () => Promise.resolve(true),
  ...over,
});

async function captureWarnings(fn: () => Promise<void>): Promise<unknown[][]> {
  const real = console.warn;
  const calls: unknown[][] = [];
  console.warn = (...args: unknown[]) => {
    calls.push(args);
  };
  try {
    await fn();
  } finally {
    console.warn = real;
  }
  return calls;
}

Deno.test("a described garment comes back as one phrase", async () => {
  assertEquals(
    await describeGarment(USER, B64, seams()),
    "淺藍色寬鬆棉質抽繩長褲",
  );
});

Deno.test("the photo is sent with this channel's own prompt and schema", async () => {
  // Not the wardrobe endpoint's: its controlled vocabulary would drop the very
  // words ("淺", "抽繩") that make a follow-up search land.
  const seen: { prompt?: string; schema?: unknown; base64?: string }[] = [];
  await describeGarment(USER, B64, seams({
    analyze: (args) => {
      seen.push(args);
      return Promise.resolve({ description: "白襯衫" });
    },
  }));

  assertEquals(seen.length, 1);
  assertEquals(seen[0].base64, B64);
  assertEquals(seen[0].prompt, ANALYSIS_PROMPT);
  assertEquals(seen[0].schema, ANALYSIS_SCHEMA);
});

Deno.test("a surrounding-whitespace description is trimmed", async () => {
  assertEquals(
    await describeGarment(USER, B64, seams({
      analyze: () => Promise.resolve({ description: "  白襯衫  " }),
    })),
    "白襯衫",
  );
});

Deno.test("an over-long description is clamped", async () => {
  const result = await describeGarment(USER, B64, seams({
    analyze: () => Promise.resolve({ description: "藍".repeat(50) }),
  }));

  assertEquals(result, `${"藍".repeat(20)}…`);
});

Deno.test("clamping counts characters, not UTF-16 code units", async () => {
  // `slice` would cut an astral character in half and leave a lone surrogate in
  // the transcript.
  const result = await describeGarment(USER, B64, seams({
    analyze: () => Promise.resolve({ description: "👗".repeat(30) }),
  }));

  assertEquals(result, `${"👗".repeat(20)}…`);
});

Deno.test("an empty or non-string description is no description at all", async () => {
  for (const description of ["", "   ", 7, null, undefined]) {
    assertEquals(
      await describeGarment(USER, B64, seams({
        analyze: () => Promise.resolve({ description }),
      })),
      null,
    );
  }
});

Deno.test("a failed analysis costs the note, not the caller's turn", async () => {
  let result: string | null = "unset";
  const warnings = await captureWarnings(async () => {
    result = await describeGarment(USER, B64, seams({
      analyze: () => Promise.reject(new Error("vertex down")),
    }));
  });

  assertEquals(result, null);
  assertEquals(warnings.length, 1);
});

Deno.test("a rate-limited caller is not analysed at all", async () => {
  let analysed = false;
  let result: string | null = "unset";
  const warnings = await captureWarnings(async () => {
    result = await describeGarment(USER, B64, seams({
      checkLimit: () => Promise.resolve(false),
      analyze: () => {
        analysed = true;
        return Promise.resolve({ description: "白襯衫" });
      },
    }));
  });

  assertEquals(analysed, false);
  assertEquals(result, null);
  assertEquals(warnings.length, 1);
});

Deno.test("the limit is this channel's own budget, per minute and per day", async () => {
  const buckets: string[] = [];
  await describeGarment(USER, B64, seams({
    checkLimit: (userId, bucket) => {
      assertEquals(userId, USER);
      buckets.push(bucket);
      return Promise.resolve(true);
    },
  }));

  assertEquals(buckets, ["line_garment_analysis:minute", "line_garment_analysis:day"]);
});

// A cap the prompt states but the code does not enforce is a transcript-bloat
// bug waiting for one verbose model response.
Deno.test("ANALYSIS_PROMPT states the length cap describeGarment enforces", async () => {
  const clamped = await describeGarment(USER, B64, seams({
    analyze: () => Promise.resolve({ description: "藍".repeat(50) }),
  }));

  // Derived, not hardcoded: the ellipsis isn't part of the cap, which is
  // measured in code points.
  const cap = [...clamped!.replace(/…$/, "")].length;
  assertEquals(ANALYSIS_PROMPT.includes(`最多 ${cap} 字`), true);
});

Deno.test("ANALYSIS_SCHEMA requires the one field describeGarment reads", () => {
  const schema = ANALYSIS_SCHEMA as {
    properties: Record<string, unknown>;
    required: string[];
  };

  assertEquals(Object.keys(schema.properties), ["description"]);
  assertEquals(schema.required, ["description"]);
});
