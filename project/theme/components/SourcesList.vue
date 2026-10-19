<script setup>
import { computed } from 'vue'
import { refState, sources } from '../composables/sources'

/**
 * SourcesList — the numbered reference list for the «Источники» slide(s),
 * fed by the deck's `sources.json`. A click on `[n]` in a slide's Refs
 * footer navigates here and highlights the cited entry.
 *
 *   <SourcesList />            — all sources, two columns
 *   <SourcesList :from="1" :to="9" :cols="1" />
 */
const props = defineProps({
  /** 1-based range to show (for lists split across slides). */
  from: { type: Number, default: 1 },
  to: { type: Number, default: 0 },
  cols: { type: Number, default: 2 },
})

const items = computed(() => {
  const end = props.to > 0 ? props.to : sources.length
  return sources.slice(props.from - 1, end).map((s, i) => ({ ...s, n: props.from + i }))
})
</script>

<template>
  <div class="sources-list" :style="{ columnCount: cols }">
    <div
      v-for="s in items"
      :key="s.id"
      class="src-item"
      :class="{ 'src-active': refState.active === s.id }"
    >
      <span class="src-num">[{{ s.n }}]</span>
      <span class="src-text">
        <a v-if="s.url" :href="s.url" target="_blank" rel="noreferrer">{{ s.text }}</a>
        <template v-else>{{ s.text }}</template>
      </span>
    </div>
  </div>
</template>
