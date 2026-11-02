<script setup>
import { computed } from 'vue'

/**
 * Cve — a CVE identifier that is also a link to the CVE Program record:
 *   <Cve c="CVE-2015-0235" />  → cve.org/CVERecord?id=CVE-2015-0235
 *
 * Renders the identifier as written, so it reads like the plain-text mention
 * it replaces (same convention as <Man/>, <MitreAttack/> and <Rfc/>).
 */
const props = defineProps({
  /** The identifier as written in text, e.g. "CVE-2015-0235". */
  c: { type: String, required: true },
  /** Explicit URL override (e.g. a vendor advisory). */
  href: { type: String, default: '' },
})

const url = computed(() => {
  if (props.href)
    return props.href
  if (!/^CVE-\d{4}-\d{4,}$/.test(props.c))
    return null
  return `https://www.cve.org/CVERecord?id=${props.c}`
})
</script>

<template>
  <a v-if="url" class="cve-link" :href="url" target="_blank" rel="noreferrer">{{ c }}</a>
  <span v-else>{{ c }}</span>
</template>
