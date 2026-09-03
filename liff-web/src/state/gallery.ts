/** Page 0 is always the avatar photo; every try-on (pending or finished) takes
 * one page after it. */

export interface TryonProduct {
  productId: string;
  name: string;
}

interface EntryBase {
  id: string;
  product: TryonProduct | null;
}

export type GalleryEntry =
  | (EntryBase & { kind: "pending" })
  | (EntryBase & { kind: "finished"; imageUrl: string });

/** [id] makes the same message said twice count as a new notice: the home
 * page's auto-dismiss timer keys off it. */
export interface Notice {
  id: number;
  message: string;
}

export interface GalleryState {
  entries: GalleryEntry[];
  currentId: string | null;
  customAvatarId: string | null;
  /**
   * Kept in the gallery rather than as home-page local state: a try-on started
   * from the product page has already moved the user to home by the time it
   * fails, so the message has to survive that navigation.
   */
  notice: Notice | null;
}

export const initialGalleryState: GalleryState = {
  entries: [],
  currentId: null,
  customAvatarId: null,
  notice: null,
};

export type GalleryAction =
  | { type: "setPage"; page: number }
  | { type: "addPending"; id: string; product: TryonProduct | null }
  | { type: "complete"; id: string; imageUrl: string }
  | { type: "remove"; id: string }
  | { type: "fail"; id: string; message: string }
  | { type: "toggleAvatar" }
  | { type: "notify"; message: string }
  | { type: "dismissNotice" };

export function currentIndex(state: GalleryState): number {
  return state.entries.findIndex((e) => e.id === state.currentId);
}

export function currentPage(state: GalleryState): number {
  return currentIndex(state) + 1;
}

export function isAvatarPage(state: GalleryState): boolean {
  return currentIndex(state) === -1;
}

export function currentEntry(state: GalleryState): GalleryEntry | null {
  const index = currentIndex(state);
  return index === -1 ? null : state.entries[index];
}

export function currentImageUrl(state: GalleryState): string | null {
  const entry = currentEntry(state);
  return entry?.kind === "finished" ? entry.imageUrl : null;
}

export function customAvatarUrl(state: GalleryState): string | null {
  const entry = state.entries.find((e) => e.id === state.customAvatarId);
  return entry?.kind === "finished" ? entry.imageUrl : null;
}

export function isCurrentTheAvatar(state: GalleryState): boolean {
  return state.currentId !== null && state.currentId === state.customAvatarId;
}

/** Returns null when no such entry exists, so callers can tell "removed" from
 * "was never there". */
function withoutEntry(state: GalleryState, id: string): GalleryState | null {
  const index = state.entries.findIndex((e) => e.id === id);
  if (index === -1) return null;

  const entries = [...state.entries];
  entries.splice(index, 1);

  const currentId = state.currentId !== id
    ? state.currentId
    : entries.length === 0
    ? null
    : entries[Math.min(index, entries.length - 1)].id;

  return {
    ...state,
    entries,
    currentId,
    customAvatarId: state.customAvatarId === id ? null : state.customAvatarId,
  };
}

export function galleryReducer(
  state: GalleryState,
  action: GalleryAction,
): GalleryState {
  switch (action.type) {
    case "setPage": {
      const index = action.page - 1;
      const id = index >= 0 && index < state.entries.length
        ? state.entries[index].id
        : null;
      // The same page must return the same object: the scroll listener fires
      // setPage every frame, and a fresh object would re-run the
      // state → scroll position effect forever.
      return state.currentId === id ? state : { ...state, currentId: id };
    }

    case "addPending":
      return {
        ...state,
        entries: [
          ...state.entries,
          { kind: "pending", id: action.id, product: action.product },
        ],
        currentId: action.id,
      };

    case "complete": {
      const index = state.entries.findIndex((e) => e.id === action.id);
      // The user deleted it while it was generating — the result has nowhere to
      // go, so drop it silently.
      if (index === -1) return state;
      const entries = [...state.entries];
      entries[index] = {
        kind: "finished",
        id: action.id,
        imageUrl: action.imageUrl,
        product: entries[index].product,
      };
      return { ...state, entries };
    }

    case "remove":
      return withoutEntry(state, action.id) ?? state;

    case "fail": {
      // The user already cancelled this generation, so the failure is no longer
      // theirs — drop it silently rather than surfacing a message about
      // something they gave up on.
      const next = withoutEntry(state, action.id);
      return next === null
        ? state
        : { ...next, notice: nextNotice(state, action.message) };
    }

    case "toggleAvatar": {
      const id = state.currentId;
      if (id === null) return state;
      return { ...state, customAvatarId: state.customAvatarId === id ? null : id };
    }

    case "notify":
      return { ...state, notice: nextNotice(state, action.message) };

    case "dismissNotice":
      return state.notice === null ? state : { ...state, notice: null };
  }
}

function nextNotice(state: GalleryState, message: string): Notice {
  return { id: (state.notice?.id ?? 0) + 1, message };
}
