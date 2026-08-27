import { describe, expect, it } from "vitest";
import { downscaleDimensions } from "./image";

describe("downscaleDimensions", () => {
  it("leaves an image already within the cap untouched", () => {
    expect(downscaleDimensions(800, 600, 1024)).toEqual({
      width: 800,
      height: 600,
    });
  });

  it("scales by the long edge, whichever it is", () => {
    expect(downscaleDimensions(2048, 1024, 1024)).toEqual({
      width: 1024,
      height: 512,
    });
    expect(downscaleDimensions(1024, 2048, 1024)).toEqual({
      width: 512,
      height: 1024,
    });
  });

  it("rounds rather than truncating, so a canvas never gets a 0 edge", () => {
    expect(downscaleDimensions(3000, 7, 1000)).toEqual({ width: 1000, height: 2 });
  });
});
