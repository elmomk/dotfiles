import { atom, read, update } from 'claude-code'
import type { Register, EngineInterface, FsEntry, Timer } from 'claude-code'

import type {
  PlanSnapshot,
  MrRow,
  Status,
  PlanVersion,
  Decision,
  Target,
  Choice,
} from '../types'

// A docked pane that follows a captain's findings file: its merge request table
// and its BLOCKED log. The module only reads, and draws; it hooks no tool call.
//
// The pane follows a file or nothing, and records who chose it: the module
// (auto) or the person (hand). At a session start the module points the pane at
// the session's own findings file, when the file holds a merge request table,
// and opens it; a crew session without one looks again once a minute. Any other
// session follows nothing and the pane is not opened, until /plan-pane, which
// offers the findings files that hold a plan. A choice by hand is never
// replaced by the module, and outlives a reload.

const PANE = 'plan'
// Where a crew session's findings files are, under the home folder.
const FINDINGS_UNDER_HOME = '.local/state/crew/findings'
// The biggest file $.fs.read takes: one over it is not read, and not offered.
const READ_LIMIT = 4 * 1024 * 1024
const REFRESH_MS = 5000
// How long a crew session with no plan of its own waits to look at its
// findings file again.
const LOOK_MS = 60_000
// How many open decisions the pane lists before it says how many more wait.
const DECISIONS_SHOWN = 4
// A crew name as the `crew` launcher accepts one. CREW_NAME ends up in a file
// path, so nothing else is taken: no separator and no dot, hence no "..".
const CREW_NAME_RE = /^[a-z0-9][a-z0-9-]{0,39}$/

// The shape `snap` is written in (PlanSnapshot.v).
const SHAPE = 2

const snap = atom({ plugin: 'plan-pane', key: 'snap' } as const, null)
const target = atom({ plugin: 'plan-pane', key: 'target' } as const, null)
const choices = atom({ plugin: 'plan-pane', key: 'choices' } as const, [])

function hashStr(s: string): string {
  let h = 5381
  for (let i = 0; i < s.length; i += 1) {
    h = ((h << 5) + h + s.charCodeAt(i)) | 0
  }
  return (h >>> 0).toString(36)
}

function clip(s: string, n: number): string {
  const t = s.trim()
  return t.length > n ? `${t.slice(0, n)}…` : t
}

// The states a Next-step cell can open with.
const LEAD_STATES: Status[] = ['merged', 'dropped', 'superseded']
// What must follow one of those words for it to be the row's state: the end of
// the cell, "." or ":", a clock time (16:05 or 16:05:52), or "by". A backtick,
// a hyphen, a bare number or a parenthesis there starts prose about something
// done to the branch: "Merged `master` into the branch", "Merged 2 review
// fixes", "Merged-results pipeline", "Merged (locally) the fix commits".
const AFTER_STATE_RE = /^(?:$|[.:]|\s+\d{2}:\d{2}(?::\d{2})?(?!\d)|\s+by\b)/

// The state a row's Next-step cell opens with ("MERGED 16:05:52 by ...",
// "Dropped by the user ...", "Superseded: ..."), or null. The same words
// further in ("imageTag silently dropped on a cluster") are prose.
//
// Only a merged row leaves the todo list. A dropped or superseded row stays
// listed with that label: it is a merge request somebody still has to close,
// and "Superseded by the next push" cannot be told from "Superseded by U3" by
// its wording, so a row that stays listed can at worst be mislabelled.
function leadState(next: string): Status | null {
  const lead = next.toLowerCase()
  for (const state of LEAD_STATES) {
    if (lead.startsWith(state) && AFTER_STATE_RE.test(lead.slice(state.length))) {
      return state
    }
  }
  return null
}

function deriveStatus(mr: string, id: string, next: string): Status {
  const state = leadState(next)
  if (state) return state
  const t = `${mr} ${id} ${next}`.toLowerCase()
  if (t.includes('held')) return 'held'
  if (t.includes('blocked')) return 'blocked'
  if (t.includes('draft')) return 'draft'
  if (t.includes('running')) return 'running'
  if (t.includes('green')) return 'green'
  if (
    t.includes('pending') ||
    t.includes('built and verified') ||
    t.includes('not created') ||
    t.includes('not started')
  ) {
    return 'pending'
  }
  return 'unknown'
}

