<script setup>
import { computed } from 'vue'

/**
 * DebianMan — a man-page reference hosted on manpages.debian.org, for pages that
 * exist only in Debian/Ubuntu (adduser(8), addgroup(8), adduser.conf(5), …) and
 * therefore are absent from man7.org, where <Man> points.
 *
 *   <DebianMan p="adduser(8)" />                 → manpages.debian.org/stable/adduser/adduser.8.en.html
 *   <DebianMan p="adduser.conf(5)" pkg="adduser" />
 *
 * The URL is manpages.debian.org/<release>/<package>/<name>.<section>.<lang>.html;
 * the package defaults to the page name without its extension (adduser.conf → adduser),
 * which is correct for the adduser family. Styled exactly like <Man>.
 */
const props = defineProps({
  /** The reference as written in text, e.g. "adduser(8)". */
  p: { type: String, required: true },
  /** Debian package owning the page; defaults to the page name's first component. */
  pkg: { type: String, default: '' },
  /** Debian release the manpage is taken from. */
  release: { type: String, default: 'stable' },
  /** Manpage language suffix. */
  lang: { type: String, default: 'en' },
  /** Explicit URL, bypassing the generated one. */
  href: { type: String, default: '' },
})

const url = computed(() => {
  if (props.href)
    return props.href
  const m = props.p.match(/^(.+)\((\w+)\)$/)
  if (!m)
    return null
  const [, name, section] = m
  const pkg = props.pkg || name.split('.')[0]
  return `https://manpages.debian.org/${props.release}/${pkg}/${name}.${section}.${props.lang}.html`
})
</script>

<template>
  <a v-if="url" class="man-link" :href="url" target="_blank" rel="noreferrer"><code>{{ p }}</code></a>
  <code v-else>{{ p }}</code>
</template>
