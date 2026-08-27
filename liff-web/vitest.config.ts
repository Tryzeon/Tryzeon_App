import { defineConfig } from "vitest/config";

// Separate from vite.config.ts on purpose — see the note there: the
// `tsc -b && vite build` step must never depend on Vitest's type augmentation.
// Node environment: everything under test here is a pure function.
export default defineConfig({
  test: {
    include: ["src/**/*.test.ts"],
    environment: "node",
  },
});
