import { existsSync, mkdirSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const catalog = JSON.parse(readFileSync(join(root, 'lectures.json'), 'utf8'))
const [command = 'list', ...args] = process.argv.slice(2)
const isAll = args.includes('--all')
const formatIndex = args.indexOf('--format')
const format = formatIndex >= 0 ? args[formatIndex + 1] : 'pdf'
const target = args.find((argument, index) => (
  !argument.startsWith('--') && args[index - 1] !== '--format'
))
const formats = new Set(['html', 'pdf', 'all'])

const lectures = catalog.topics.flatMap((topic) => topic.lectures.map((lecture) => ({
  ...lecture,
  topicId: topic.id,
  topicTitle: topic.title,
  key: `${topic.id}/${lecture.id}`,
})))

function usage(message) {
  if (message) console.error(`Error: ${message}\n`)
  console.log('Usage: npm run <list|dev|build|export> -- <topic>/<lecture> [--format html|pdf|all]')
  process.exit(message ? 1 : 0)
}

function slidev(arguments_) {
  const executable = process.platform === 'win32' ? 'slidev.cmd' : 'slidev'
  const binary = join(root, 'node_modules', '.bin', executable)
  const result = spawnSync(binary, arguments_, { cwd: root, stdio: 'inherit' })
  if (result.error) throw result.error
  if (result.status !== 0) process.exit(result.status ?? 1)
}

function select() {
  if (isAll) return lectures
  if (!target) usage('A lecture target is required.')
  const lecture = lectures.find((item) => item.key === target)
  if (!lecture) usage(`Unknown lecture '${target}'. Run 'npm run list'.`)
  return [lecture]
}

function entryFor(lecture) {
  const entry = join(root, 'materials', 'lectures', lecture.topicId, lecture.id, 'slides.md')
  if (!existsSync(entry)) usage(`Missing source: ${entry}`)
  return entry
}

if (command === 'list') {
  for (const lecture of lectures) console.log(`${lecture.key}\t${lecture.title}`)
  process.exit(0)
}
if (!['dev', 'build', 'export'].includes(command)) usage(`Unknown command '${command}'.`)
if (command === 'export' && !formats.has(format)) usage(`Unsupported format '${format}'.`)

for (const lecture of select()) {
  const entry = entryFor(lecture)
  const outputDir = join(root, 'dist', lecture.topicId, lecture.id)
  if (command === 'dev') slidev(['--open', entry])
  if (command === 'build' || (command === 'export' && ['html', 'all'].includes(format))) {
    mkdirSync(outputDir, { recursive: true })
    slidev(['build', entry, '--out', outputDir, '--base', './'])
  }
  if (command === 'export' && ['pdf', 'all'].includes(format)) {
    mkdirSync(outputDir, { recursive: true })
    slidev(['export', entry, '--output', join(outputDir, `${lecture.id}.pdf`), '--with-toc'])
  }
}
