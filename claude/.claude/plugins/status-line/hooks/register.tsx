import type { Register, EngineInterface, Timer } from 'claude-code'

// One status line, pinned under the prompt: today's points of the weekly limit, the
// week's usage and the NAT ports this box holds toward the Claude API, as
// "day 2% · wk 33% · api 16/64". The module hooks session.start and nothing else, so
// it can neither deny nor change anything, and a field it cannot read says "?" and
// never a number.

const REFRESH_MS = 5000

// Cloud NAT gives this box 64 ports per destination (api-headroom documents it).
// At 63-64 held it drops new SYNs; api-headroom refuses a launch from 58, which
// this line does not show.
const NAT_PORTS = 64

// tmux-sysstat's API chip calls its count unknown once api-held is older than
// this, in seconds. The watcher rewrites the file at least every 5 s.
const API_STALE_S = 15

// Two weekly reset times less than this apart are one window's, as claude-usage's
// WINDOW_SLACK_MS has it: one window's reset time comes out a few hundred milliseconds
// apart from one source to the next.
const WINDOW_SLACK_MS = 60 * 60 * 1000

// The popup lets a weekly figure go once it is this old, as claude-usage's WEEK_KEEP_MS
// has it: 8 days.
const WEEK_KEEP_MS = 8 * 24 * 60 * 60 * 1000

type Paths = { week: string | null; figures: string | null; api: string | null }

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

// A folder out of the environment becomes part of a path that $.fs.read opens, and
// a relative path would be read under the session's directory: only an absolute
// path with no newline in it is taken.
function folder(value: string | null): string | null {
  return value !== null && value.startsWith('/') && !value.includes('\n') ? value : null
}

// Where the files are, worked out once at each session start. Both folders come
// from the environment, `printenv` as plan-pane asks for CREW_NAME; the runtime one
// falls back to /run/user/<uid>, as tmux-sysstat-api's own state path does.
async function locate($: EngineInterface): Promise<Paths> {
  const home = folder(await printed($, ['printenv', 'HOME']))
  let run = folder(await printed($, ['printenv', 'XDG_RUNTIME_DIR']))
  if (run === null) {
    const uid = await printed($, ['id', '-u'])
    run = uid !== null && /^\d+$/.test(uid) ? `/run/user/${uid}` : null
  }
  return {
    week: home === null ? null : `${home}/.local/state/claude-usage/statusline-limits.json`,
    figures: home === null ? null : `${home}/.local/state/claude-usage/week.json`,
    api: run === null ? null : `${run}/tmux-sysstat/api-held`,
  }
}

// A file's text, or null when its path was never found or it cannot be read.
async function readText($: EngineInterface, path: string | null): Promise<string | null> {
  if (path === null) return null
  try {
    const got = await $.fs.read(path)
    return typeof got === 'string' ? got : null
  } catch {
    return null
  }
}

// claude-usage prints a percent with Python's {pct:g}: 33, 33.4, six digits at most.
const percent = (x: number): string => String(Number(x.toPrecision(6)))

// What statusline-command.sh keeps in statusline-limits.json, as far as this reads it:
// the figures, when they were fetched, and under `previous` the same of the figures the
// file held before the local day it last replaced them on.
type Limits = {
  fetchedAtMs?: unknown
  utilization?: {
    seven_day?: { utilization?: unknown; resets_at?: unknown } | null
  } | null
  previous?: Limits
} | null

// The instant a time names, in epoch ms, or NaN when it is not one this reads: the two
// shapes the files hold, "2026-10-08T12:00:00Z" (statusline-command.sh's) and
// "2026-10-08T11:59:59.828970+00:00" (/usage's, in plan.json), each with a Z or a
// +hh:mm / -hh:mm offset. Date.parse alone also reads "5" and "2026" as dates, and a
// time with no offset in the box's own zone, so the text is cut to the exact form
// ES defines first, the fraction to milliseconds.
function isoMs(text: string): number {
  const m = /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:\d{2})$/.exec(text)
  if (m === null) return NaN
  const millis = (m[2] ?? '').slice(0, 3).padEnd(3, '0')
  return Date.parse(`${m[1]}.${millis}${m[3]}`)
}

