<script setup>
import { computed, provide, reactive } from 'vue'

/**
 * CodeSnippet — renders a source-code excerpt (kernel, libc, demo sources)
 * with controllable line numbering and the course's callout machinery.
 *
 * Snippet files live in `materials/lectures/<topic>/<lecture>/assets/snippets/`
 * and hold verbatim excerpts of the original file. A marker line of the form
 *   @@ <n>    — following lines carry original file numbers starting at <n>;
 *               at the top of the snippet it only sets the numbering, elsewhere
 *               it also renders an ellipsis row («⋯», skipped lines);
 *   @@        — plain ellipsis row, numbering continues uninterrupted.
 * Without markers the numbering is sequential from 1 (`:numbers="false"` hides
 * the gutter entirely). Ellipsis rows count as rows for TCallout coordinates.
 *
 * Usage in slides.md:
 *   <CodeSnippet src="snippets/cred-struct.h" title="include/linux/cred.h">
 *     <TCallout :line="3" :col="17" :span="4" :n="1" />
 *   </CodeSnippet>
 *
 * Callouts are the same as in TerminalCapture: asciidoctor-style numbered
 * balls (`:n` without `:span`) and the project's numbered highlight boxes
 * (`:n` + `:span`); coordinates are 1-based rows/cells of the shown excerpt.
 */
const props = defineProps({
  /** Suffix of the snippet file path, e.g. "snippets/cred-struct.h". */
  src: { type: String, default: '' },
  /** Inline code (alternative to src); supports the same @@ markers. */
  code: { type: String, default: '' },
  /** Language for highlighting: "c" / "cpp" (others render unhighlighted). */
  lang: { type: String, default: 'c' },
  /** Title shown in the window bar; defaults to the snippet file name. */
  title: { type: String, default: '' },
  /** Muted tag at the right of the title bar, e.g. "Linux v6.18". */
  tag: { type: String, default: '' },
  /** Hide the window title bar. */
  plain: { type: Boolean, default: false },
  /** Show the line-number gutter. */
  numbers: { type: Boolean, default: true },
  /** Rows to emphasise, e.g. "2,5-7" (1-based rows of the shown excerpt). */
  highlight: { type: String, default: '' },
  /** CSS max-height of the scrollable body, e.g. "280px". */
  maxHeight: { type: String, default: '' },
  /** CSS font-size override for the code. */
  fontSize: { type: String, default: '' },
  /** Extra bottom padding, e.g. "2.2em" — room for labels below the last line. */
  padBottom: { type: String, default: '' },
  /** Tab stop width in cells (kernel sources use 8). */
  tabSize: { type: Number, default: 8 },
})

// Every snippet of every lecture; tiny text files, so eager import is fine.
const snippetModules = import.meta.glob(
  '../../materials/lectures/*/*/assets/snippets/*',
  { query: '?raw', import: 'default', eager: true },
)

// Snippets of the running deck (Slidev's Vite root is the deck directory),
// preferred over the cross-deck glob — same rule as TerminalCapture.
const deckSnippets = import.meta.glob(
  '/assets/snippets/*',
  { query: '?raw', import: 'default', eager: true },
)

