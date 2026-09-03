import { describe, expect, it } from "vitest";
import {
  downscaleDimensions,
  JPEG_EXTENSION,
  JPEG_MIME,
} from "./image";

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

describe("downscaleToBlob", () => {
  // Asserts half the contract: canvas has no implementation under node, so the
  // actual drawing is left to manual verification. What is guarded here is that
  // the output is always jpeg — the storage path's extension and contentType are
  // both hard-coded on that assumption, and switching to png without changing
  // the path would be a silent bug.
  it("is declared to produce jpeg", () => {
    expect(JPEG_MIME).toBe("image/jpeg");
    expect(JPEG_EXTENSION).toBe("jpg");
  });
});
