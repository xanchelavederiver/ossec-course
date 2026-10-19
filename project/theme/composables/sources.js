import { reactive } from 'vue'

/**
 * Per-deck source registry for the Refs / SourcesList components.
 *
 * Each lecture keeps a `sources.json` next to its `slides.md`: an ordered
 * array of `{ id, text, url? }`. The order defines the `[n]` numbering on
 * slides and on the references slide. Slidev's Vite root is the lecture
 * directory, so the root-relative glob below resolves to the sources of the
 * deck being served.
 */
const modules = import.meta.glob('/sources.json', { import: 'default', eager: true })

export const sources = Object.values(modules)[0] ?? []

/** id -> 1-based number used in `[n]` references. */
export const sourceIndex = new Map(sources.map((s, i) => [s.id, i + 1]))

/** Shared state: the source highlighted on the references slide. */
export const refState = reactive({ active: null })