function findHeading(lines: string[], re: RegExp): number {
  for (let i = 0; i < lines.length; i += 1) {
    const ln = lines[i] ?? ''
    if (/^##\s/.test(ln) && re.test(ln)) return i
  }
  return -1
}

function tableAfter(lines: string[], startIdx: number): string[][] {
  const out: string[][] = []
  for (let i = startIdx + 1; i < lines.length; i += 1) {
    const ln = lines[i] ?? ''
    if (/^##\s/.test(ln)) break
    if (!/^\s*\|/.test(ln)) continue
    out.push(ln.split('|').map(c => c.trim()))
  }
  return out
}

type ParsedCore = {
  hasPlan: boolean
  hasLog: boolean
  rows: MrRow[]
  merged: number
  total: number
  todo: MrRow[]
  doneIds: string[]
  decisions: Decision[]
  versions: PlanVersion[]
  sig: string
}

function parsePlan(textAll: string): ParsedCore {
  const lines = textAll.split('\n')

  // A table is there when its heading is and table lines follow it. A plan
  // kept as a list under the heading is no table, and the pane says so rather
  // than draw a section that looks empty and all clear.
  const mrIdx = findHeading(lines, /merge requests/i)
  const mrTable = mrIdx >= 0 ? tableAfter(lines, mrIdx) : []
  const rows: MrRow[] = []
  for (const cells of mrTable) {
    const n = cells[1] ?? ''
    if (!n || n === '#' || /^-+$/.test(n)) continue
    const mr = cells[2] ?? ''
    const id = cells[3] ?? ''
    const next = cells[8] ?? ''
    const go = cells[9] ?? ''
    rows.push({ n, id, mr, status: deriveStatus(mr, id, next), next, go })
  }
  const merged = rows.filter(r => r.status === 'merged').length
  const todo = rows.filter(r => r.status !== 'merged')
  const doneIds = rows.filter(r => r.status === 'merged').map(r => r.id || r.n)

  const decIdx = findHeading(
    lines,
    /decisions asked|decisions the user owes|blocked log/i,
  )
  const decTable = decIdx >= 0 ? tableAfter(lines, decIdx) : []
  const decisions: Decision[] = []
  for (const cells of decTable) {
    const id = cells[1] ?? ''
    if (!id || id === 'Id' || /^-+$/.test(id)) continue
    const answer = (cells[4] ?? '').toLowerCase()
    if (answer === '' || answer === 'open') {
      decisions.push({ id, sent: cells[2] ?? '', asks: cells[3] ?? '' })
    }
  }

  // Every heading that names a plan. They are not drawn (the last one in the
  // file is not the newest plan), but they are part of the signature below, so
  // a plan heading added or renamed still counts as a plan change.
  const versions: PlanVersion[] = []
  for (const ln of lines) {
    const m = /^##\s+(.*\bplan\b.*)$/i.exec(ln)
    if (m) {
      const tm = /\((\d{1,2}:\d{2})\)/.exec(ln)
      versions.push({
        title: (m[1] ?? '').replace(/\s*\(\d{1,2}:\d{2}\)\s*$/, '').trim(),
        at: tm?.[1] ?? '',
      })
    }
  }

  // What a plan change is: a row added, removed, or changed in its state, its
  // Next-step text or its go gate; a decision added or answered; a plan heading.
  const sig = hashStr(
    `${JSON.stringify(rows.map(r => [r.n, r.status, r.next, r.go]))}#${decisions
      .map(d => d.id)
      .join(',')}#${versions.map(v => v.title).join('|')}`,
  )
  return {
    hasPlan: mrTable.length > 0,
    hasLog: decTable.length > 0,
    rows,
    merged,
    total: rows.length,
    todo,
    doneIds,
    decisions,
    versions,
    sig,
  }
}

function diffRows(prev: MrRow[], now: MrRow[]): string[] {
  const out: string[] = []
  const pmap = new Map(prev.map(r => [r.n, r] as const))
  const nmap = new Map(now.map(r => [r.n, r] as const))
  for (const r of now) {
    const p = pmap.get(r.n)
    const label = r.id || r.n
    if (!p) out.push(`+ ${label} (${r.status})`)
    else if (p.status !== r.status) out.push(`${label}: ${p.status} -> ${r.status}`)
    else if (p.next !== r.next) out.push(`${label}: next step edited`)
    else if (p.go !== r.go) out.push(`${label}: go ${p.go || '-'} -> ${r.go || '-'}`)
  }
  for (const r of prev) if (!nmap.has(r.n)) out.push(`- ${r.id || r.n}`)
  return out.slice(0, 6)
}

function statusColor(s: Status): string | undefined {
  switch (s) {
    case 'merged':
    case 'green':
      return 'green'
    case 'blocked':
    case 'dropped':
      return 'red'
    case 'running':
    case 'pending':
      return 'yellow'
    case 'draft':
    case 'held':
    case 'superseded':
      return 'gray'
    default:
      return undefined
  }
}

function hhmm(ms: number): string {
  const d = new Date(ms)
  const p = (n: number) => (n < 10 ? `0${n}` : `${n}`)
  return `${p(d.getHours())}:${p(d.getMinutes())}`
}

// What an earlier read left, when it was a read of this same file. A plan
// change is a change between two reads of one file: what another file held
// says nothing about this one, so /plan-pane <path> is not a plan change.
function sameFile(prev: PlanSnapshot | null, file: string): PlanSnapshot | null {
  return prev?.file === file ? prev : null
}

// `value` as a snapshot of the shape this module writes, or null: nothing read
// yet, or one an earlier version of the module left (state outlives a hot
// reload). Without the arrays, the two table flags and the shape number it is
// neither drawn as a plan nor compared with a new read.
function asSnap(value: unknown): PlanSnapshot | null {
  const s = value as Partial<PlanSnapshot> | null | undefined
  if (
    s === null ||
    typeof s !== 'object' ||
    s.v !== SHAPE ||
    typeof s.file !== 'string' ||
    typeof s.ok !== 'boolean' ||
    typeof s.hasPlan !== 'boolean' ||
    typeof s.hasLog !== 'boolean' ||
    !Array.isArray(s.rows) ||
    !Array.isArray(s.todo) ||
    !Array.isArray(s.doneIds) ||
    !Array.isArray(s.decisions) ||
    !Array.isArray(s.changes)
  ) {
    return null
  }
  return s as PlanSnapshot
}

// Whether two JSON values are the same, whatever order their keys came back in.
function same(a: unknown, b: unknown): boolean {
  if (a === b) return true
  if (typeof a !== 'object' || typeof b !== 'object' || a === null || b === null) return false
  if (Array.isArray(a) !== Array.isArray(b)) return false
  const x = a as Record<string, unknown>
  const y = b as Record<string, unknown>
  const keys = Object.keys(x)
  return keys.length === Object.keys(y).length && keys.every(k => k in y && same(x[k], y[k]))
}

// The text of a file, or null when it cannot be read.
async function readText($: EngineInterface, path: string): Promise<string | null> {
  try {
    const got = await $.fs.read(path)
    return typeof got === 'string' ? got : null
  } catch {
    return null
  }
}

// What a read of `file` leaves in the snapshot, after the one before it:
// `core` is what the file parsed to, null when it could not be read.
function snapshot(
  prev: PlanSnapshot | null,
  file: string,
  core: ParsedCore | null,
  now: number,
): PlanSnapshot {
  const kept = sameFile(prev, file)
  let changedAt = kept?.changedAt ?? null
  let changes = kept?.changes ?? []
  if (core === null) {
    return {
      v: SHAPE,
      file,
      ok: false,
      error: `cannot read ${file}`,
      hasPlan: false,
      hasLog: false,
      rows: [],
      merged: 0,
      total: 0,
      todo: [],
      doneIds: [],
      decisions: [],
      versions: [],
      sig: '',
      changedAt,
      changes,
    }
  }
  if (kept && kept.ok && kept.sig && kept.sig !== core.sig) {
    changes = diffRows(kept.rows, core.rows)
    changedAt = now
  }
  return { v: SHAPE, file, ok: true, ...core, changedAt, changes }
}

// `value` as a target of the shape this module writes, or null: none, or the
// plain path an earlier version of the module left, which records nothing of
// how it was chosen (state outlives a hot reload).
function asTarget(value: unknown): Target | null {
  const t = value as Partial<Target> | null | undefined
  if (t === null || typeof t !== 'object') return null
  if (typeof t.file !== 'string' || (t.by !== 'auto' && t.by !== 'hand')) return null
  return t as Target
}

// The number the latest refresh to start took, and the number of the latest one
// to write the snapshot. Refreshes can overlap (a tick's, a command's, a press's)
// and one that started earlier can be answered later: what it read is older than
// what a later one has written, and writing it would put the file back as it
// was, which the pane would report as a plan change.
let started = 0
let written = 0

async function refresh($: EngineInterface): Promise<void> {
  started += 1
  const mine = started
  const aimed = asTarget(await read($, target))
  if (aimed === null) return
  const now = await $.clock.now()
  const text = await readText($, aimed.file)
  // A press or a command may have moved the pane to another file while this
  // one was read: the read is of no use then, and the move made its own.
  if (asTarget(await read($, target))?.file !== aimed.file) return
  const core = text === null ? null : parsePlan(text)
  // A read that finds the file as it was changes nothing: no write, so no
  // redraw. What is written is worked out again from what stands by then.
  const before = asSnap(await read($, snap))
  if (same(before, snapshot(before, aimed.file, core, now))) return
  // When a refresh that started later has already written, this read is the
  // older one and is let go. Nothing is awaited between that comparison and
  // recording this refresh's own number.
  if (mine < written) return
  written = mine
  await update($, snap, latest => snapshot(asSnap(latest), aimed.file, core, now))
}

// What `argv` printed with its one trailing newline cut, or null when it could
// not run or exited non-zero (printenv exits 1 for a variable that is not set).
async function printed($: EngineInterface, argv: string[]): Promise<string | null> {
  try {
    const { exitCode, stdout } = await $.process.run(argv)
    if (exitCode !== 0) return null
    return stdout.endsWith('\n') ? stdout.slice(0, -1) : stdout
  } catch {
    return null
  }
}

// A folder out of the environment becomes part of a path that $.fs reads, and a
// relative path would be read under the session's directory: only an absolute
// path with no newline in it is taken.
function folder(value: string | null): string | null {
  return value !== null && value.startsWith('/') && !value.includes('\n') ? value : null
}

// Where this session's findings are: the folder, and the file of the crew
// member `printenv CREW_NAME` names, when it names one. Without a usable home
// folder there is no findings folder, and so no file either.
type Place = { dir: string | null; crew: string | null }

async function locate($: EngineInterface): Promise<Place> {
  const home = folder(await printed($, ['printenv', 'HOME']))
  if (home === null) return { dir: null, crew: null }
  const dir = `${home}/${FINDINGS_UNDER_HOME}`
  const name = await printed($, ['printenv', 'CREW_NAME'])
  return { dir, crew: name !== null && CREW_NAME_RE.test(name) ? `${dir}/${name}.md` : null }
}

// The place the last session start worked out, as a promise: a command that
// comes before it is done waits for it, and after a hot reload (no session
// start for this environment yet) it is worked out when first asked for.
let place: Promise<Place> | undefined

function placeOf($: EngineInterface): Promise<Place> {
  place ??= locate($)
  return place
}

// The timer that ticks, which a later session.start stops before it starts its
// own: session.start fires again on a reload or a worker respawn, and timers
// must not stack. A reload gives the module a fresh environment and drops its
// timers with the old one, so nothing of this outlives one.
let timer: Timer | undefined
// Whether a tick is still at work. A tick that finds one in flight does
// nothing: a slow read must not pile reads up behind it.
let reading = false

// Starts a timer that ticks every `ms`, or none when `ms` is null, after
// stopping the one there was.
function setTimer($: EngineInterface, ms: number | null): void {
  timer?.cancel()
  timer =
    ms === null
      ? undefined
      : $.clock.every(ms, () => {
          void tick($)
        })
}

// One tick: while the pane follows a file, read it again; while it follows
// nothing, look at the session's own file once more, as a plan often appears
// during a session.
async function tick($: EngineInterface): Promise<void> {
  if (reading) return
  reading = true
  try {
    if (asTarget(await read($, target)) !== null) {
      await refresh($)
    } else {
      const { crew } = await placeOf($)
      if (crew !== null) await adopt($, crew)
    }
  } catch {
    /* the next tick tries again */
  } finally {
    reading = false
  }
}

// Reads the target now, and again at every tick.
async function follow($: EngineInterface): Promise<void> {
  setTimer($, REFRESH_MS)
  try {
    await refresh($)
  } catch {
    /* the timer reads again */
  }
}

// Points the pane at `file`, and resolves whether it does now. What the module
// chooses itself (auto) never replaces what the person chose (hand).
async function aim($: EngineInterface, file: string, by: Target['by']): Promise<boolean> {
  // No write when it already is so, or when it will not be: a write would be
  // drawn again for nothing.
  const held = asTarget(await read($, target))
  if (held?.file === file && held.by === by) return true
  if (by === 'auto' && held?.by === 'hand') return false
  const set = asTarget(
    await update($, target, latest => {
      const kept = asTarget(latest)
      return by === 'auto' && kept?.by === 'hand' ? kept : { file, by }
    }),
  )
  return set?.file === file && set.by === by
}

// The session's own plan: when `file` holds a merge request table, the pane is
// pointed at it (auto), opened, and followed. Resolves whether it was.
async function adopt($: EngineInterface, file: string): Promise<boolean> {
  const text = await readText($, file)
  if (text === null || !parsePlan(text).hasPlan) return false
  if (!(await aim($, file, 'auto'))) return false
  // Unawaited, because placing can wait on the surface. A ui.open hook may
  // refuse, and that must not be left as a rejection nothing handles.
  void $.ui.open({ id: PANE, title: 'Plan' }).catch(() => {})
  await follow($)
  return true
}

// Looks through the findings folder for what the chooser offers: every *.md
// directly in it (a subfolder is not looked into) that holds a merge request
// table, in name order. A file that cannot be read, or is too big for $.fs.read,
// is left out. Nothing else looks: the chooser is the only thing that needs
// this, so it is looked for when the chooser is about to be shown.
async function scan($: EngineInterface): Promise<void> {
  const { dir } = await placeOf($)
  if (dir === null) {
    await update($, choices, () => [])
    return
  }
  let entries: FsEntry[] = []
  try {
    entries = await $.fs.list(dir)
  } catch {
    /* no folder, so nothing to offer */
  }
  const names = entries
    .filter(f => f.kind === 'file' && f.name.endsWith('.md') && f.size <= READ_LIMIT)
    .map(f => f.name)
    .sort()
  const looked = await Promise.all(
    names.map(async (name): Promise<Choice | null> => {
      const file = `${dir}/${name}`
      const text = await readText($, file)
      const core = text === null ? null : parsePlan(text)
      return core?.hasPlan ? { file, merged: core.merged, total: core.total } : null
    }),
  )
  await update($, choices, () => looked.filter((c): c is Choice => c !== null))
}

// How many choices by hand have been made, by `/plan-pane` with an argument or by
// a press in the chooser. A choice counts once the target holds it, and before it
// sets its timer, with nothing awaited between. A session start looks at the target
// once more before it settles the timer, and the answer to that look can arrive
// late, after a choice made since the look was asked for: that choice has set its
// own timer, and the start must not change it.
let handChoices = 0

// What a press on an entry of the chooser does: the person's choice of that file.
async function choose($: EngineInterface, file: string): Promise<void> {
  try {
    await aim($, file, 'hand')
    handChoices += 1
    await follow($)
  } catch {
    /* the person presses again */
  }
}

// Whether the pane is open. The engine keeps that record, and a pane outlives a
// reload of the module that opened it.
async function paneUp($: EngineInterface): Promise<boolean> {
  try {
    return (await $.ui.panes()).some(pane => pane.id === PANE)
  } catch {
    return false
  }
}

// Opens the pane and, when `follows` is set, follows the target while it opens.
// The pane may refuse to open, or wait on the surface to be placed, and the file
// is followed all the same. A refusal still reaches the caller, once that is done.
async function openPane($: EngineInterface, follows: boolean): Promise<void> {
  const opening = $.ui.open({ id: PANE, title: 'Plan' })
  // Handled now though it is awaited last: a refusal that comes while the file
  // is being read would otherwise be a rejection nothing handles.
  void opening.catch(() => {})
  if (follows) await follow($)
  await opening
}

// What a session start sets going: the command, the lookup of the session's own
// plan, and the timer. Nobody waits for it (see session.start below), so a
// fault in any step is caught where it happens and the steps after it still run.
async function begin($: EngineInterface): Promise<void> {
  try {
    await $.command.register({
      name: 'plan-pane',
      description: 'Follow a captain plan file in a pane: /plan-pane [name or path]',
    })
  } catch {
    /* a name collision must not kill the pane */
  }
  // This start's own lookup, kept in a local as well: `place` is replaced by the
  // next start, and this one goes on with the answer to its own.
  const looking = locate($)
  place = looking
  // The target is read before the lookup is waited for: a printenv can take as
  // long as $.process.run's timeout, and what stands in the target does not
  // depend on it.
  const held: unknown = await read($, target)
  // session.start fires again on a reload or a worker respawn, and a target the
  // person chose must outlive that, whatever CREW_NAME says now. It is followed
  // at once, not once the lookup has answered.
  if (asTarget(held)?.by === 'hand') {
    await follow($)
    return
  }
  // What an earlier version of this module left is no target, and the pane
  // follows nothing: that is set now too, before the lookup is waited for.
  if (held !== null && asTarget(held) === null) {
    await update($, target, was => (asTarget(was) === null ? null : was))
  }
  const here = await looking
  // Anything else is resolved afresh: the session's own plan, or nothing.
  // That includes what an earlier version of this module left, which records
  // nothing of how it was chosen.
  if (here.crew !== null && (await adopt($, here.crew))) return
  // Choices by hand are counted from here: one made after this may not be seen
  // by the look below.
  const noted = handChoices
  const kept =
    held === null
      ? await read($, target)
      : await update($, target, was => (asTarget(was)?.by === 'hand' ? was : null))
  // The person chose a file while this looked: that choice has its own timer.
  if (kept !== null) return
  // The answer can be late: a choice made since the look was asked for has its
  // own timer too, whatever the answer says. Nothing is awaited between this and
  // setTimer.
  if (handChoices !== noted) return
  // A crew session looks again once a minute, any other session never does.
  setTimer($, here.crew === null ? null : LOOK_MS)
  // The pane follows nothing, and is not opened. One that is up all the same
  // (it outlived a reload, or an earlier version of this module opened it)
  // shows the chooser, so the chooser is looked for.
  if (await paneUp($)) await scan($)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    // Not awaited: session.start is awaited before the first prompt, so a
    // `printenv` or a read that is slow, or never answers, would hold the whole
    // session up. What begin cannot foresee is caught here, not left a
    // rejection nothing handles.
    void begin($).catch(() => {})

    return next(e)
  })

  on('command.run', { command: 'plan-pane' }, async ($, e) => {
    const arg = (e.args ?? '').trim()
    if (arg === '') {
      // The pane opens on the file it follows, which is followed again; with
      // none, on the chooser, and nothing is followed.
      const chosen = asTarget(await read($, target)) !== null
      if (!chosen) await scan($)
      await openPane($, chosen)
      return { text: 'Plan pane opened.' }
    }

    // A path when it starts with "/", else a crew name, which is the file of
    // that name in the findings folder.
    let file: string
    if (arg.startsWith('/')) {
      file = arg
    } else if (CREW_NAME_RE.test(arg)) {
      const { dir } = await placeOf($)
      if (dir === null) {
        return {
          text:
            'Plan pane: no findings folder (HOME is not an absolute path), ' +
            `so "${arg}" cannot be looked up: give a path.`,
        }
      }
      file = `${dir}/${arg}.md`
    } else {
      return {
        text: `Plan pane: "${arg}" is neither a crew name nor a path starting with "/".`,
      }
    }
    await aim($, file, 'hand')
    handChoices += 1
    await openPane($, true)

    return { text: `Plan pane -> ${file}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const held: unknown = await read($, target)

    // Following nothing: the session has no plan of its own and the person has
    // chosen none. The pane offers the plans there are, or is empty.
    if (held === null) {
      const offered = await read($, choices)
      if (offered.length === 0) {
        return (
          <Box flexDirection="column">
            <Text>no findings file holds a merge request table</Text>
            <Text dimColor>
              {'point the pane at a file: /plan-pane <name> or /plan-pane /path/to/file.md'}
            </Text>
          </Box>
        )
      }
      return (
        <Box flexDirection="column">
          {offered.map(c => {
            const name = c.file.split('/').pop() ?? c.file
            return (
              <Button
                key={`plan:${name}`}
                label={`${name} — ${c.merged}/${c.total} merged`}
                onPress={() => choose($, c.file)}
              />
            )
          })}
          <Text dimColor>{'or type /plan-pane <name>'}</Text>
        </Box>
      )
    }
    const aimed = asTarget(held)
    const s = asSnap(await read($, snap))

    // Nothing read yet of the file the pane follows; or a target or a snapshot
    // an earlier version of this module left.
    if (aimed === null || s === null || s.file !== aimed.file) {
      return (
        <Box flexDirection="column">
          <Text dimColor>Reading plan...</Text>
        </Box>
      )
    }
    if (!s.ok) {
      return (
        <Box flexDirection="column">
          <Text color="red" bold>
            plan: unavailable
          </Text>
          <Text dimColor wrap="truncate-end">
            {s.error ?? ''}
          </Text>
        </Box>
      )
    }

    const base = s.file.split('/').pop() ?? s.file
    const vrows = e.viewport?.rows ?? 40
    const todoRoom = Math.max(2, Math.floor((vrows - 14) / 3))

    return (
      <Box flexDirection="column" gap={1}>
        <Box flexDirection="column">
          <Text bold>
            {base}
            {s.hasPlan ? ` — ${s.merged}/${s.total} merged` : ''}
          </Text>
        </Box>

        <Box flexDirection="column">
          <Text bold color="cyan">
            Todo, in order
          </Text>
          {!s.hasPlan ? (
            <Text color="yellow">no merge request table in {base}</Text>
          ) : s.todo.length === 0 ? (
            <Text dimColor>nothing open</Text>
          ) : (
            s.todo.slice(0, todoRoom).map((r, i) => (
              <Box key={r.n} flexDirection="column">
                <Text color={statusColor(r.status)}>
                  {i + 1}. {r.id || r.n}
                  {r.mr && r.mr !== 'new' ? ` (${r.mr})` : ''}
                  {r.status !== 'unknown' ? ` — ${r.status}` : ''}
                  {r.go ? `  · go: ${r.go}` : ''}
                </Text>
                {r.next ? (
                  <Text dimColor wrap="wrap">
                    {clip(r.next, 240)}
                  </Text>
                ) : null}
              </Box>
            ))
          )}
          {s.todo.length > todoRoom ? (
            <Text dimColor>...+{s.todo.length - todoRoom} more below</Text>
          ) : null}
        </Box>

        <Box flexDirection="column">
          <Text bold color="yellow">
            Needs your call
          </Text>
          {!s.hasLog ? (
            <Text color="yellow">no BLOCKED log in {base}</Text>
          ) : s.decisions.length === 0 ? (
            <Text dimColor>no open decisions</Text>
          ) : (
            s.decisions.slice(0, DECISIONS_SHOWN).map(d => (
              <Box key={d.id} flexDirection="column">
                <Text bold color="yellow">
                  {d.id}
                  {d.sent ? ` (${d.sent})` : ''}
                </Text>
                <Text color="yellow" wrap="wrap">
                  {clip(d.asks, 300)}
                </Text>
              </Box>
            ))
          )}
          {s.decisions.length > DECISIONS_SHOWN ? (
            <Text color="yellow">
              ...+{s.decisions.length - DECISIONS_SHOWN} more open
            </Text>
          ) : null}
        </Box>

        <Box flexDirection="column">
          {s.doneIds.length ? (
            <Text dimColor wrap="truncate-end">done: {s.doneIds.join(', ')}</Text>
          ) : null}
          {s.changedAt ? (
            <Text color="green" wrap="truncate-end">
              plan updated {hhmm(s.changedAt)}
              {s.changes[0] ? ` — ${s.changes[0]}` : ''}
            </Text>
          ) : (
            <Text dimColor>no plan change seen this session</Text>
          )}
        </Box>
      </Box>
    )
  })
}
