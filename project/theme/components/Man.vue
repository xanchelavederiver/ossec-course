<script setup>
import { computed } from 'vue'

/**
 * Man — a man-page reference that is also a link:
 *   <Man p="capabilities(7)" />          → man7.org/linux/man-pages/man7/capabilities.7.html
 *   <Man p="sudoers(5)" href="https://www.sudo.ws/docs/man/sudoers.man/" />
 *
 * Styled as inline code, so it reads like the usual `name(section)` mention.
 */
const props = defineProps({
  /** The reference as written in text, e.g. "capabilities(7)". */
  p: { type: String, required: true },
  /** Explicit URL for pages not hosted on man7.org. */
  href: { type: String, default: '' },
})

const url = computed(() => {
  if (props.href)
    return props.href
  const m = props.p.match(/^(.+)\((\w+)\)$/)
  if (!m)
    return null
  return `https://man7.org/linux/man-pages/man${m[2][0]}/${m[1]}.${m[2]}.html`
})
</script>

<template>
  <a v-if="url" class="man-link" :href="url" target="_blank" rel="noreferrer"><code>{{ p }}</code></a>
  <code v-else>{{ p }}</code>
</template>
