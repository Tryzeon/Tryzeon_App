import { createContext, useContext, useReducer, type ReactNode } from "react";
import {
  galleryReducer,
  initialGalleryState,
  type GalleryAction,
  type GalleryState,
} from "./gallery";

/**
 * 只活在記憶體裡 —— 試穿結果沒有任何一張表記得它的 object key,存下網址只會在第
 * 7 天全部變成 403。
 */
const GalleryContext = createContext<
  { state: GalleryState; dispatch: (action: GalleryAction) => void } | null
>(null);

export function GalleryProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(galleryReducer, initialGalleryState);
  return (
    <GalleryContext.Provider value={{ state, dispatch }}>
      {children}
    </GalleryContext.Provider>
  );
}

export function useGallery() {
  const value = useContext(GalleryContext);
  if (value === null) throw new Error("useGallery outside GalleryProvider");
  return value;
}
