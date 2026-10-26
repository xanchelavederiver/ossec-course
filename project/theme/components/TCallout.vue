<script setup>
import { computed, inject, onBeforeUnmount } from 'vue'

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
  /**
   * Corner of the numbered badge: tr | br | tl | bl. Empty (default) = auto:
   * top-right, flipped to bottom-right when another numbered box occupies the
   * line directly above and the badge would land on it.
   */
  badge: { type: String, default: '' },
  /** Accent colour of the marker and label border. */
  color: { type: String, default: 'var(--tc-callout)' },
})

// Numbered boxes of the same TerminalCapture register themselves, so each
// badge can detect a neighbour on the adjacent line and dodge it.
const registry = inject('tc-callout-registry', null)
const me = { line: props.line, rows: props.rows, col: props.col, span: props.span }
if (registry && props.n > 0 && props.span > 0)
  registry.push(me)
onBeforeUnmount(() => {
  if (!registry)
    return
  const i = registry.indexOf(me)
  if (i >= 0)
    registry.splice(i, 1)
})

/** True when a sibling box covers the given line within the badge's x-zone. */
function badgeCollides(atLine) {
  if (!registry)
    return false
  // The ball sits on the box's right corner: roughly the last two cells of
  // the region and one cell beyond it.
  const x1 = props.col + props.span - 2
  const x2 = props.col + props.span + 1
  return registry.some(o =>
    o !== me
    && atLine >= o.line && atLine <= o.line + (o.rows || 1) - 1
    && o.col <= x2 && o.col + o.span - 1 >= x1)
}

const badgeSide = computed(() => {
  if (props.badge)
    return props.badge
  return badgeCollides(props.line - 1) ? 'br' : 'tr'
})

const gutterCh = inject('tc-gutter-ch', computed(() => 0))

const rootStyle = computed(() => ({
  // --tc-pad-y: the transcript's top padding; absolute offsets inside the
  // overlay don't include it, so without the term every marker sits high.
  'top': `calc(var(--tc-pad-y) + ${props.line - 1} * var(--tc-lh))`,
  'left': `calc(var(--tc-pad-x) + ${gutterCh.value + props.col - 1}ch)`,
  '--tcc': props.color,
}))

const boxStyle = computed(() => ({
  width: props.span > 0 ? `${props.span}ch` : '0.75em',
  // Slightly thinner than the covered line boxes: the frame hugs the glyphs
  // and boxes on adjacent lines don't touch (centering is done in CSS).
  height: `calc(${props.rows} * var(--tc-lh) - 0.3em)`,
}))
</script>

<template>
  <div v-if="n > 0" class="t-callout t-callout-num" :style="rootStyle">
    <div v-if="span > 0" class="t-callout-box" :style="boxStyle" />
    <span class="co-ball" :class="span > 0 ? ['co-ball-tag', `co-ball-tag-${badgeSide}`] : []">{{ n }}</span>
  </div>
  <div v-else class="t-callout" :class="[`t-callout-${side}`, `t-callout-${kind}`]" :style="rootStyle">
    <div class="t-callout-box" :style="boxStyle" />
    <div class="t-callout-label">
      <slot>{{ label }}</slot>
    </div>
  </div>
</template>
