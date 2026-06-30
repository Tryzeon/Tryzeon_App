// @vitest-environment node
import { describe, expect, it } from "vitest";
import { downscaleDimensions } from "./image";

describe("downscaleDimensions", () => {
  it("leaves images already within bounds unchanged", () => {
    expect(downscaleDimensions(800, 600, 1024)).toEqual({ width: 800, height: 600 });
  });
  it("scales a wide image so the long edge equals max", () => {
    expect(downscaleDimensions(2048, 1024, 1024)).toEqual({ width: 1024, height: 512 });
  });
  it("scales a tall image so the long edge equals max", () => {
    expect(downscaleDimensions(1000, 4000, 1024)).toEqual({ width: 256, height: 1024 });
  });
});
