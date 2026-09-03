import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  EMPTY_PROMPT_CONFIG,
  loadPromptConfig,
  normalizePromptConfig,
  savePromptConfig,
} from "./promptConfig";

function useMemoryStorage(): void {
  const store = new Map<string, string>();
  vi.stubGlobal("localStorage", {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
  });
}

describe("promptConfig", () => {
  beforeEach(() => {
    vi.unstubAllGlobals();
    useMemoryStorage();
  });

  it("round-trips what was saved", () => {
    savePromptConfig({ scenePrompt: "urban street", stylingPrompt: "tucked in" });
    expect(loadPromptConfig()).toEqual({
      scenePrompt: "urban street",
      stylingPrompt: "tucked in",
    });
  });

  it("trims on the way in", () => {
    savePromptConfig({ scenePrompt: "  urban street ", stylingPrompt: "  " });
    expect(loadPromptConfig()).toEqual({
      scenePrompt: "urban street",
      stylingPrompt: "",
    });
  });

  it("starts empty", () => {
    expect(loadPromptConfig()).toEqual(EMPTY_PROMPT_CONFIG);
  });

  it("falls back to empty on a corrupt value rather than throwing", () => {
    localStorage.setItem("tryzeon.tryonPromptConfig", "{not json");
    expect(loadPromptConfig()).toEqual(EMPTY_PROMPT_CONFIG);
  });

  it("ignores non-string fields", () => {
    localStorage.setItem("tryzeon.tryonPromptConfig", '{"scenePrompt":7}');
    expect(loadPromptConfig()).toEqual(EMPTY_PROMPT_CONFIG);
  });

  it("survives a storage that throws", () => {
    vi.stubGlobal("localStorage", {
      getItem: () => {
        throw new Error("denied");
      },
      setItem: () => {
        throw new Error("denied");
      },
    });
    expect(loadPromptConfig()).toEqual(EMPTY_PROMPT_CONFIG);
    expect(() => savePromptConfig({ scenePrompt: "x", stylingPrompt: "" })).not.toThrow();
  });

  it("normalizes without touching storage", () => {
    expect(normalizePromptConfig({ scenePrompt: " a ", stylingPrompt: "\tb\n" }))
      .toEqual({ scenePrompt: "a", stylingPrompt: "b" });
  });
});
