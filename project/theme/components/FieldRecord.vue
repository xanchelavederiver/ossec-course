<script setup>
import { computed } from 'vue'

/**
 * FieldRecord — a separated record (an /etc/passwd or /etc/shadow line, a hash
 * string) split into field boxes with numbered badges and an optional legend.
 *
 * Usage in slides.md:
 *   <FieldRecord
 *     :fields="['bob', { t: 'x', hot: true }, '1001', '1001', '', '/home/bob', '/bin/bash']"
 *     :legend="['имя для входа', { t: 'признак наличия пароля', hot: true }, 'UID', ...]"
 *     :cols="2"
 *   />
 *
 * Field: string or { t, hot?, label? }. An empty t renders a dashed empty box.
 * `label` puts a caption under the box (hash-format breakdowns; use sep="").
 * Legend items are laid out column-wise and support `code`, **bold**, *italic*.
 * Numbers show automatically when a legend is given (force with :numbers).
 */
const props = defineProps({
  fields: { type: Array, required: true },
  /** Separator between boxes; "" for adjacent boxes (hash parts). */
  sep: { type: String, default: ':' },
  legend: { type: Array, default: () => [] },
  /** Legend columns. */
  cols: { type: Number, default: 2 },
  numbers: { type: Boolean, default: undefined },
  /** CSS font-size of the record boxes, e.g. "1.1em". */
  size: { type: String, default: '' },
  /** CSS font-size of the legend, e.g. "0.8em". */
  legendSize: { type: String, default: '' },
})

const items = computed(() =>
  props.fields.map(f => (typeof f === 'string' ? { t: f } : f)))
const legendItems = computed(() =>
  props.legend.map(l => (typeof l === 'string' ? { t: l } : l)))
const showNums = computed(() =>
  props.numbers !== undefined ? props.numbers : legendItems.value.length > 0)

const legendStyle = computed(() => {
  const rows = Math.ceil(legendItems.value.length / props.cols)
  return {
    gridTemplateRows: `repeat(${rows}, auto)`,
    gridTemplateColumns: `repeat(${props.cols}, minmax(0, 1fr))`,
    gridAutoFlow: 'column',
    ...(props.legendSize ? { fontSize: props.legendSize } : {}),
  }
})

/** `code`, **bold**, *italic* -> runs for the legend/labels. */
function runs(str) {
  const out = []
  const re = /(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)/g
  let last = 0
  for (let m = re.exec(str); m; m = re.exec(str)) {
    if (m.index > last)
      out.push({ t: str.slice(last, m.index) })
    const tok = m[0]
    if (tok.startsWith('**'))
      out.push({ t: tok.slice(2, -2), b: true })
    else if (tok.startsWith('`'))
      out.push({ t: tok.slice(1, -1), c: true })
    else
      out.push({ t: tok.slice(1, -1), i: true })
    last = m.index + tok.length
  }
  if (last < str.length)
    out.push({ t: str.slice(last) })
  return out
}
</script>

<template>
  <div class="field-record">
    <div class="fr-row" :style="size ? { fontSize: size } : {}">
      <template v-for="(f, i) in items" :key="i">
        <div class="fr-cell">
          <div v-if="showNums" class="fr-num" :class="{ 'fr-hot': f.hot }">{{ i + 1 }}</div>
          <div class="fr-box" :class="{ 'fr-hot-box': f.hot, 'fr-empty': !f.t }">{{ f.t || ' ' }}</div>
          <div v-if="f.label" class="fr-under">
            <template v-for="(r, k) in runs(f.label)" :key="k">
              <code v-if="r.c">{{ r.t }}</code><b v-else-if="r.b">{{ r.t }}</b><i v-else-if="r.i">{{ r.t }}</i><template v-else>{{ r.t }}</template>
            </template>
          </div>
        </div>
        <div v-if="sep && i < items.length - 1" class="fr-cell">
          <div v-if="showNums" class="fr-num fr-ghost">0</div>
          <div class="fr-sep">{{ sep }}</div>
        </div>
      </template>
    </div>
    <div v-if="legendItems.length" class="fr-legend" :style="legendStyle">
      <div v-for="(l, i) in legendItems" :key="i" class="fr-leg-item">
        <span class="fr-num" :class="{ 'fr-hot': l.hot }">{{ i + 1 }}</span>
        <span class="fr-leg-text">
          <template v-for="(r, k) in runs(l.t)" :key="k">
            <code v-if="r.c">{{ r.t }}</code><b v-else-if="r.b">{{ r.t }}</b><i v-else-if="r.i">{{ r.t }}</i><template v-else>{{ r.t }}</template>
          </template>
        </span>
      </div>
    </div>
  </div>
</template>
