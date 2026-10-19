<script setup>
import { computed } from 'vue'

/**
 * BlockFlow — horizontal scheme of blocks connected by arrows
 * (the block-and-arrow diagrams of the course decks).
 *
 * Usage in slides.md:
 *   <BlockFlow
 *     :blocks="[
 *       { head: 'Субъект', sub: 'процесс с UID и GID' },
 *       { head: 'Монитор обращений', fill: 'dark', sub: 'разрешено ли действие?' },
 *       { head: 'Объект', sub: 'файл, устройство, память' },
 *     ]"
 *     :arrows="['обращение', { label: 'разрешено', color: '#2e7d5b' }]"
 *   />
 *
 * Block: string or { head, q?, sub?, mono?, fill?, flex? }
 *   q    — accent line under the head (amber, bold);
 *   fill — 'tint' (default) | 'dark' | 'accent' | 'amber' | 'green' | 'red';
 *   sub  — supports line breaks via \n.
 * Arrow i sits between blocks i and i+1: true/string label or { label, color }.
 */
const props = defineProps({
  blocks: { type: Array, required: true },
  arrows: { type: Array, default: () => [] },
  /** CSS font-size of the whole scheme, e.g. "0.9em". */
  size: { type: String, default: '' },
})

const items = computed(() =>
  props.blocks.map(b => (typeof b === 'string' ? { head: b } : b)))

function arrowAt(i) {
  const a = props.arrows[i]
  if (a == null || a === true)
    return {}
  return typeof a === 'string' ? { label: a } : a
}
</script>

<template>
  <div class="block-flow" :style="size ? { fontSize: size } : {}">
    <template v-for="(b, i) in items" :key="i">
      <div
        class="bf-block" :class="`bf-fill-${b.fill || 'tint'}`"
        :style="b.flex ? { flex: b.flex } : {}"
      >
        <div class="bf-head" :class="{ 'bf-mono': b.mono }">{{ b.head }}</div>
        <div v-if="b.q" class="bf-q">{{ b.q }}</div>
        <div v-if="b.sub" class="bf-sub">{{ b.sub }}</div>
      </div>
      <div
        v-if="i < items.length - 1"
        class="bf-arrow"
        :style="arrowAt(i).color ? { '--bf-arrow': arrowAt(i).color } : {}"
      >
        <div v-if="arrowAt(i).label" class="bf-arrow-label">{{ arrowAt(i).label }}</div>
        <div class="bf-arrow-line" />
        <div class="bf-arrow-tip" />
      </div>
    </template>
  </div>
</template>
