/** 第 0 頁永遠是模特照,之後每一次試穿(生成中或已完成)各佔一頁。 */

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

/** [id] 讓「同一句話再說一次」仍算新的一則:首頁的自動消失計時器以它為依據。 */
export interface Notice {
  id: number;
  message: string;
}

export interface GalleryState {
  entries: GalleryEntry[];
  currentId: string | null;
  customAvatarId: string | null;
  /**
   * 放在 gallery 而不是首頁的區域狀態:一次從商品頁按下去的試穿,失敗時人已經被
   * 帶到首頁了,訊息必須跨得過那次換頁。
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

/** 沒有這筆 entry 時回 null,讓呼叫端能分辨「刪掉了」和「本來就不在」。 */
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
      // 同一頁要回傳同一個物件:捲動監聽器每一幀都會送一次 setPage,換新物件會
      // 讓「狀態 → 捲動位置」那條 effect 一直重跑。
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
      // 使用者在生成途中就把它刪了 —— 那份結果沒有位置可放,靜靜丟掉。
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
      // 使用者已經按過「取消生成」,這次失敗不再屬於他 —— 靜靜丟掉,不要為一件
      // 他早就放棄的事彈訊息。
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
