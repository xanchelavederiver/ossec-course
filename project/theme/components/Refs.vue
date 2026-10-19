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
const refsPage = computed(() =>
  nav.slides.value.find(s => s.meta?.slide?.frontmatter?.routeAlias === 'refs')?.no,
)

function goTo(id) {
  refState.active = id
  if (refsPage.value)
    nav.go(refsPage.value)
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
