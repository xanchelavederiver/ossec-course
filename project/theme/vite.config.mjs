// Lecture sources live below `materials/`, while their generated artifacts are
// collected in the project-level `dist/` directory. Slidev uses the source
// directory as Vite's root, so opt in to cleaning these known, scoped outputs.
export default {
  build: {
    emptyOutDir: true,
  },
  server: {
    watch: {
      // Large decks (slides.md > 64K chars) may be saved by the editor in
      // several write() calls. Without this, the watcher fires after the first
      // chunk, Slidev parses a truncated slides.md, the cut-off slide fails to
      // compile ("Element is missing end tag") and the edit is not applied.
      awaitWriteFinish: {
        stabilityThreshold: 500,
        pollInterval: 50,
      },
    },
  },
}
