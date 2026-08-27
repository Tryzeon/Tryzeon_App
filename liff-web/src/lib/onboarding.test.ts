import { beforeEach, describe, expect, it } from "vitest";
import { isOnboarded, setOnboarded } from "./onboarding";

describe("onboarding state", () => {
  beforeEach(() => setOnboarded(false));

  it("starts out not onboarded", () => {
    expect(isOnboarded()).toBe(false);
  });

  // 上傳成功後不重新查一次伺服器就要能反映出來,否則使用者剛傳完照片、按試穿
  // 又被踢回 /onboard。
  it("flips once the model photo is in", () => {
    setOnboarded(true);
    expect(isOnboarded()).toBe(true);
  });
});
