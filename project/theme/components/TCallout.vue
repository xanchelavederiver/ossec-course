<script setup>
import { computed, inject } from 'vue'

/**
 * TCallout — positioned annotation inside a <TerminalCapture>.
 *
 * Coordinates are 1-based and refer to the *shown* fragment of the capture
 * (after `section`/`lines` filtering), counted in monospace cells.
 * Appears on click when the standard Slidev `v-click` directive is applied:
 *   <TCallout v-click :line="3" :col="7" :span="12" label="соль" />
 *
 * With `n` it renders a numbered callout — pair it with a legend list that
 * repeats the numbers (inline balls: <span class="co-ball">1</span>).
 * Together with `span` it localizes the point of interest inside the line:
 * a rounded rectangle around the region with the number badge on its corner,
 * the step-callout convention of screenshot-annotation tools:
 *   <TCallout :line="2" :col="15" :span="13" :n="1" />
 * Without `span` it is a plain asciidoctor-style ball at line/col.
 */
const props = defineProps({
  /** Line of the shown fragment, 1-based. */
  line: { type: Number, required: true },
  /** First column of the annotated region, 1-based. */
  col: { type: Number, default: 1 },
  /** Width of the annotated region in characters; 0 = point marker. */
  span: { type: Number, default: 0 },
  /** Additional lines covered by the box (multi-line region). */
  rows: { type: Number, default: 1 },
  /** Short explanation shown next to the marker (or use the default slot). */
  label: { type: String, default: '' },
  /** Side of the label relative to the box: right | left | top | bottom. */
  side: { type: String, default: 'right' },
  /** Marker form: box | underline | badge. */
  kind: { type: String, default: 'box' },
  /** Callout number: renders a numbered ball (asciidoctor style) at line/col. */
  n: { type: Number, default: 0 },
  /** Accent colour of the marker and label border. */
  color: { type: String, default: 'var(--tc-callout)' },
})

const gutterCh = inject('tc-gutter-ch', computed(() => 0))

const rootStyle = computed(() => ({
  'top': `calc(${props.line - 1} * var(--tc-lh))`,
  'left': `calc(var(--tc-pad-x) + ${gutterCh.value + props.col - 1}ch)`,
  '--tcc': props.color,
}))

const boxStyle = computed(() => ({
  width: props.span > 0 ? `${props.span}ch` : '0.75em',
  height: `calc(${props.rows} * var(--tc-lh))`,
}))
</script>

<template>
  <div v-if="n > 0" class="t-callout t-callout-num" :style="rootStyle">
    <div v-if="span > 0" class="t-callout-box" :style="boxStyle" />
    <span class="co-ball" :class="{ 'co-ball-tag': span > 0 }">{{ n }}</span>
  </div>
  <div v-else class="t-callout" :class="[`t-callout-${side}`, `t-callout-${kind}`]" :style="rootStyle">
    <div class="t-callout-box" :style="boxStyle" />
    <div class="t-callout-label">
      <slot>{{ label }}</slot>
    </div>
  </div>
</template>
