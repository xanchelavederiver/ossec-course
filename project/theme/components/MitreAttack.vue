<script setup>
import { computed } from 'vue'

/**
 * MitreAttack — a MITRE ATT&CK technique mention that is also a link:
 *   <MitreAttack t="T1087" />      → attack.mitre.org/techniques/T1087/
 *   <MitreAttack t="T1546.004" />  → attack.mitre.org/techniques/T1546/004/
 *
 * Renders the conventional bold «MITRE ATT&CK <id>» label, so it reads like
 * the plain-text mention it replaces (same convention as <Man/> for man pages).
 */
const props = defineProps({
  /** Technique id as written in text, e.g. "T1087" or "T1546.004". */
  t: { type: String, required: true },
  /** Explicit URL override (e.g. a tactic or mitigation page). */
  href: { type: String, default: '' },
})

const url = computed(() => {
  if (props.href)
    return props.href
  const m = props.t.match(/^(TA?\d+)(?:\.(\d+))?$/)
  if (!m)
    return null
  const base = m[1].startsWith('TA')
    ? `https://attack.mitre.org/tactics/${m[1]}/`
    : `https://attack.mitre.org/techniques/${m[1]}/`
  return m[2] ? `${base}${m[2]}/` : base
})
</script>

<template>
  <a v-if="url" class="attack-link" :href="url" target="_blank" rel="noreferrer"><b>MITRE ATT&amp;CK {{ t }}</b></a>
  <b v-else>MITRE ATT&amp;CK {{ t }}</b>
</template>
