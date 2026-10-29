<script setup>
import { computed } from 'vue'
import { useNav } from '@slidev/client'
import { refState, sourceIndex } from '../composables/sources'

/**
 * Refs — the per-slide references footer: «Источники: [3], [7]».
 *
 * Numbers come from the deck's `sources.json` (see composables/sources.js).
 * Each `[n]` is clickable: it jumps to the slide with `routeAlias: refs`
 * and highlights the cited source there (SourcesList reacts to the shared
 * state). Place once per slide, demo slides go without it:
 *   <Refs ids="man-credentials debian-policy" />
 */
const props = defineProps({
  /** Source ids: space/comma-separated string or an array. */
  ids: { type: [String, Array], required: true },
})

const list = computed(() => {
  const raw = Array.isArray(props.ids) ? props.ids : String(props.ids).split(/[\s,]+/)
  return raw.filter(Boolean).sort((a, b) => (sourceIndex.get(a) ?? 999) - (sourceIndex.get(b) ?? 999))
})

const nav = useNav()
// A long list may be split across slides: the first carries `routeAlias: refs`,
// continuations use `routeAlias: refs2`, `refs3`, … plus `refsFrom: <n>` — the
// first source number shown there. A click lands on the slide holding `[n]`.
const refsPages = computed(() =>
  nav.slides.value
    .filter(s => /^refs\d*$/.test(String(s.meta?.slide?.frontmatter?.routeAlias ?? '')))
    .map(s => ({ no: s.no, from: Number(s.meta?.slide?.frontmatter?.refsFrom ?? 1) }))
    .sort((a, b) => a.from - b.from),
)

function goTo(id) {
  refState.active = id
  const n = sourceIndex.get(id) ?? 1
  let target = null
  for (const p of refsPages.value) {
    if (n >= p.from || target === null)
      target = p
  }
  if (target)
    nav.go(target.no)
}
</script>

<template>
  <div class="slide-refs">
    <span class="sr-label">Источники:</span>
    <a
      v-for="id in list"
      :key="id"
      class="sr-link"
      :title="id"
      @click.prevent="goTo(id)"
    >[{{ sourceIndex.get(id) ?? '?' }}]</a>
  </div>
</template>