// The week's half: "wk 33%", or "wk ?" when the file is missing, is not JSON, has no
// number where the figure belongs, or the figure's window has ended.
//
// A figure holds for as long as its window runs: within one a percentage only goes up,
// and statusline-command.sh rewrites the file only when the 5-hour or the 7-day figure
// has moved, so the file's own age (fetchedAtMs) says nothing about the figure. What
// ends it is its window: from the time resets_at names, the figure is the closed
// window's, and it reads "wk ?" until the file is rewritten for the next one. A
// resets_at that is missing, or is not a time isoMs reads, leaves nothing to compare the
// figure with, and the figure is shown.
//
// claude-usage shows the newest of three sources: /usage's cache in ~/.claude.json,
// which this never reads, plan.json, which only claude-usage's own popup refreshes,
// and this file, the one that keeps itself current. Claude Code hands the status line
// the account's limits after each API response.
function weekHalf(raw: string | null, now: number | null): string {
  if (raw === null || now === null) return 'wk ?'
  let doc: Limits
  try {
    doc = JSON.parse(raw)
  } catch {
    return 'wk ?'
  }
  const week = doc?.utilization?.seven_day
  const pct = week?.utilization
  if (typeof pct !== 'number' || !Number.isFinite(pct) || pct < 0) return 'wk ?'
  const resetsAt = week?.resets_at
  const ends = typeof resetsAt === 'string' ? isoMs(resetsAt) : NaN
  return Number.isFinite(ends) && ends <= now ? 'wk ?' : `wk ${percent(pct)}%`
}

// One weekly figure as claude-usage keeps them in week.json: when it was fetched, the
// percent it read, and the end of its window, all in epoch ms except the percent, and
// null for a window with no end on record.
type Figure = { at: number; pct: number; resets: number | null }

const finite = (x: unknown): x is number => typeof x === 'number' && Number.isFinite(x)
const integer = (x: unknown): x is number => typeof x === 'number' && Number.isInteger(x)

// Whether two weekly reset times are one window's: less than WINDOW_SLACK_MS apart, or
// either unknown.
function sameWindow(a: number | null, b: number | null): boolean {
  return a === null || b === null || Math.abs(a - b) < WINDOW_SLACK_MS
}

// The local midnight that starts the day `now` is in, in epoch ms. The local setters work
// in the box's time zone, which the module runs in, as plan-pane's hhmm relies on when it
// reads the local getters, and which claude-usage counts its days in.
function localMidnight(now: number): number {
  const day = new Date(now)
  day.setHours(0, 0, 0, 0)
  return day.getTime()
}

// Today's use of the weekly limit, in points of it, or null when the figures cannot say:
// claude-usage's week_today, case for case and in its order. It also hands back where
// its count began and which case answered, which this does not show. `cur` is the week's
// figure shown and `figures` the ones on record, oldest first.
//
// The points are `cur`'s less the last figure before local midnight, else less today's
// first. Across the weekly reset they are the old window's points after that figure and
// the new window's added, or the new window's alone when no figure of the old window came
// after it. A `cur` that is not from today counts nothing, nor does one that is today's
// first figure or only repeats it, as two sources fetched moments apart do.
function weekToday(figures: Figure[], cur: Figure, now: number): number | null {
  const midnight = localMidnight(now)
  if (cur.at < midnight) return null
  const upto = figures.filter(f => f.at <= cur.at)
  const before = upto.filter(f => f.at < midnight)
  const base = before.at(-1) ?? upto.find(f => f.at < cur.at)
  if (
    base === undefined ||
    (before.length === 0 && base.pct === cur.pct && sameWindow(base.resets, cur.resets))
  ) {
    return null
  }
  if (
    sameWindow(base.resets, cur.resets) ||
    (base.resets !== null && cur.resets !== null && base.resets > cur.resets)
  ) {
    return Math.max(0, cur.pct - base.pct)
  }
  const old = upto.filter(
    f => f.at > base.at && f.resets !== null && sameWindow(f.resets, base.resets),
  )
  const last = old.at(-1)
  return last === undefined ? cur.pct : Math.max(0, last.pct - base.pct) + cur.pct
}

// The week's figure a limits record holds, or null when it holds none this can use: it
// needs a fetch time that is a number and a percent that is a number, not below 0, as
// weekHalf takes one. Its window ends at resets_at, read as weekHalf reads it, and at no
// time known when that is missing or is not one isoMs reads.
function heldFigure(held: Limits | undefined): Figure | null {
  const week = held?.utilization?.seven_day
  const at = held?.fetchedAtMs
  const pct = week?.utilization
  if (!finite(at) || !finite(pct) || pct < 0) return null
  const resetsAt = week?.resets_at
  const resets = typeof resetsAt === 'string' ? isoMs(resetsAt) : NaN
  return { at, pct, resets: Number.isFinite(resets) ? resets : null }
}

// The figures in week.json, {"figures": [[fetched, percent, resets], ...]}, which the
// popup keeps for 8 days: those in the shape claude-usage's week_figures takes in, a list
// of three with the fetch time a whole number, the percent a number and the reset time a
// whole number or null. Any other entry adds nothing, and nor does a file that is missing,
// is not JSON or holds no such list. Three differences from Python, none of which a file
// the popup wrote shows: JSON.parse cannot tell 5 from 5.0, which week_figures turns away
// as a float; a percent must be finite, where Python reads 1e999 as inf, so that the field
// never prints Infinity; and a percent below 0 is no figure, as weekHalf takes it, where
// Python takes it in.
function recordedFigures(raw: string | null): Figure[] {
  if (raw === null) return []
  let doc: { figures?: unknown } | null
  try {
    doc = JSON.parse(raw)
  } catch {
    return []
  }
  const list = doc?.figures
  if (!Array.isArray(list)) return []
  const figures: Figure[] = []
  for (const f of list) {
    if (
      Array.isArray(f) &&
      f.length === 3 &&
      integer(f[0]) &&
      finite(f[1]) &&
      f[1] >= 0 &&
      (f[2] === null || integer(f[2]))
    ) {
      figures.push({ at: f[0], pct: f[1], resets: f[2] })
    }
  }
  return figures
}

