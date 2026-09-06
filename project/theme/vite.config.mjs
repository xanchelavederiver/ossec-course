// Lecture sources live below `materials/`, while their generated artifacts are
// collected in the project-level `dist/` directory. Slidev uses the source
// directory as Vite's root, so opt in to cleaning these known, scoped outputs.
export default {
  build: {
    emptyOutDir: true,
  },
}
