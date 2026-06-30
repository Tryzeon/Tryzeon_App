import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Production build config only. Test config lives in vitest.config.ts so the
// `tsc -b && vite build` step never depends on Vitest's type augmentation.
export default defineConfig({
  plugins: [react()],
});
