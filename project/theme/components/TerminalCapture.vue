<script setup>
import { computed, provide } from 'vue'

/**
 * TerminalCapture — renders a captured terminal transcript on a slide.
 *
 * Capture files live in `materials/lectures/<topic>/<lecture>/assets/captures/`
 * and are plain transcripts (optionally with ANSI SGR colour codes) whose
 * sections are delimited by lines of the form `===== Section title =====`.
 *
 * Usage in slides.md:
 *   <TerminalCapture src="captures/04-shadow-password-policy.txt" section="6">
 *     <TCallout :line="2" :col="6" :span="34" label="yescrypt-хэш" side="bottom" />
 *   </TerminalCapture>
 */
const props = defineProps({
  /** Suffix of the capture file path, e.g. "captures/01-passwd-uid-zero.txt". */
  src: { type: String, default: '' },
  /** Inline transcript (alternative to src). */
  content: { type: String, default: '' },
  /** Section to show: 1-based index or a substring of its `===== title =====` header. */
  section: { type: [String, Number], default: null },
  /** Additionally restrict to a line range of the shown fragment, e.g. "3-12". */
  lines: { type: String, default: '' },
  /** Title shown in the window bar; defaults to the section header or file name. */
  title: { type: String, default: '' },
  /** Lines to emphasise, e.g. "2,5-7" (1-based within the shown fragment). */
  highlight: { type: String, default: '' },
  /** Show line numbers. */
  numbers: { type: Boolean, default: false },
  /** Wrap long lines (callout positioning assumes nowrap). */
  wrap: { type: Boolean, default: false },
  /** Hide the window title bar. */
  plain: { type: Boolean, default: false },
  /** CSS max-height of the scrollable body, e.g. "280px". */
  maxHeight: { type: String, default: '' },
  /** CSS font-size override for the transcript. */
  fontSize: { type: String, default: '' },
  /** Extra bottom padding, e.g. "2.2em" — room for labels below the last line. */
  padBottom: { type: String, default: '' },
  /**
   * Colour plain transcripts like a standard bash session: green "$ " /
   * red "# " prompt, bold command, muted trailing "# …" or "<-- …" comment.
   * Lines that carry their own ANSI SGR codes are rendered as recorded.
   */
  colorize: { type: Boolean, default: true },
})

// Every capture of every lecture; tiny text files, so eager import is fine.
const captureModules = import.meta.glob(
  '../../materials/lectures/*/*/assets/captures/*',
  { query: '?raw', import: 'default', eager: true },
)

const SECTION_RE = /^\s*={3,}\s*(.*?)\s*={3,}\s*$/

