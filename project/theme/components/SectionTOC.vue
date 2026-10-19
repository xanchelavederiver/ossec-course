<script setup>
/**
 * SectionTOC — the subsection list on a section title slide. The upcoming
 * subsection is highlighted, the rest are greyed out; the same slide is
 * repeated before each subsection with `current` advanced:
 *
 *   <SectionTOC prefix="2" :current="1" :items="[
 *     'Субъекты и объекты',
 *     'Файл паролей <code>/etc/passwd</code>',
 *   ]" />
 */
defineProps({
  /** Subsection titles (inline HTML allowed, e.g. <code>). */
  items: { type: Array, required: true },
  /** 1-based index of the highlighted subsection. */
  current: { type: Number, default: 1 },
  /** Section number: prefix="2" renders 2.1, 2.2, … */
  prefix: { type: String, default: '' },
})
</script>

<template>
  <div class="section-toc">
    <div
      v-for="(it, i) in items"
      :key="i"
      class="st-item"
      :class="i + 1 === current ? 'st-current' : 'st-dim'"
    >
      <span class="st-num">{{ prefix ? `${prefix}.${i + 1}` : i + 1 }}</span>
      <!-- eslint-disable-next-line vue/no-v-html — titles are deck-authored -->
      <span class="st-text" v-html="it" />
    </div>
  </div>
</template>
