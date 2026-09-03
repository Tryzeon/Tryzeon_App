import { createContext, useContext, useReducer, type ReactNode } from "react";
import {
  galleryReducer,
  initialGalleryState,
  type GalleryAction,
  type GalleryState,
} from "./gallery";

/**
 * Memory only — no table records the object key of a try-on result, so persisted
 * URLs would all turn into 403s on day 7.
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
