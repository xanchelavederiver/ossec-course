<script setup>
import { computed } from 'vue'

/**
 * Rfc — an IETF RFC mention that is also a link:
 *   <Rfc n="4511" />   → rfc-editor.org/rfc/rfc4511
 *   <Rfc n="86.0" href="http://www.opengroup.org/rfc/mirror-rfc/rfc86.0.txt" />
 *
 * Renders the conventional «RFC <n>» label, so it reads like the plain-text
 * mention it replaces (same convention as <Man/> and <MitreAttack/>).
 */
const props = defineProps({
  /** RFC number as written in text, e.g. "4511". */
  n: { type: String, required: true },
  /** Explicit URL override (e.g. an OSF RFC not hosted by the RFC Editor). */
  href: { type: String, default: '' },
})

const url = computed(() => {
  if (props.href)
    return props.href
  if (!/^\d+$/.test(props.n))
    return null
  return `https://www.rfc-editor.org/rfc/rfc${props.n}`
})
</script>

<template>
  <a v-if="url" class="rfc-link" :href="url" target="_blank" rel="noreferrer">RFC&nbsp;{{ n }}</a>
  <span v-else>RFC&nbsp;{{ n }}</span>
</template>
