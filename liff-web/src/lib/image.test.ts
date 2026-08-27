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
  // 只斷言契約的一半:canvas 在 node 環境沒有實作,所以真的畫圖那段留給手動
  // 驗收。這裡守的是「輸出一定是 jpeg」—— 儲存路徑的副檔名和 contentType 都
  // 是照這個假設寫死的,改成 png 而忘了改路徑會是個安靜的錯。
  it("is declared to produce jpeg", () => {
    expect(JPEG_MIME).toBe("image/jpeg");
    expect(JPEG_EXTENSION).toBe("jpg");
  });
});
