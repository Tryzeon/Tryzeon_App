import { assertEquals } from "@std/assert";
import {
  CHANNEL_VALUES,
  ELASTICITY_VALUES,
  FIT_VALUES,
  GENDER_VALUES,
  SEASON_VALUES,
  THICKNESS_VALUES,
} from "./vocabularies.ts";

Deno.test("vocabularies match the schema enums", () => {
  assertEquals([...SEASON_VALUES], ["spring", "summer", "autumn", "winter"]);
  assertEquals([...THICKNESS_VALUES], ["low", "medium", "high"]);
  assertEquals([...ELASTICITY_VALUES], ["none", "low", "medium", "high"]);
  assertEquals([...FIT_VALUES], ["slim", "regular", "loose", "oversize"]);
  assertEquals([...CHANNEL_VALUES], ["physical", "online"]);
  assertEquals([...GENDER_VALUES], ["male", "female", "unisex"]);
});

Deno.test("no vocabulary is empty", () => {
  for (
    const v of [
      SEASON_VALUES,
      THICKNESS_VALUES,
      ELASTICITY_VALUES,
      FIT_VALUES,
      CHANNEL_VALUES,
      GENDER_VALUES,
    ]
  ) {
    assertEquals(v.length > 0, true);
  }
});
