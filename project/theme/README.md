# Course design system

Put course-wide CSS, reusable Vue components, layouts, and assets here. Every lecture imports `styles/index.css` in its front matter, so changes apply across the collection.

For a new visual identity, begin with the CSS variables in `styles/index.css`. Keep lecture-specific exceptions next to that lecture rather than changing the shared system.

## Components

- **TerminalCapture** + **TCallout** — captured demo transcript with positioned
  annotations. Plain transcripts are coloured like a standard bash session
  (green `$ ` / red `# ` prompt, bold command, muted trailing `# …` comment);
  lines with their own ANSI SGR codes are rendered as recorded. Disable the
  heuristic with `:colorize="false"`.
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

Each component's props are documented in its header comment in `components/`.
