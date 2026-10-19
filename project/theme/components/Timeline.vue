<script setup>
/**
 * Timeline — horizontal timeline; entries alternate above and below the axis.
 *
 * Usage in slides.md:
 *   <Timeline
 *     :items="[
 *       { year: '1971', head: 'Unix V1', text: 'файл /etc/passwd' },
 *       { year: '1988', head: 'Червь Морриса', text: 'атака по словарю', hot: true },
 *     ]"
 *     height="15em"
 *   />
 *
 * Item: { year, head?, text?, hot? }. `hot` highlights the dot and the year.
 */
defineProps({
  items: { type: Array, required: true },
  /** CSS height of the diagram (labels live above and below the axis). */
  height: { type: String, default: '15em' },
  /** CSS font-size of the whole diagram. */
  size: { type: String, default: '' },
})
</script>

<template>
  <div class="timeline" :style="{ height, ...(size ? { fontSize: size } : {}) }">
    <div class="tl-axis" />
    <div
      v-for="(it, i) in items" :key="i"
      class="tl-item" :class="i % 2 === 0 ? 'tl-up' : 'tl-down'"
    >
      <div class="tl-dot" :class="{ 'tl-hot': it.hot }" />
      <div class="tl-conn" />
      <div class="tl-card">
        <div class="tl-year" :class="{ 'tl-year-hot': it.hot }">{{ it.year }}</div>
        <div v-if="it.head" class="tl-head">{{ it.head }}</div>
        <div v-if="it.text" class="tl-text">{{ it.text }}</div>
      </div>
    </div>
  </div>
</template>