const rawText = computed(() => {
  if (props.content)
    return props.content
  if (!props.src)
    return '[TerminalCapture: укажите src или content]'
  const wanted = props.src.replace(/^\.?\//, '')
  const keys = Object.keys(captureModules).filter(k => k.endsWith(wanted))
  if (keys.length === 1)
    return captureModules[keys[0]]
  if (keys.length === 0)
    return `[TerminalCapture: файл "${wanted}" не найден в assets/captures]`
  return `[TerminalCapture: "${wanted}" неоднозначен: ${keys.join(', ')}]`
})

/** Split the transcript into sections on `===== title =====` lines. */
const sections = computed(() => {
  const out = []
  let current = { title: '', lines: [] }
  for (const line of rawText.value.replace(/\r\n/g, '\n').split('\n')) {
    const m = line.match(SECTION_RE)
    if (m) {
      if (current.title || current.lines.some(l => l.trim()))
        out.push(current)
      current = { title: m[1], lines: [] }
    }
    else {
      current.lines.push(line)
    }
  }
  if (current.title || current.lines.some(l => l.trim()))
    out.push(current)
  return out
})

const picked = computed(() => {
  const secs = sections.value
  if (props.section == null || secs.length === 0) {
    return {
      title: '',
      lines: rawText.value.replace(/\r\n/g, '\n').split('\n'),
    }
  }
  let sec
  if (typeof props.section === 'number' || /^\d+$/.test(String(props.section)))
    sec = secs[Number(props.section) - 1]
  else
    sec = secs.find(s => s.title.toLowerCase().includes(String(props.section).toLowerCase()))
  return sec ?? { title: `[секция "${props.section}" не найдена]`, lines: [] }
})

function parseRanges(spec) {
  const set = new Set()
  for (const part of String(spec).split(',')) {
    const m = part.trim().match(/^(\d+)(?:-(\d+))?$/)
    if (!m)
      continue
    const a = Number(m[1])
    const b = m[2] ? Number(m[2]) : a
    for (let i = a; i <= b; i++)
      set.add(i)
  }
  return set
}

const shownLines = computed(() => {
  let lines = [...picked.value.lines]
  // Trim leading/trailing blank lines of the fragment.
  while (lines.length && !lines[0].trim())
    lines.shift()
  while (lines.length && !lines[lines.length - 1].trim())
    lines.pop()
  if (props.lines) {
    const keep = parseRanges(props.lines)
    lines = lines.filter((_, i) => keep.has(i + 1))
  }
  return lines
})

const hlSet = computed(() => props.highlight ? parseRanges(props.highlight) : new Set())

/* ---------- ANSI SGR -> styled segments ---------- */

const BASIC_FG = { 30: 0, 31: 1, 32: 2, 33: 3, 34: 4, 35: 5, 36: 6, 37: 7, 90: 8, 91: 9, 92: 10, 93: 11, 94: 12, 95: 13, 96: 14, 97: 15 }
const BASIC_BG = { 40: 0, 41: 1, 42: 2, 43: 3, 44: 4, 45: 5, 46: 6, 47: 7, 100: 8, 101: 9, 102: 10, 103: 11, 104: 12, 105: 13, 106: 14, 107: 15 }

function xterm256(n) {
  n = Number(n)
  if (n < 16)
    return null // handled via palette classes
  if (n >= 232) {
    const v = 8 + (n - 232) * 10
    return `rgb(${v},${v},${v})`
  }
  const idx = n - 16
  const lv = [0, 95, 135, 175, 215, 255]
  return `rgb(${lv[Math.floor(idx / 36)]},${lv[Math.floor(idx / 6) % 6]},${lv[idx % 6]})`
}

const parsedLines = computed(() => {
  const state = { bold: false, dim: false, italic: false, underline: false, invert: false, fg: null, bg: null, fgCss: null, bgCss: null }

  function applySGR(params) {
    const p = params.length ? params : ['0']
    for (let i = 0; i < p.length; i++) {
      const code = Number(p[i] || 0)
      if (code === 0)
        Object.assign(state, { bold: false, dim: false, italic: false, underline: false, invert: false, fg: null, bg: null, fgCss: null, bgCss: null })
      else if (code === 1) state.bold = true
      else if (code === 2) state.dim = true
      else if (code === 3) state.italic = true
      else if (code === 4) state.underline = true
      else if (code === 7) state.invert = true
      else if (code === 22) { state.bold = false; state.dim = false }
      else if (code === 23) state.italic = false
      else if (code === 24) state.underline = false
      else if (code === 27) state.invert = false
      else if (code === 39) { state.fg = null; state.fgCss = null }
      else if (code === 49) { state.bg = null; state.bgCss = null }
      else if (code in BASIC_FG) { state.fg = BASIC_FG[code]; state.fgCss = null }
      else if (code in BASIC_BG) { state.bg = BASIC_BG[code]; state.bgCss = null }
      else if (code === 38 || code === 48) {
        const isFg = code === 38
        if (p[i + 1] === '5') {
          const n = Number(p[i + 2]); i += 2
          if (n < 16) {
            if (isFg) { state.fg = n; state.fgCss = null }
            else { state.bg = n; state.bgCss = null }
          }
          else if (isFg) { state.fgCss = xterm256(n); state.fg = null }
          else { state.bgCss = xterm256(n); state.bg = null }
        }
        else if (p[i + 1] === '2') {
          const css = `rgb(${Number(p[i + 2])},${Number(p[i + 3])},${Number(p[i + 4])})`
          i += 4
          if (isFg) { state.fgCss = css; state.fg = null }
          else { state.bgCss = css; state.bg = null }
        }
      }
    }
  }

  function segmentStyle() {
    const cls = []
    if (state.bold) cls.push('tc-b')
    if (state.dim) cls.push('tc-dim')
    if (state.italic) cls.push('tc-i')
    if (state.underline) cls.push('tc-u')
    if (state.invert) cls.push('tc-inv')
    if (state.fg != null) cls.push(`tc-f${state.fg}`)
    if (state.bg != null) cls.push(`tc-g${state.bg}`)
    const style = {}
    if (state.fgCss) style.color = state.fgCss
    if (state.bgCss) style.backgroundColor = state.bgCss
    return { cls, style }
  }

  // A transcript without colour codes, shown as a standard bash session:
  // prompt + bold command (with an optional muted trailing comment), plain output.
  function colorizeLine(line) {
    const m = line.match(/^([\w.@~-]*[$#]) (.*)$/)
    if (!m)
      return [{ text: line || ' ', cls: [], style: {} }]
    const segs = [{ text: `${m[1]} `, cls: [m[1].endsWith('#') ? 'tc-prompt-r' : 'tc-prompt-u'], style: {} }]
    const rest = m[2]
    const cm = rest.match(/\s{2,}(?:#\s|<--).*$/)
    if (cm && cm.index > 0) {
      segs.push({ text: rest.slice(0, cm.index), cls: ['tc-cmd'], style: {} })
      segs.push({ text: rest.slice(cm.index), cls: ['tc-note'], style: {} })
    }
    else {
      segs.push({ text: rest || ' ', cls: ['tc-cmd'], style: {} })
    }
    return segs
  }

  return shownLines.value.map((line) => {
    // Carriage-return overwrite semantics: keep what the terminal would show.
    const visible = line.split('\r').pop() ?? ''
    const cleaned = visible
      .replace(/\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)/g, '') // OSC (window titles etc.)
      .replace(/\x1B\[[0-9;?]*[A-LN-Za-ln-z]/g, '')      // CSI other than SGR (m)
    if (props.colorize && !cleaned.includes('\x1B')) {
      let col = 0
      return colorizeLine(cleaned).map((seg) => {
        const text = expandTabsAt(seg.text, col)
        col += text.length
        return { ...seg, text }
      })
    }
    const segments = []
    let last = 0
    const re = /\x1B\[([0-9;]*)m/g
    let m
    let col = 0
    for (m = re.exec(cleaned); m; m = re.exec(cleaned)) {
      if (m.index > last) {
        const text = expandTabsAt(cleaned.slice(last, m.index), col)
        col += text.length
        segments.push({ text, ...segmentStyle() })
      }
      applySGR(m[1].split(';').filter(s => s !== ''))
      last = m.index + m[0].length
    }
    if (last < cleaned.length) {
      const text = expandTabsAt(cleaned.slice(last), col)
      segments.push({ text, ...segmentStyle() })
    }
    if (segments.length === 0)
      segments.push({ text: ' ', cls: [], style: {} })
    return segments
  })

  function expandTabsAt(s, startCol) {
    if (!s.includes('\t'))
      return s
    let out = ''
    let col = startCol
    for (const ch of s) {
      if (ch === '\t') {
        const n = 8 - (col % 8)
        out += ' '.repeat(n)
        col += n
      }
      else {
        out += ch
        col += 1
      }
    }
    return out
  }
})

const displayTitle = computed(() =>
  props.title
  || picked.value.title
  || (props.src ? props.src.split('/').pop() : 'terminal'),
)

const gutterCh = computed(() => props.numbers ? String(shownLines.value.length).length + 2 : 0)
provide('tc-gutter-ch', gutterCh)

const bodyStyle = computed(() => {
  const s = { '--tc-gutter': `${gutterCh.value}ch` }
  if (props.maxHeight)
    s.maxHeight = props.maxHeight
  return s
})
const rootStyle = computed(() => props.fontSize ? { fontSize: props.fontSize } : {})
const innerStyle = computed(() => props.padBottom ? { paddingBottom: props.padBottom } : {})
</script>

<template>
  <div class="terminal-capture" :class="{ 'tc-wrap': wrap }" :style="rootStyle">
    <div v-if="!plain" class="tc-titlebar">
      <span class="tc-dot tc-dot-r" /><span class="tc-dot tc-dot-y" /><span class="tc-dot tc-dot-g" />
      <span class="tc-title">{{ displayTitle }}</span>
    </div>
    <div class="tc-body" :style="bodyStyle">
      <div class="tc-inner" :style="innerStyle">
        <div class="tc-pre">
          <div
            v-for="(segs, i) in parsedLines"
            :key="i"
            class="tc-line"
            :class="{ 'tc-hl': hlSet.has(i + 1) }"
          >
            <span v-if="numbers" class="tc-num">{{ i + 1 }}</span><span
              v-for="(seg, j) in segs"
              :key="j"
              :class="seg.cls"
              :style="seg.style"
            >{{ seg.text }}</span>
          </div>
        </div>
        <div class="tc-overlay">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>
