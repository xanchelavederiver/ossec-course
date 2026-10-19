# Course design system

Put course-wide CSS, reusable Vue components, layouts, and assets here. Every lecture imports `styles/index.css` in its front matter, so changes apply across the collection.

For a new visual identity, begin with the CSS variables in `styles/index.css`. Keep lecture-specific exceptions next to that lecture rather than changing the shared system.

## Components

- **TerminalCapture** + **TCallout** — captured demo transcript with positioned
  annotations. Plain transcripts are coloured like a standard bash session
  (green `$ ` / red `# ` prompt, bold command, muted trailing `# …` comment);
  lines with their own ANSI SGR codes are rendered as recorded. Disable the
  heuristic with `:colorize="false"`. `src` is resolved by suffix, preferring
  the running deck's own `assets/captures/` — the same file name may exist in
  several decks (e.g. a capture migrated from a deck's `_old` version). `<TCallout :n="1" …>` renders a numbered
  callout instead of a marker box — with `:span` it is a step callout
  (screenshot-annotation convention: a rounded rectangle localizing the region,
  the number badge on its corner), without `:span` a plain asciidoctor-style
  ball. Pair either with a legend that repeats the numbers inline:
  `<span class="co-ball">1</span>`.
- **BlockFlow** — horizontal scheme of blocks connected by arrows (subject →
  reference monitor → object, KDF pipelines). Blocks take `head`/`q`/`sub`,
  fills `tint|dark|accent|amber|green|red`; arrows take optional labels and colours.
- **FieldRecord** — a colon-separated record (`/etc/passwd`, `/etc/shadow` lines,
  hash strings) split into numbered field boxes with a column-wise legend;
  `hot` highlights a field, `label` captions a box (use `sep=""` for hash parts).
  Legend text supports `` `code` ``, `**bold**`, `*italic*`.
- **Timeline** — horizontal timeline with entries alternating above and below
  the axis; `hot` highlights a point.
- **HistoryNote** — the one style for historical asides («Исторический экскурс»).
- **Refs** + **SourcesList** — per-slide references footer «Источники: [n]» and
  the numbered list on the references slide. Both read the deck's `sources.json`
  (ordered `{ id, text, url? }` next to `slides.md`; order = numbering). A click
  on `[n]` jumps to the slide with `routeAlias: refs` and highlights the entry.
  Demo slides simply omit `<Refs>`.
- **Man** — a man-page mention that links to man7.org:
  `<Man p="capabilities(7)" />`; `href` overrides the URL for pages hosted
  elsewhere (e.g. sudoers).
- **SectionTOC** — subsection list on a section title slide; `current` is
  highlighted, the rest are greyed out. Repeat the slide before each
  subsection with `current` advanced.
- **InfoCard** — dpo-style tinted card with a round dark icon badge and inline
  heading; icons: `user | users | id-card | info | warning | terminal`,
  fills `tint | amber | blue`; body is the default slot (markdown).

Markdown tables get no styling from the default theme; wrap one in
`<div class="t-table">…</div>` for the course look — full borders, a dark header
row, zebra striping (defined in `styles/index.css`; size with `text-xs`/`text-sm`
on the wrapper).

`global-bottom.vue` prints the slide number in the lower right corner of every
slide. The references footer sits bottom-left (as in the dpo decks); Slidev's
invisible hover nav controls, which would swallow clicks there, are lifted just
above the footer line by a rule in `styles/index.css` — they still appear on
hover, a touch higher.

Each component's props are documented in its header comment in `components/`.
