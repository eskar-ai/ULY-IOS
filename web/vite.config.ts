import { defineConfig } from "vite";

/** Set VITE_BASE=/ULY-IOS/demo/ when publishing to GitHub Pages. */
const base = process.env.VITE_BASE || "/";

export default defineConfig({
  base,
  server: {
    host: "0.0.0.0",
    port: 3847,
    // If 3847 is taken, Vite picks the next free port (do not hardcode localhost:3847 in docs).
    strictPort: false,
  },
  preview: {
    host: "0.0.0.0",
    port: 3847,
    strictPort: false,
  },
});
