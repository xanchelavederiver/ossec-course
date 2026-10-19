<script setup>
/**
 * HistoryNote — the course's one style for historical asides: a dashed frame
 * with an «Исторический экскурс» label. Content goes into the default slot.
 *
 * Usage in slides.md:
 *   <HistoryNote>
 *   Сначала хэши хранились прямо в общедоступном <code>/etc/passwd</code>…
 *   </HistoryNote>
 */
defineProps({
  label: { type: String, default: 'Исторический экскурс' },
})
</script>

<template>
  <div class="history-note">
    <div class="hn-label">{{ label }}</div>
    <div class="hn-body"><slot /></div>
  </div>
</template>