// The figures on record, oldest first: claude-usage's week_figures, less the file it reads
// and writes. They are sorted by fetch time, then window end (an unknown one first), then
// percent. A figure is let go when it was fetched more than WEEK_KEEP_MS before `now`, or
// when it only repeats the one kept before it: the same percent in the same window.
function weekFigures(figures: Figure[], now: number): Figure[] {
  const sorted = [...figures].sort(
    (a, b) => a.at - b.at || (a.resets ?? 0) - (b.resets ?? 0) || a.pct - b.pct,
  )
  const kept: Figure[] = []
  for (const f of sorted) {
    const last = kept.at(-1)
    const repeat = last !== undefined && last.pct === f.pct && sameWindow(last.resets, f.resets)
    if (f.at >= now - WEEK_KEEP_MS && !repeat) kept.push(f)
  }
  return kept
}

// The day field: "day 2%", today's points of the weekly limit as the usage popup counts
// them, or "day ?" when it cannot say: the week half reads "wk ?", the limits file has no
// fetch time to place its figure by, or weekToday finds nothing to count from.
//
// It counts from the figures the popup keeps in week.json and the two the limits file
// holds, the current one and the one under `previous`, as the popup's week_figures leaves
// them. The popup writes week.json and this only reads it; without it the limits file's
// two figures are all there are.
function dayField(
  limits: string | null,
  recorded: string | null,
  week: string,
  now: number | null,
): string {
  if (limits === null || now === null || week === 'wk ?') return 'day ?'
  let doc: Limits
  try {
    doc = JSON.parse(limits)
  } catch {
    return 'day ?'
  }
  const cur = heldFigure(doc)
  if (cur === null) return 'day ?'
  const previous = heldFigure(doc?.previous)
  const figures = weekFigures(
    [...recordedFigures(recorded), cur, ...(previous === null ? [] : [previous])],
    now,
  )
  const points = weekToday(figures, cur, now)
  return points === null ? 'day ?' : `day ${percent(points)}%`
}

// The API half: "api 16/64", "api 16+/64" while the count is a floor, or "api ?".
// tmux-sysstat's API chip is the rule: the file holds "<epoch seconds> <ports held>
// <open> <warm>", the first two in digits and the first not older than API_STALE_S,
// else the count is unknown; it is exact when warm is 1 and a floor otherwise. The
// chip's `read -r` leaves the rest of the line in warm, as the rest does here.
function apiHalf(raw: string | null, now: number | null): string {
  if (raw === null || now === null) return 'api ?'
  const [at, n, , ...warm] = (raw.split('\n', 1)[0] ?? '').trim().split(/\s+/)
  if (at === undefined || n === undefined || !/^\d+$/.test(at) || !/^\d+$/.test(n)) {
    return 'api ?'
  }
  if (Math.floor(now / 1000) - Number(at) > API_STALE_S) return 'api ?'
  return `api ${n}${warm.join(' ') === '1' ? '' : '+'}/${NAT_PORTS}`
}

// The text last pinned, kept so that a tick pins again only when it changed.
type Pinned = { text: string | undefined }

// Reads the three files and pins the line when its text is not the one pinned.
async function refresh($: EngineInterface, paths: Paths, pinned: Pinned): Promise<void> {
  try {
    const now = await $.clock.now().catch(() => null)
    const limits = await readText($, paths.week)
    const week = weekHalf(limits, now)
    const day = dayField(limits, await readText($, paths.figures), week, now)
    const api = apiHalf(await readText($, paths.api), now)
    const text = `${day} · ${week} · ${api}`
    if (text !== pinned.text) {
      $.ui.status(text)
      pinned.text = text
    }
  } catch {
    /* the line stays as it was; the next tick tries again */
  }
}

export const register: Register = on => {
  const pinned: Pinned = { text: undefined }
  // The timer that ticks, which a later session.start stops before it starts its own:
  // session.start fires again on a reload or a worker respawn, and timers must not
  // stack.
  let timer: Timer | undefined

  on('session.start', async ($, e, next) => {
    try {
      const paths = await locate($)
      await refresh($, paths, pinned)
      timer?.cancel()
      timer = $.clock.every(REFRESH_MS, () => {
        void refresh($, paths, pinned)
      })
    } catch {
      /* nothing here may fail a session start */
    }

    return next(e)
  })
}
