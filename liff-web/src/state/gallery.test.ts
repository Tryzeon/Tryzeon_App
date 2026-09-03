import { describe, expect, it } from "vitest";
import {
  currentEntry,
  currentImageUrl,
  currentPage,
  customAvatarUrl,
  galleryReducer,
  initialGalleryState,
  isAvatarPage,
  isCurrentTheAvatar,
  type GalleryState,
} from "./gallery";

function withEntries(...ids: string[]): GalleryState {
  return ids.reduce(
    (state, id) => galleryReducer(state, { type: "addPending", id, product: null }),
    initialGalleryState,
  );
}

describe("pages", () => {
  it("starts on the model photo", () => {
    expect(currentPage(initialGalleryState)).toBe(0);
    expect(isAvatarPage(initialGalleryState)).toBe(true);
  });

  it("jumps to a try-on the moment it starts", () => {
    const state = withEntries("a", "b");
    expect(currentPage(state)).toBe(2);
    expect(isAvatarPage(state)).toBe(false);
  });

  it("returns the same object when the page did not change", () => {
    const state = withEntries("a");
    expect(galleryReducer(state, { type: "setPage", page: 1 })).toBe(state);
  });

  it("treats any out-of-range page as the model photo", () => {
    const state = galleryReducer(withEntries("a"), { type: "setPage", page: 9 });
    expect(isAvatarPage(state)).toBe(true);
  });
});

describe("completing", () => {
  it("swaps the placeholder for its result", () => {
    const state = galleryReducer(withEntries("a"), {
      type: "complete",
      id: "a",
      imageUrl: "https://r2/a.jpg",
    });
    expect(currentImageUrl(state)).toBe("https://r2/a.jpg");
  });

  it("drops a result whose entry the user already removed", () => {
    const removed = galleryReducer(withEntries("a"), { type: "remove", id: "a" });
    const state = galleryReducer(removed, {
      type: "complete",
      id: "a",
      imageUrl: "https://r2/a.jpg",
    });
    expect(state).toBe(removed);
    expect(state.entries).toHaveLength(0);
  });
});

describe("removing", () => {
  it("falls back to the neighbour that took its place", () => {
    const state = galleryReducer(withEntries("a", "b", "c"), {
      type: "remove",
      id: "c",
    });
    expect(state.currentId).toBe("b");
  });

  it("falls back to the model photo when nothing is left", () => {
    const state = galleryReducer(withEntries("a"), { type: "remove", id: "a" });
    expect(isAvatarPage(state)).toBe(true);
  });

  it("leaves the page in view alone when some other entry goes", () => {
    const state = galleryReducer(withEntries("a", "b"), { type: "remove", id: "a" });
    expect(state.currentId).toBe("b");
  });
});

describe("custom avatar", () => {
  it("toggles the page in view on and off", () => {
    const done = galleryReducer(withEntries("a"), {
      type: "complete",
      id: "a",
      imageUrl: "https://r2/a.jpg",
    });

    const on = galleryReducer(done, { type: "toggleAvatar" });
    expect(isCurrentTheAvatar(on)).toBe(true);
    expect(customAvatarUrl(on)).toBe("https://r2/a.jpg");

    const off = galleryReducer(on, { type: "toggleAvatar" });
    expect(isCurrentTheAvatar(off)).toBe(false);
    expect(customAvatarUrl(off)).toBeNull();
  });

  it("cannot be set from the model page", () => {
    const state = galleryReducer(initialGalleryState, { type: "toggleAvatar" });
    expect(state).toBe(initialGalleryState);
  });

  // Once the avatar image is deleted, the next try-on must fall back to the one
  // on the profile rather than point at an id that no longer exists.
  it("is dropped along with the entry it points at", () => {
    const done = galleryReducer(withEntries("a"), {
      type: "complete",
      id: "a",
      imageUrl: "https://r2/a.jpg",
    });
    const on = galleryReducer(done, { type: "toggleAvatar" });
    const state = galleryReducer(on, { type: "remove", id: "a" });
    expect(state.customAvatarId).toBeNull();
    expect(customAvatarUrl(state)).toBeNull();
  });

  // A page still generating has no image to serve as an avatar, and the menu
  // does not offer the option — but the state layer still has to be safe.
  it("yields no url while the entry it points at is still pending", () => {
    const on = galleryReducer(withEntries("a"), { type: "toggleAvatar" });
    expect(customAvatarUrl(on)).toBeNull();
  });
});

describe("product source", () => {
  const shirt = { productId: "p1", name: "白襯衫" };

  // The "試穿 ⋯" line on the result image lives off this field, so completing
  // must not overwrite it.
  it("survives the swap from pending to finished", () => {
    const pending = galleryReducer(initialGalleryState, {
      type: "addPending",
      id: "a",
      product: shirt,
    });
    const done = galleryReducer(pending, {
      type: "complete",
      id: "a",
      imageUrl: "https://r2/a.jpg",
    });
    expect(currentEntry(done)?.product).toEqual(shirt);
  });

  it("is null for a garment the user photographed themselves", () => {
    expect(currentEntry(withEntries("a"))?.product).toBeNull();
  });
});

describe("notice", () => {
  // When a try-on started from the product page fails, the user has already been
  // moved to home, so the message has to survive that navigation.
  it("holds the last message until dismissed", () => {
    const shown = galleryReducer(initialGalleryState, {
      type: "notify",
      message: "今日試穿次數已用完",
    });
    expect(shown.notice?.message).toBe("今日試穿次數已用完");

    const cleared = galleryReducer(shown, { type: "dismissNotice" });
    expect(cleared.notice).toBeNull();
  });

  it("gives the same message a fresh id when it is raised again", () => {
    const first = galleryReducer(initialGalleryState, {
      type: "notify",
      message: "出了點狀況",
    });
    const second = galleryReducer(first, { type: "notify", message: "出了點狀況" });
    expect(second.notice?.message).toBe(first.notice?.message);
    expect(second.notice?.id).not.toBe(first.notice?.id);
  });

  it("returns the same object when there was nothing to dismiss", () => {
    expect(galleryReducer(initialGalleryState, { type: "dismissNotice" }))
      .toBe(initialGalleryState);
  });
});

describe("failing", () => {
  it("drops the placeholder and says why", () => {
    const state = galleryReducer(withEntries("a"), {
      type: "fail",
      id: "a",
      message: "今日試穿次數已用完",
    });
    expect(state.entries).toHaveLength(0);
    expect(state.notice?.message).toBe("今日試穿次數已用完");
    expect(isAvatarPage(state)).toBe(true);
  });

  it("stays silent when the user already cancelled it", () => {
    const removed = galleryReducer(withEntries("a"), { type: "remove", id: "a" });
    const state = galleryReducer(removed, {
      type: "fail",
      id: "a",
      message: "出了點狀況",
    });
    expect(state).toBe(removed);
    expect(state.notice).toBeNull();
  });

  it("leaves the other try-ons and the page in view alone", () => {
    const state = galleryReducer(withEntries("a", "b"), {
      type: "fail",
      id: "a",
      message: "出了點狀況",
    });
    expect(state.entries.map((e) => e.id)).toEqual(["b"]);
    expect(state.currentId).toBe("b");
  });
});