const rawText = computed(() => {
  if (props.code)
    return props.code
  if (!props.src)
    return '[CodeSnippet: укажите src или code]'
  const wanted = props.src.replace(/^\.?\//, '')
  const own = Object.keys(deckSnippets).filter(k => k.endsWith(wanted))
  if (own.length === 1)
    return deckSnippets[own[0]]
  const keys = Object.keys(snippetModules).filter(k => k.endsWith(wanted))
  if (keys.length === 1)
    return snippetModules[keys[0]]
  if (keys.length === 0)
    return `[CodeSnippet: файл "${wanted}" не найден в assets/snippets]`
  return `[CodeSnippet: "${wanted}" неоднозначен: ${keys.join(', ')}]`
})

const MARKER_RE = /^@@(?:\s+(\d+))?\s*$/

/** Rows of the excerpt: code lines with their numbers, and ellipsis rows. */
const rows = computed(() => {
  const out = []
  let num = 1
  let first = true
  for (const line of rawText.value.replace(/\r\n/g, '\n').replace(/\n$/, '').split('\n')) {
    const m = line.match(MARKER_RE)
    if (m) {
      if (m[1] != null) {
        if (!first)
          out.push({ skip: true })
        num = Number(m[1])
      }
      else {
        out.push({ skip: true })
      }
      first = false
      continue
    }
    out.push({ text: expandTabs(line, props.tabSize), num })
    num += 1
    first = false
  }
  return out
})

function expandTabs(s, tab) {
  if (!s.includes('\t'))
    return s
  let out = ''
  for (const ch of s) {
    if (ch === '\t')
      out += ' '.repeat(tab - (out.length % tab))
    else
      out += ch
  }
  return out
}

/* ---------- C / C++ tokenizer ---------- */

const C_KEYWORDS = new Set([
  'auto', 'break', 'case', 'const', 'continue', 'default', 'do', 'else',
  'enum', 'extern', 'for', 'goto', 'if', 'inline', 'register', 'restrict',
  'return', 'sizeof', 'static', 'struct', 'switch', 'typedef', 'typeof',
  'union', 'volatile', 'while', '_Bool', '_Static_assert',
  // C++ additions — enough for occasional C++ snippets
  'class', 'namespace', 'template', 'typename', 'public', 'private',
  'protected', 'virtual', 'operator', 'new', 'delete', 'this', 'using',
  'constexpr', 'noexcept', 'nullptr', 'true', 'false',
])

const C_TYPES = new Set([
  'void', 'char', 'short', 'int', 'long', 'float', 'double', 'signed',
  'unsigned', 'bool', 'u8', 'u16', 'u32', 'u64', 's8', 's16', 's32', 's64',
])

const C_TOKEN_RE = /\/\*|\/\/.*$|"(?:[^"\\]|\\.)*(?:"|$)|'(?:[^'\\]|\\.)*(?:'|$)|0[xX][0-9a-fA-F]+[uUlL]*|\d+[uUlL]*|[A-Za-z_]\w*|\s+|./g

/** Line-by-line C tokenizer with block-comment and macro-continuation state. */
function tokenizeC(lines) {
  let inComment = false
  let inMacro = false
  return lines.map((row) => {
    if (row.skip)
      return row
    const line = row.text
    const segs = []
    const push = (text, cls) => {
      if (!text)
        return
      const last = segs[segs.length - 1]
      if (last && last.cls === cls)
        last.text += text
      else
        segs.push({ text, cls })
    }
    let i = 0
    if (inComment) {
      const end = line.indexOf('*/')
      if (end < 0) {
        push(line || ' ', 'cs-com')
        return { ...row, segs }
      }
      push(line.slice(0, end + 2), 'cs-com')
      i = end + 2
      inComment = false
    }
    const rest = line.slice(i)
    const mPre = !inMacro && rest.match(/^(\s*)(#\s*\w+)/)
    let pos = i
    if (mPre) {
      push(mPre[1], '')
      push(mPre[2], 'cs-pre')
      pos = i + mPre[0].length
    }
    const tail = line.slice(pos)
    let prevWord = ''
    // exec-loop (not matchAll): skipping a /*…*/ needs a writable lastIndex.
    const re = new RegExp(C_TOKEN_RE.source, 'g')
    let m
    // eslint-disable-next-line no-cond-assign
    while ((m = re.exec(tail))) {
      const t = m[0]
      if (t === '/*') {
        const end = tail.indexOf('*/', m.index + 2)
        if (end < 0) {
          push(tail.slice(m.index), 'cs-com')
          inComment = true
          break
        }
        push(tail.slice(m.index, end + 2), 'cs-com')
        re.lastIndex = end + 2
        continue
      }
      if (t.startsWith('//')) {
        push(t, 'cs-com')
        break
      }
      if (t[0] === '"' || t[0] === '\'') {
        push(t, 'cs-str')
        prevWord = ''
        continue
      }
      if (/^\d/.test(t)) {
        push(t, 'cs-numlit')
        prevWord = ''
        continue
      }
      if (/^[A-Za-z_]/.test(t)) {
        let cls = ''
        if (C_KEYWORDS.has(t))
          cls = 'cs-kw'
        else if (C_TYPES.has(t) || /_t$/.test(t) || prevWord === 'struct' || prevWord === 'union' || prevWord === 'enum')
          cls = 'cs-type'
        else if (/^[A-Z][A-Z0-9_]+$/.test(t))
          cls = 'cs-const'
        else if (tail.slice(m.index + t.length).match(/^\s*\(/))
          cls = 'cs-fn'
        push(t, cls)
        prevWord = t
        continue
      }
      if (/^\s+$/.test(t)) {
        push(t, '')
        continue
      }
      push(t, t === '\\' && m.index + 1 === tail.length ? 'cs-pre' : '')
      prevWord = ''
    }
    inMacro = (mPre || inMacro) && line.endsWith('\\')
    if (!segs.length)
      segs.push({ text: ' ', cls: '' })
    return { ...row, segs }
  })
}

const renderedRows = computed(() => {
  if (props.lang === 'c' || props.lang === 'cpp')
    return tokenizeC(rows.value)
  return rows.value.map(r => r.skip ? r : { ...r, segs: [{ text: r.text || ' ', cls: '' }] })
})

function parseRanges(spec) {
  const set = new Set()
  for (const part of String(spec).split(',')) {
    const m = part.trim().match(/^(\d+)(?:-(\d+))?$/)
    if (!m)
      continue
    for (let i = Number(m[1]); i <= Number(m[2] ?? m[1]); i++)
      set.add(i)
  }
  return set
}

const hlSet = computed(() => props.highlight ? parseRanges(props.highlight) : new Set())

const displayTitle = computed(() =>
  props.title || (props.src ? props.src.split('/').pop() : 'code'),
)

const numWidth = computed(() => {
  let max = 1
  for (const r of rows.value) {
    if (!r.skip && r.num > max)
      max = r.num
  }
  return String(max).length
})

// Gutter width in ch for TCallout x-offsets: digits + 2 (right margin).
const gutterCh = computed(() => props.numbers ? numWidth.value + 2 : 0)
provide('tc-gutter-ch', gutterCh)

// Same registry contract as TerminalCapture: numbered TCallout boxes dodge
// a neighbouring box on the adjacent line.
provide('tc-callout-registry', reactive([]))

const bodyStyle = computed(() => props.maxHeight ? { maxHeight: props.maxHeight } : {})
const rootStyle = computed(() => props.fontSize ? { fontSize: props.fontSize } : {})
const innerStyle = computed(() => props.padBottom ? { paddingBottom: props.padBottom } : {})
const numStyle = computed(() => ({ width: `${numWidth.value}ch` }))
</script>

<template>
  <div class="code-snippet" :style="rootStyle">
    <div v-if="!plain" class="cs-titlebar">
      <span class="cs-glyph">‹/›</span>
      <span class="cs-title">{{ displayTitle }}</span>
      <span v-if="tag" class="cs-tag">{{ tag }}</span>
    </div>
    <div class="tc-body" :style="bodyStyle">
      <div class="tc-inner" :style="innerStyle">
        <div class="tc-pre cs-pre-block">
          <div
            v-for="(row, i) in renderedRows"
            :key="i"
            class="tc-line"
            :class="{ 'tc-hl': hlSet.has(i + 1), 'cs-skip': row.skip }"
          >
            <template v-if="row.skip">
              <span v-if="numbers" class="cs-num" :style="numStyle"> </span><span class="cs-ellipsis">⋯</span>
            </template>
            <template v-else>
              <span v-if="numbers" class="cs-num" :style="numStyle">{{ row.num }}</span><span
                v-for="(seg, j) in row.segs"
                :key="j"
                :class="seg.cls"
              >{{ seg.text }}</span>
            </template>
          </div>
        </div>
        <div class="tc-overlay">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>
