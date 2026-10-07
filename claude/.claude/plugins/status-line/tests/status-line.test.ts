// Run with `claude plugin test <this mod's folder>`. Each test stands in for the
// world beneath the mod (the three files it reads, `printenv` and `id`, the clock)
// and reads back what the mod pins with `$.ui.status`.
import { describe, expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

// The mod's refresh interval, the age past which it calls the API count unknown,
// and where the mocked clock starts (2023-11-14T22:13:20Z).
const REFRESH_MS = 5000
const API_STALE_S = 15
const T0 = 1_700_000_000_000
const NOW_S = T0 / 1000
// A week window's end as statusline-command.sh spells it, long after T0: a figure
// with it is inside its window.
const WINDOW_END = '2026-10-08T12:00:00Z'

const HOME = '/home/tester'
const RUN = '/run/user/1234'
const WEEK_FILE = `${HOME}/.local/state/claude-usage/statusline-limits.json`
const FIGURES_FILE = `${HOME}/.local/state/claude-usage/week.json`
const API_FILE = `${RUN}/tmux-sysstat/api-held`

// statusline-limits.json as statusline-command.sh writes it: `pct` the week's figure,
// `resetsAt` the end of its window, `fetchedAtMs` when the file last changed.
const weekFile = (pct: unknown, resetsAt: unknown = WINDOW_END, fetchedAtMs: unknown = T0 - 60_000) =>
  JSON.stringify({
    fetchedAtMs,
    utilization: {
      five_hour: { utilization: 22, resets_at: '2026-10-05T10:30:00Z' },
      seven_day: { utilization: pct, resets_at: resetsAt },
    },
  })
// api-held as tmux-sysstat-api writes it, "<epoch seconds> <held> <open> <warm>",
// dated `ageS` seconds before the clock starts.
const apiFile = (held: number, warm: number, ageS = 1) =>
  `${NOW_S - ageS} ${held} ${held} ${warm}\n`
// The same two files as their writers keep them for as long as they run: dated at
// the moment they are read.
const liveWeek = (pct: number) => (now: number) => weekFile(pct, WINDOW_END, now - 60_000)
const liveApi = (held: number, warm = 1) => (now: number) =>
  `${Math.floor(now / 1000)} ${held} ${held} ${warm}\n`

// The world beneath the mod, and a record of everything the mod asked of it.
type Given = {
  // What $.fs.read answers from, a file's text or a function of the time it is read
  // at; a path not here is missing.
  files: Record<string, string | ((now: number) => string)>
  // What `printenv NAME` prints; a name not here is unset (exit 1).
  env?: Record<string, string>
  // What `id -u` prints; it fails when absent.
  uid?: string
  // Where the mocked clock starts, in ms; T0 when absent.
  now?: number
  // Every read, every command, or every status line fails beneath the mod.
  failReads?: boolean
  failRuns?: boolean
  refuseStatus?: boolean
}
type World = Required<Pick<Given, 'files' | 'env'>> &
  Given & { asked: string[]; pinned: (string | undefined)[] }

function stage(on: On, given: Given) {
  const world: World = {
    env: { HOME, XDG_RUNTIME_DIR: RUN },
    uid: '1234\n',
    ...given,
    asked: [],
    pinned: [],
  }
  const clock = mock.clock(on, { now: world.now ?? T0 })
  on('fs.read', (_$, e) => {
    world.asked.push(`read ${e.path}`)
    if (world.failReads) throw new Error('the disk is gone')
    const file = world.files[e.path]
    if (file === undefined) return { deny: `ENOENT: ${e.path}` }
    return { value: typeof file === 'function' ? file(clock.now()) : file }
  })
  on('process.run', (_$, e) => {
    world.asked.push(`run ${e.argv.join(' ')}`)
    if (world.failRuns) throw new Error('cannot start')
    const [cmd, arg] = e.argv
    let stdout: string | undefined
    if (cmd === 'printenv' && arg !== undefined) {
      const value = world.env[arg]
      stdout = value === undefined ? undefined : `${value}\n`
    } else if (cmd === 'id' && arg === '-u') {
      stdout = world.uid
    }
    return {
      value: {
        exitCode: stdout === undefined ? 1 : 0,
        stdout: stdout ?? '',
        stderr: '',
        isStdoutTruncated: false,
        isStderrTruncated: false,
      },
    }
  })
  // The mod only reads: a write is recorded, so a test can see it, and refused.
  on('fs.write', (_$, e) => {
    world.asked.push(`write ${e.path}`)
    return { deny: 'this mod only reads' }
  })
  on('ui.status', (_$, e) => {
    if (world.refuseStatus) return { deny: 'no status line here' }
    world.pinned.push(e.text)
    return { value: undefined }
  })
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  return { world, clock }
}

// A session starting, which is also what a reload or a worker respawn raises.
const start = ($: Engine) =>
  $.session.start({ cwd: '/w', surface: 'terminal', isInteractive: true })

describe('the line', () => {
  test("shows today's points, the week and the API ports side by side, and reads those three files and no others", async ($, on) => {
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
    })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
    expect(world.asked).toEqual([
      'run printenv HOME',
      'run printenv XDG_RUNTIME_DIR',
      `read ${WEEK_FILE}`,
      `read ${FIGURES_FILE}`,
      `read ${API_FILE}`,
    ])
  })

  test('shows the week figure, not the 5-hour one beside it', async ($, on) => {
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(41), [API_FILE]: apiFile(0, 1) },
    })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 41% · api 0/64'])
  })

  test('0 is a figure, in either half', async ($, on) => {
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(0), [API_FILE]: apiFile(0, 1) },
    })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 0% · api 0/64'])
  })

  // claude-usage prints {pct:g}: a whole figure without a decimal point, another to six
  // digits at most.
  const percents: [string, string][] = [
    ['33', 'wk 33%'],
    ['33.0', 'wk 33%'],
    ['33.5', 'wk 33.5%'],
    ['33.456789', 'wk 33.4568%'],
    ['7.000000000000001', 'wk 7%'],
    ['100', 'wk 100%'],
  ]
  for (const [figure, shown] of percents) {
    test(`writes a percent of ${figure} as claude-usage does, ${shown}`, async ($, on) => {
      const raw = `{"fetchedAtMs": ${T0 - 1000}, "utilization": {"seven_day": {"utilization": ${figure}, "resets_at": "${WINDOW_END}"}}}`
      const { world } = stage(on, { files: { [WEEK_FILE]: raw, [API_FILE]: apiFile(1, 1) } })
      await start($)
      expect(world.pinned).toEqual([`day ? · ${shown} · api 1/64`])
    })
  }
})

describe('the API half', () => {
  // The chip's rule: exact when the watcher has run 120 s (warm 1), a floor before
  // that, and a floor too when the field is not there or not exactly 1.
  test('a count the watcher says is warm is exact', async ($, on) => {
    const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  test('a count that is not warm is a floor', async ($, on) => {
    const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 0) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16+/64'])
  })

  const at = NOW_S - 1
  const floors = [`${at} 16 16`, `${at} 16`, `${at} 16 16 2`, `${at} 16 16 true`, `${at} 16 16 1 extra`]
  for (const raw of floors) {
    test(`a floor too when the file says ${JSON.stringify(raw)}`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: raw } })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk 33% · api 16+/64'])
    })
  }

  test('a missing file is unknown, and the week half is still shown', async ($, on) => {
    const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api ?'])
  })

  // Not "<epoch> <n> ..." in digits: unknown, whatever else the line holds.
  const malformed = [
    '',
    '\n',
    'garbage',
    `abc 16 16 1`,
    `${NOW_S - 1} x 16 1`,
    `${NOW_S - 1}`,
    `${NOW_S - 1} 16.5 16 1`,
    `-${NOW_S - 1} 16 16 1`,
    `${NOW_S - 1}.5 16 16 1`,
    `${NOW_S - 1} -16 16 1`,
    '{"held": 16}',
  ]
  for (const raw of malformed) {
    test(`a file that reads ${JSON.stringify(raw)} is unknown`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: raw } })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk 33% · api ?'])
    })
  }

  // The chip keeps a count while `now - at <= 15`.
  const aged: [number, string][] = [
    [0, 'api 16/64'],
    [API_STALE_S, 'api 16/64'],
    [API_STALE_S + 1, 'api ?'],
    [3600, 'api ?'],
  ]
  for (const [ageS, shown] of aged) {
    test(`a file ${ageS} s old reads "${shown}"`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1, ageS) } })
      await start($)
      expect(world.pinned).toEqual([`day ? · wk 33% · ${shown}`])
    })
  }

  // The chip does the same; api-headroom is stricter. Whatever a clock stepped back
  // leaves is gone at the watcher's next write, within 5 s.
  test('a file dated ahead of the clock is read, as the chip reads it', async ($, on) => {
    const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1, -60) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  // The watcher rewrites the file every 5 s at least, so a mod that reads every 5 s
  // sees it going stale the way the chip does, 15 s after the watcher stops.
  test('a watcher that stops reads as unknown within 20 s', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: apiFile(16, 1, 0) },
    })
    await start($)
    await clock.advance(API_STALE_S * 1000)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64', 'day ? · wk 33% · api ?'])
  })
})

describe('the week half', () => {
  test('a missing file is unknown, and the API half is still shown', async ($, on) => {
    const { world } = stage(on, { files: { [API_FILE]: apiFile(16, 1) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk ? · api 16/64'])
  })

  const notFigures: [string, string][] = [
    ['empty', ''],
    ['not JSON', 'not json'],
    ['cut off', '{"fetchedAtMs": 1700000000000, "utilization": {'],
    ['null', 'null'],
    ['a list', '[]'],
    ['a string', '"33"'],
    ['a number', '33'],
    ['an empty object', '{}'],
    ['no utilization', JSON.stringify({ fetchedAtMs: T0 - 1000 })],
    ['a number for utilization', JSON.stringify({ fetchedAtMs: T0 - 1000, utilization: 33 })],
    [
      'no seven_day',
      JSON.stringify({ fetchedAtMs: T0 - 1000, utilization: { five_hour: { utilization: 22 } } }),
    ],
    ['a null seven_day', JSON.stringify({ fetchedAtMs: T0 - 1000, utilization: { seven_day: null } })],
    ['a figure that is a string', weekFile('33')],
    ['a figure that is null', weekFile(null)],
    ['a figure that is true', weekFile(true)],
    ['a figure that is an object', weekFile({ percent: 33 })],
    ['a negative figure', weekFile(-1)],
    ['a figure out of range', `{"fetchedAtMs": ${T0 - 1000}, "utilization": {"seven_day": {"utilization": 1e999}}}`],
  ]
  for (const [what, raw] of notFigures) {
    test(`a file that holds ${what} is unknown`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: raw, [API_FILE]: apiFile(16, 1) } })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk ? · api 16/64'])
    })
  }

})

// A figure holds for as long as its window runs. The file is rewritten only when a
// figure changes, so its age (fetchedAtMs) says nothing about the figure; what ends it
// is resets_at, the end of the window it belongs to.
describe("the week's window", () => {
  const ages: [string, number][] = [
    ['a minute', 60_000],
    ['31 minutes', 31 * 60_000],
    ['6 hours', 6 * 3600_000],
    ['3 days', 3 * 86_400_000],
  ]
  for (const [how, ageMs] of ages) {
    test(`a figure that last changed ${how} ago is shown while its window runs`, async ($, on) => {
      const { world } = stage(on, {
        files: { [WEEK_FILE]: weekFile(33, WINDOW_END, T0 - ageMs), [API_FILE]: apiFile(16, 1) },
      })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
    })
  }

  // fetchedAtMs is not read at all: what it holds, or that it is missing, changes nothing.
  const fetchTimes: [string, string][] = [
    ['missing', JSON.stringify({ utilization: { seven_day: { utilization: 33, resets_at: WINDOW_END } } })],
    ['a string', weekFile(33, WINDOW_END, String(T0 - 1000))],
    ['null', weekFile(33, WINDOW_END, null)],
    ['a day ahead of the clock', weekFile(33, WINDOW_END, T0 + 86_400_000)],
  ]
  for (const [what, raw] of fetchTimes) {
    test(`a figure whose file has a fetch time that is ${what} is shown`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: raw, [API_FILE]: apiFile(16, 1) } })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
    })
  }

  // The window has ended once resets_at is not after the clock.
  const ended: [string, string][] = [
    ['now', new Date(T0).toISOString()],
    ['a millisecond ago', new Date(T0 - 1).toISOString()],
    ['a second ago', new Date(T0 - 1000).toISOString()],
    ['a day ago', new Date(T0 - 86_400_000).toISOString()],
  ]
  for (const [when, resetsAt] of ended) {
    test(`a figure whose window ended ${when} (${resetsAt}) reads "wk ?"`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33, resetsAt), [API_FILE]: apiFile(16, 1) } })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk ? · api 16/64'])
    })
  }

  test('a figure whose window ends a millisecond from now is shown', async ($, on) => {
    const resetsAt = new Date(T0 + 1).toISOString()
    const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33, resetsAt), [API_FILE]: apiFile(16, 1) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  // With nothing to compare the figure with, it is shown: resets_at missing, or not one of
  // the shapes read below. Past ones among these would end the figure if a time that
  // Date.parse alone makes of "5", "2023" or a time with no offset were taken for one.
  const noEnd: [string, string][] = [
    ['missing', JSON.stringify({ fetchedAtMs: T0 - 1000, utilization: { seven_day: { utilization: 33 } } })],
    ['null', weekFile(33, null)],
    ['a number', weekFile(33, T0 - 1000)],
    ['an object', weekFile(33, {})],
    ['empty', weekFile(33, '')],
    ['not a time', weekFile(33, 'soon')],
    ['a bare number', weekFile(33, '5')],
    ['a bare year', weekFile(33, '2023')],
    ['a date with no time', weekFile(33, '2023-11-14')],
    ['a time with no offset', weekFile(33, '2023-11-14T22:13:19')],
    ['a spelled-out date', weekFile(33, 'Nov 14 2023')],
    ['a month that is no month', weekFile(33, '2023-13-45T99:99:99Z')],
  ]
  for (const [what, raw] of noEnd) {
    test(`a figure whose resets_at is ${what} is shown`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: raw, [API_FILE]: apiFile(16, 1) } })
      await start($)
      expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
    })
  }

  // The shapes resets_at has: a Z or an offset, a whole second or a fraction of any
  // length. Each is read, which the ones in the past show: a time that was not read
  // would leave the figure shown.
  const shapes: [string, string][] = [
    ['2023-11-14T22:13:19Z', 'wk ?'],
    ['2023-11-14T22:13:21Z', 'wk 33%'],
    ['2023-11-14T22:13:19.828970+00:00', 'wk ?'],
    ['2023-11-14T22:13:20.828970+00:00', 'wk 33%'],
    ['2023-11-14T22:13:19.9Z', 'wk ?'],
    ['2023-11-14T22:13:20.9Z', 'wk 33%'],
    ['2023-11-14T22:13:19.999999999Z', 'wk ?'],
    ['2023-11-15T00:13:19+02:00', 'wk ?'],
    ['2023-11-15T00:13:21+02:00', 'wk 33%'],
    ['2023-11-14T20:13:19-02:00', 'wk ?'],
    ['2023-11-14T20:13:21-02:00', 'wk 33%'],
  ]
  for (const [resetsAt, shown] of shapes) {
    test(`a window end of ${resetsAt} reads "${shown}"`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33, resetsAt), [API_FILE]: apiFile(16, 1) } })
      await start($)
      expect(world.pinned).toEqual([`day ? · ${shown} · api 16/64`])
    })
  }

  // A fraction is a fraction whatever its length: ".9" is 900 ms and ".50" is 500, so with
  // the clock part-way through that second the window still runs.
  const fractions: [string, number, string][] = [
    ['2023-11-14T22:13:20.9Z', T0 + 500, 'wk 33%'],
    ['2023-11-14T22:13:20.9Z', T0 + 901, 'wk ?'],
    ['2023-11-14T22:13:20.50Z', T0 + 100, 'wk 33%'],
    ['2023-11-14T22:13:20.50Z', T0 + 501, 'wk ?'],
    ['2023-11-14T22:13:20.5000009Z', T0 + 499, 'wk 33%'],
  ]
  for (const [resetsAt, now, shown] of fractions) {
    test(`${resetsAt} with the clock ${now - T0} ms past 22:13:20 reads "${shown}"`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33, resetsAt), [API_FILE]: liveApi(16) }, now })
      await start($)
      expect(world.pinned).toEqual([`day ? · ${shown} · api 16/64`])
    })
  }

  // The two shapes exactly as the files hold them (statusline-limits.json's, and /usage's
  // as claude-usage keeps it in plan.json), with the clock put on either side of them.
  const Z_END = Date.parse('2026-10-08T12:00:00.000Z')
  const MICRO_END = Date.parse('2026-10-08T11:59:59.828Z') // the milliseconds of ...59.828970
  const verbatim: [string, number, string][] = [
    ['2026-10-08T12:00:00Z', Z_END - 1, 'wk 33%'],
    ['2026-10-08T12:00:00Z', Z_END, 'wk ?'],
    ['2026-10-08T12:00:00Z', Z_END + 1, 'wk ?'],
    ['2026-10-08T11:59:59.828970+00:00', MICRO_END - 1, 'wk 33%'],
    ['2026-10-08T11:59:59.828970+00:00', MICRO_END + 1, 'wk ?'],
  ]
  for (const [resetsAt, now, shown] of verbatim) {
    test(`${resetsAt} with the clock at ${new Date(now).toISOString()} reads "${shown}"`, async ($, on) => {
      const { world } = stage(on, { files: { [WEEK_FILE]: weekFile(33, resetsAt), [API_FILE]: liveApi(16) }, now })
      await start($)
      expect(world.pinned).toEqual([`day ? · ${shown} · api 16/64`])
    })
  }

  test('a window that ends while the line is up turns it to "wk ?", and the next window\'s figure is shown once the file is rewritten', async ($, on) => {
    // Ends between the second tick (10 s) and the third (15 s).
    const ends = new Date(T0 + 12_000).toISOString()
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: weekFile(80, ends), [API_FILE]: liveApi(16) },
    })
    await start($)
    await clock.advance(2 * REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 80% · api 16/64'])

    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 80% · api 16/64', 'day ? · wk ? · api 16/64'])

    world.files[WEEK_FILE] = weekFile(1, new Date(T0 + 7 * 86_400_000).toISOString())
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 80% · api 16/64', 'day ? · wk ? · api 16/64', 'day ? · wk 1% · api 16/64'])
  })
})

// The day field counts from the box's local midnight, as claude-usage does, so these tests
// set the clock and the time of every figure from it and read the same in any time zone:
// the clock stands at noon on the day T0 falls on, and h(n) is n hours past that day's local
// midnight, before it when n is negative.
describe("today's points of the week", () => {
  const HOUR = 3_600_000
  const MIDNIGHT = new Date(T0).setHours(0, 0, 0, 0)
  const h = (hours: number) => MIDNIGHT + hours * HOUR
  const NOON = h(12)
  const NEXT_MIDNIGHT = new Date(MIDNIGHT).setHours(24, 0, 0, 0)
  // The window every figure is in unless it says otherwise, which is still running at noon,
  // and the two either side of a weekly reset at 05:00 that day.
  const END = Date.parse(WINDOW_END)
  const OLD_END = h(5)
  const NEW_END = OLD_END + 7 * 24 * HOUR

  // A weekly figure as week.json keeps it: [fetched, percent, the end of its window].
  type Row = [fetched: number, pct: number, resets: number | null]
  // statusline-limits.json with `cur` for its figure and `previous` for the one it held
  // before the local day it last replaced them on, the window ends spelled in whole seconds
  // with a Z as statusline-command.sh spells them.
  const limitsFile = (cur: Row, previous?: Row) => {
    const held = ([fetchedAtMs, pct, resets]: Row) => ({
      fetchedAtMs,
      utilization: {
        seven_day: {
          utilization: pct,
          resets_at: resets === null ? null : new Date(resets).toISOString().replace('.000Z', 'Z'),
        },
      },
    })
    return JSON.stringify({ ...held(cur), ...(previous === undefined ? {} : { previous: held(previous) }) })
  }
  const figuresFile = (...entries: unknown[]) => JSON.stringify({ figures: entries })
  // The line pinned when the session starts, from these files and the clock at noon.
  const lineWith = async ($: Engine, on: On, files: Given['files']) => {
    const { world } = stage(on, { files: { [API_FILE]: liveApi(16), ...files }, now: NOON })
    await start($)
    return world.pinned
  }

  // Each: what is counted, the figures week.json holds, the figure shown, and the field.
  const counts: [what: string, rows: Row[], cur: Row, day: string, previous?: Row][] = [
    [
      "counts from the last figure before local midnight, not an older one or today's first",
      [[h(-30), 30, END], [h(-1), 43, END], [h(2), 44, END]],
      [h(10), 46, END],
      'day 3%',
    ],
    [
      "with none before local midnight, counts from today's first figure, not the latest earlier one",
      [[h(1), 40, END], [h(5), 42, END]],
      [h(10), 45, END],
      'day 5%',
    ],
    [
      "takes a figure at local midnight for today's",
      [[h(-1), 30, END], [h(0), 40, END]],
      [h(10), 45, END],
      'day 15%',
    ],
    [
      'takes a figure a millisecond before local midnight for one before it',
      [[h(-1), 30, END], [h(0) - 1, 40, END]],
      [h(10), 45, END],
      'day 5%',
    ],
    [
      'gives 0 for a figure that has not risen since the last one before local midnight',
      [[h(-1), 45, END]],
      [h(10), 45, END],
      'day 0%',
    ],
    [
      'gives 0, not a negative rise, for a figure below the one it counts from',
      [[h(-1), 50, END]],
      [h(10), 44, END],
      'day 0%',
    ],
    ["has nothing to count from when the figure shown is today's first", [], [h(10), 45, END], 'day ?'],
    [
      "has nothing to count from when the figure shown only repeats today's first",
      [[h(1), 45, END]],
      [h(10), 45, END],
      'day ?',
    ],
    [
      'takes a repeat whose window ends less than an hour apart for a repeat',
      [[h(1), 45, END + 30 * 60_000]],
      [h(10), 45, END],
      'day ?',
    ],
    [
      'has nothing to count from when the figure shown is not from today',
      [[h(-30), 40, END], [h(-1), 43, END]],
      [h(0) - 1, 44, END],
      'day ?',
    ],
    ['takes a figure fetched at local midnight for one from today', [[h(-1), 43, END]], [h(0), 44, END], 'day 1%'],
    [
      'does not count a figure fetched after the one shown',
      [[h(-1), 43, END], [h(11), 50, END]],
      [h(10), 44, END],
      'day 1%',
    ],
    ['writes a fraction of a point as claude-usage writes a percent', [[h(-1), 43.1, END]], [h(10), 44.3, END], 'day 1.2%'],

    // Across the weekly reset at 05:00: the old window's points after the base and the new
    // window's figure, which is all its points when nothing of the old window came after.
    [
      "across the weekly reset, adds the old window's rise after the base to the new window's figure",
      [[h(-2), 60, OLD_END], [h(2), 75, OLD_END]],
      [h(10), 4, NEW_END],
      'day 19%',
    ],
    [
      "counts the old window's rise to its last figure",
      [[h(-2), 60, OLD_END], [h(1), 70, OLD_END], [h(3), 75, OLD_END]],
      [h(10), 4, NEW_END],
      'day 19%',
    ],
    [
      "counts an old window's fall as 0",
      [[h(-2), 60, OLD_END], [h(2), 58, OLD_END]],
      [h(10), 4, NEW_END],
      'day 4%',
    ],
    [
      "across the weekly reset with no figure of the old window after the base, gives the new window's figure",
      [[h(-2), 60, OLD_END]],
      [h(10), 4, NEW_END],
      'day 4%',
    ],
    [
      "does not take a figure of another window for the old window's",
      [[h(-2), 60, OLD_END], [h(2), 75, OLD_END + 14 * 24 * HOUR]],
      [h(10), 4, NEW_END],
      'day 4%',
    ],
    [
      "does not take a figure with no window end for the old window's",
      [[h(-2), 60, OLD_END], [h(2), 75, null]],
      [h(10), 4, NEW_END],
      'day 4%',
    ],
    [
      "counts an old window's figure fetched together with the one shown",
      [[h(-2), 60, OLD_END], [h(10), 75, OLD_END]],
      [h(10), 4, NEW_END],
      'day 19%',
    ],
    [
      'does not take a figure fetched together with the base for one after it',
      [[h(1), 60, OLD_END], [h(1), 70, OLD_END]],
      [h(10), 4, NEW_END],
      'day 4%',
    ],
    [
      "takes the same percent in another window for the new window's figure, not a repeat",
      [[h(1), 4, OLD_END]],
      [h(10), 4, NEW_END],
      'day 4%',
    ],
    // Two window ends are one window's when they are less than an hour apart or either is
    // unknown.
    [
      'takes two window ends a millisecond short of an hour apart for one window',
      [[h(-1), 43, END - (HOUR - 1)]],
      [h(10), 44, END],
      'day 1%',
    ],
    [
      'takes two window ends exactly an hour apart for two windows',
      [[h(-1), 43, END - HOUR]],
      [h(10), 44, END],
      'day 44%',
    ],
    ['takes an unknown window end for any window', [[h(-1), 43, null]], [h(10), 44, END], 'day 1%'],
    ['takes an unknown window end on the figure shown for any window', [[h(-1), 43, END]], [h(10), 44, null], 'day 1%'],
    [
      "takes a base whose window ends after the figure shown's for the same window",
      [[h(-1), 40, END + 7 * 24 * HOUR]],
      [h(10), 44, END],
      'day 4%',
    ],

    // Figures in week.json and in the limits file are sorted together by fetch time, then
    // window end (an unknown one first), then percent.
    [
      "takes the limits file's previous for the figure before local midnight when week.json has none",
      [],
      [h(10), 44, END],
      'day 1%',
      [h(-5), 43, END],
    ],
    [
      'takes a later figure from week.json before local midnight over previous',
      [[h(-1), 42, END]],
      [h(10), 44, END],
      'day 2%',
      [h(-5), 43, END],
    ],
    [
      'does not need week.json in order',
      [[h(2), 44, END], [h(-1), 43, END], [h(-30), 30, END]],
      [h(10), 46, END],
      'day 3%',
    ],
    [
      'sorts figures fetched together by percent',
      [[h(-1), 45, END], [h(-1), 43, END]],
      [h(10), 46, END],
      'day 1%',
    ],
    [
      'sorts figures fetched together with one percent by window end',
      [[h(-1), 43, NEW_END], [h(-1), 43, OLD_END]],
      [h(10), 44, NEW_END],
      'day 1%',
    ],
    // The unknown end sorts first, so the 43 is the base. Sorted by percent alone the 45 comes
    // last, is taken for the base, and matches any window: the day reads 0.
    [
      'sorts an unknown window end before any known one',
      [[h(-1), 43, END], [h(-1), 45, null]],
      [h(10), 44, END],
      'day 1%',
    ],

    // Then, as week_figures does, a figure is let go when it was fetched more than 8 days
    // before the clock, or when it only repeats the one kept before it: the same percent in
    // the same window, an unknown window end being any window.
    [
      'keeps a figure fetched exactly 8 days before the clock',
      [[NOON - 8 * 24 * HOUR, 40, END]],
      [h(10), 44, END],
      'day 4%',
    ],
    [
      'lets go a figure fetched a millisecond more than 8 days before the clock',
      [[NOON - 8 * 24 * HOUR - 1, 40, END]],
      [h(10), 44, END],
      'day ?',
    ],
    [
      'lets go a figure that only repeats the one before it, though its window end is unknown',
      [[h(-2), 60, OLD_END]],
      [h(10), 4, NEW_END],
      'day 4%',
      [h(-1), 60, null],
    ],
    [
      'keeps a figure with the same percent in another window',
      [[h(-2), 60, OLD_END], [h(-1), 60, NEW_END]],
      [h(10), 70, NEW_END],
      'day 10%',
    ],
    [
      'compares a figure with the one kept before it, not with a repeat that was let go',
      [[h(-4), 60, END], [h(-3), 60, END + 50 * 60_000], [h(-1), 60, END + 100 * 60_000]],
      [h(10), 70, END + 100 * 60_000],
      'day 10%',
    ],
  ]
  for (const [what, rows, cur, day, previous] of counts) {
    test(`${what}: "${day}"`, async ($, on) => {
      const pinned = await lineWith($, on, {
        [WEEK_FILE]: limitsFile(cur, previous),
        [FIGURES_FILE]: figuresFile(...rows),
      })
      expect(pinned).toEqual([`${day} · wk ${cur[1]}% · api 16/64`])
    })
  }

  test('the full line: the day, the week and the API ports', async ($, on) => {
    const pinned = await lineWith($, on, {
      [WEEK_FILE]: limitsFile([h(10), 44, END]),
      [FIGURES_FILE]: figuresFile([h(-1), 43, END]),
      [API_FILE]: liveApi(23),
    })
    expect(pinned).toEqual(['day 1% · wk 44% · api 23/64'])
  })

  // The limits file's figure and the one under `previous` are all there is when week.json
  // is missing.
  test("the limits file's previous is the base when week.json is missing", async ($, on) => {
    const pinned = await lineWith($, on, { [WEEK_FILE]: limitsFile([h(10), 44, END], [h(-5), 43, END]) })
    expect(pinned).toEqual(['day 1% · wk 44% · api 16/64'])
  })

  // With no week.json and no previous, the figure shown is the only one on record.
  test('the figure shown is the only one on record: nothing to count from', async ($, on) => {
    const pinned = await lineWith($, on, { [WEEK_FILE]: limitsFile([h(10), 44, END]) })
    expect(pinned).toEqual(['day ? · wk 44% · api 16/64'])
  })

  // Figures that would be the base, but are not in a shape week_figures takes in: whole
  // fetch time and window end (or no end), the percent a number, a list of three.
  const notRows: [string, unknown][] = [
    ['two items', [h(-1), 10]],
    ['four items', [h(-1), 10, END, 0]],
    ['a percent that is a string', [h(-1), '10', END]],
    ['a percent that is true', [h(-1), true, END]],
    ['a percent that is null', [h(-1), null, END]],
    ['a percent below 0', [h(-1), -1, END]],
    ['a fetch time that is a string', [String(h(-1)), 10, END]],
    ['a fetch time that is not whole', [h(-1) + 0.5, 10, END]],
    ['a fetch time that is null', [null, 10, END]],
    ['a window end that is a string', [h(-1), 10, String(END)]],
    ['a window end that is not whole', [h(-1), 10, END + 0.5]],
    ['a window end that is true', [h(-1), 10, true]],
    ['an object', { fetched: h(-1), pct: 10, resets: END }],
    ['a string', 'x'],
    ['null', null],
    ['a number', 7],
    ['an empty list', []],
  ]
  for (const [what, entry] of notRows) {
    test(`an entry of week.json that is ${what} is left out`, async ($, on) => {
      const pinned = await lineWith($, on, {
        [WEEK_FILE]: limitsFile([h(10), 44, END]),
        [FIGURES_FILE]: figuresFile([h(-3), 43, END], entry),
      })
      expect(pinned).toEqual(['day 1% · wk 44% · api 16/64'])
    })
  }

  test('an entry of week.json whose percent is out of range is left out', async ($, on) => {
    const pinned = await lineWith($, on, {
      [WEEK_FILE]: limitsFile([h(10), 44, END]),
      [FIGURES_FILE]: `{"figures": [[${h(-3)}, 43, ${END}], [${h(-1)}, 1e999, ${END}]]}`,
    })
    expect(pinned).toEqual(['day 1% · wk 44% · api 16/64'])
  })

  // A week.json that cannot be used leaves the limits file's two figures, which are enough
  // here to count from.
  const notFiles: [string, string][] = [
    ['empty', ''],
    ['not JSON', 'not json'],
    ['cut off', `{"figures": [[${h(-1)}, 10,`],
    ['null', 'null'],
    ['a list', '[]'],
    ['an empty object', '{}'],
    ['a figures list that is a number', '{"figures": 5}'],
    ['a figures list that is an object', '{"figures": {}}'],
    ['a figures list that is null', '{"figures": null}'],
    ['a figures list that is a string', '{"figures": "x"}'],
  ]
  for (const [what, raw] of notFiles) {
    test(`a week.json that holds ${what} adds nothing`, async ($, on) => {
      const pinned = await lineWith($, on, {
        [WEEK_FILE]: limitsFile([h(10), 44, END], [h(-5), 43, END]),
        [FIGURES_FILE]: raw,
      })
      expect(pinned).toEqual(['day 1% · wk 44% · api 16/64'])
    })
  }

  // The figure under `previous` is used only when it holds a week figure and the time it
  // was fetched.
  const PREVIOUS = { fetchedAtMs: h(-5), utilization: { seven_day: { utilization: 43, resets_at: WINDOW_END } } }
  const notPrevious: [string, unknown][] = [
    ['null', null],
    ['a string', 'x'],
    ['an empty object', {}],
    ['no week figure', { ...PREVIOUS, utilization: { five_hour: { utilization: 58, resets_at: WINDOW_END } } }],
    ['a null week figure', { ...PREVIOUS, utilization: { seven_day: null } }],
    ['a fetch time that is a string', { ...PREVIOUS, fetchedAtMs: String(h(-5)) }],
    ['no fetch time', { utilization: PREVIOUS.utilization }],
    ['a percent that is a string', { ...PREVIOUS, utilization: { seven_day: { utilization: '43', resets_at: WINDOW_END } } }],
  ]
  for (const [what, previous] of notPrevious) {
    test(`a previous that is ${what} adds nothing`, async ($, on) => {
      const cur = JSON.parse(limitsFile([h(10), 44, END]))
      const pinned = await lineWith($, on, { [WEEK_FILE]: JSON.stringify({ ...cur, previous }) })
      expect(pinned).toEqual(['day ? · wk 44% · api 16/64'])
    })
  }

  // The popup lets a figure go once it is 8 days old, so a `previous` that old, left from
  // before a long idle, is not counted from: counting from it would give the whole of the new
  // window's figure as today's. The popup then has nothing to count from, and so has the line.
  test('a previous fetched more than 8 days ago is let go, as the popup lets it go', async ($, on) => {
    const pinned = await lineWith($, on, {
      [WEEK_FILE]: limitsFile([h(10), 44, h(48)], [h(-9 * 24), 40, h(-5 * 24)]),
    })
    expect(pinned).toEqual(['day ? · wk 44% · api 16/64'])
  })

  // A percent below 0 is no figure, as the week half takes it, so it is not counted from.
  test('a previous whose percent is below 0 is no figure', async ($, on) => {
    const pinned = await lineWith($, on, {
      [WEEK_FILE]: limitsFile([h(10), 44, h(48)], [h(-1), -1, h(48)]),
    })
    expect(pinned).toEqual(['day ? · wk 44% · api 16/64'])
  })

  // No number for the fetch time: nothing to place the figure by, whatever week.json holds.
  const noFetchTimes: [string, string][] = [
    ['missing', JSON.stringify({ utilization: { seven_day: { utilization: 44, resets_at: WINDOW_END } } })],
    ['a string', weekFile(44, WINDOW_END, String(h(10)))],
    ['null', weekFile(44, WINDOW_END, null)],
    ['true', weekFile(44, WINDOW_END, true)],
    ['a list', weekFile(44, WINDOW_END, [h(10)])],
  ]
  for (const [what, raw] of noFetchTimes) {
    test(`a figure whose fetch time is ${what} has no day, and the week half is shown`, async ($, on) => {
      const pinned = await lineWith($, on, {
        [WEEK_FILE]: raw,
        [FIGURES_FILE]: figuresFile([h(-1), 43, END]),
      })
      expect(pinned).toEqual(['day ? · wk 44% · api 16/64'])
    })
  }

  // Whenever the week half reads "wk ?" the day does too, though week.json holds a figure to
  // count from: nothing is counted of a figure that is not shown.
  const noWeeks: [string, Record<string, string>][] = [
    ['a missing limits file', {}],
    ['a limits file that is not JSON', { [WEEK_FILE]: 'not json' }],
    ['a figure that is a string', { [WEEK_FILE]: weekFile('44', WINDOW_END, h(10)) }],
    ['a negative figure', { [WEEK_FILE]: weekFile(-1, WINDOW_END, h(10)) }],
    [
      'a figure whose window has ended',
      {
        [WEEK_FILE]: weekFile(44, new Date(h(11)).toISOString(), h(10)),
        [FIGURES_FILE]: figuresFile([h(-1), 43, h(11)]),
      },
    ],
  ]
  for (const [what, files] of noWeeks) {
    test(`${what} gives "wk ?" and so "day ?"`, async ($, on) => {
      const pinned = await lineWith($, on, { [FIGURES_FILE]: figuresFile([h(-1), 43, END]), ...files })
      expect(pinned).toEqual(['day ? · wk ? · api 16/64'])
    })
  }

  test('a figure that changes between two ticks changes the day field too', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: limitsFile([h(10), 44, END], [h(-5), 43, END]), [API_FILE]: liveApi(16) },
      now: NOON,
    })
    await start($)
    world.files[WEEK_FILE] = limitsFile([NOON + 1000, 46, END], [h(-5), 43, END])
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day 1% · wk 44% · api 16/64', 'day 3% · wk 46% · api 16/64'])
  })

  // The figure shown is from yesterday once local midnight passes, and is not counted as
  // today's; the file is rewritten at the first new figure, holding yesterday's as previous.
  test('a day that ends while the line is up turns the field to "day ?" until a figure of the new day', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: limitsFile([h(10), 44, END], [h(-5), 43, END]), [API_FILE]: liveApi(16) },
      now: NEXT_MIDNIGHT - 7000,
    })
    await start($)
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day 1% · wk 44% · api 16/64'])

    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day 1% · wk 44% · api 16/64', 'day ? · wk 44% · api 16/64'])

    world.files[WEEK_FILE] = limitsFile([NEXT_MIDNIGHT + 1000, 45, END], [h(10), 44, END])
    await clock.advance(REFRESH_MS)
    expect(world.pinned.at(-1)).toBe('day 1% · wk 45% · api 16/64')
  })
})

describe('ticks', () => {
  test('the files are read again every 5 seconds, and not before', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)
    world.asked.length = 0
    await clock.advance(REFRESH_MS - 1)
    expect(world.asked).toEqual([])
    await clock.advance(1)
    expect(world.asked).toEqual([`read ${WEEK_FILE}`, `read ${FIGURES_FILE}`, `read ${API_FILE}`])
    await clock.advance(REFRESH_MS)
    expect(world.asked).toHaveLength(6)
  })

  test('a figure that changes between two ticks changes the line, either half', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])

    world.files[API_FILE] = liveApi(20)
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64', 'day ? · wk 33% · api 20/64'])

    world.files[WEEK_FILE] = liveWeek(34)
    await clock.advance(REFRESH_MS)
    expect(world.pinned.at(-1)).toBe('day ? · wk 34% · api 20/64')

    world.files[API_FILE] = liveApi(21, 0)
    world.files[WEEK_FILE] = liveWeek(35)
    await clock.advance(REFRESH_MS)
    expect(world.pinned.at(-1)).toBe('day ? · wk 35% · api 21+/64')
    expect(world.pinned).toHaveLength(4)
  })

  test('a tick that finds the same text makes no ui.status call', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)
    world.asked.length = 0
    await clock.advance(3 * REFRESH_MS)
    // The three ticks did read all three files each ...
    expect(world.asked).toEqual([
      `read ${WEEK_FILE}`,
      `read ${FIGURES_FILE}`,
      `read ${API_FILE}`,
      `read ${WEEK_FILE}`,
      `read ${FIGURES_FILE}`,
      `read ${API_FILE}`,
      `read ${WEEK_FILE}`,
      `read ${FIGURES_FILE}`,
      `read ${API_FILE}`,
    ])
    // ... and the line was pinned once, by the start.
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  test('a file that goes away between ticks is unknown, and shown again when it is back', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)

    delete world.files[API_FILE]
    delete world.files[WEEK_FILE]
    await clock.advance(REFRESH_MS)
    expect(world.pinned.at(-1)).toBe('day ? · wk ? · api ?')

    world.files[API_FILE] = liveApi(16)
    world.files[WEEK_FILE] = liveWeek(33)
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64', 'day ? · wk ? · api ?', 'day ? · wk 33% · api 16/64'])
  })

  test('a file that is missing when the session starts is picked up once it appears', async ($, on) => {
    const { world, clock } = stage(on, { files: {} })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk ? · api ?'])

    world.files[WEEK_FILE] = liveWeek(33)
    world.files[API_FILE] = liveApi(16)
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk ? · api ?', 'day ? · wk 33% · api 16/64'])
  })
})

describe('timers', () => {
  // session.start fires again on a reload or a worker respawn. One timer ticks every
  // 5 s and reads three files, so a second one would read six.
  test('a second session.start leaves exactly one timer', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)
    await start($)
    world.asked.length = 0

    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${WEEK_FILE}`, `read ${FIGURES_FILE}`, `read ${API_FILE}`])
    await clock.advance(2 * REFRESH_MS)
    expect(world.asked).toHaveLength(9)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  test('so does a third', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)
    await start($)
    await start($)
    world.asked.length = 0

    await clock.advance(REFRESH_MS)
    expect(world.asked).toHaveLength(3)
  })

  // Both are still finding their files when the other arrives: the old timer is
  // stopped and the new one started in one step, after that wait, so neither start
  // can leave its timer behind unseen.
  test('two session.starts in flight together leave one timer too', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await Promise.all([start($), start($)])
    world.asked.length = 0

    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${WEEK_FILE}`, `read ${FIGURES_FILE}`, `read ${API_FILE}`])
  })

  test('the timer a session.start leaves is the new one: it reads where that start found the files', async ($, on) => {
    const OTHER = '/home/other/.local/state/claude-usage/statusline-limits.json'
    const OTHER_FIGURES = '/home/other/.local/state/claude-usage/week.json'
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: liveWeek(33), [OTHER]: liveWeek(50), [API_FILE]: liveApi(16) },
    })
    await start($)
    world.env.HOME = '/home/other'
    await start($)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64', 'day ? · wk 50% · api 16/64'])
    world.asked.length = 0

    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${OTHER}`, `read ${OTHER_FIGURES}`, `read ${API_FILE}`])
  })
})

describe('where the files are', () => {
  test('the runtime folder falls back to /run/user/<uid> when XDG_RUNTIME_DIR is not set', async ($, on) => {
    const API = '/run/user/4321/tmux-sysstat/api-held'
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [API]: apiFile(16, 1) },
      env: { HOME },
      uid: '4321\n',
    })
    await start($)
    expect(world.asked).toEqual([
      'run printenv HOME',
      'run printenv XDG_RUNTIME_DIR',
      'run id -u',
      `read ${WEEK_FILE}`,
      `read ${FIGURES_FILE}`,
      `read ${API}`,
    ])
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  test('XDG_RUNTIME_DIR is used, and `id -u` not asked, when it is an absolute path', async ($, on) => {
    const RUN2 = '/var/run/tester'
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [`${RUN2}/tmux-sysstat/api-held`]: apiFile(16, 1) },
      env: { HOME, XDG_RUNTIME_DIR: RUN2 },
    })
    await start($)
    expect(world.asked).not.toContain('run id -u')
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
  })

  // The folder becomes part of a path. A value that is not an absolute path with no
  // newline is not used at all: no path is built from it, and the runtime folder is
  // then /run/user/<uid>, as with the variable unset.
  const notFolders = [
    'run/user/1234',
    'relative',
    '.',
    '..',
    '',
    '~/run',
    ' /run/user/1234',
    'C:\\run',
    '/run/user/1234\nx',
    '/run\n/user/1234',
    'file:///run/user/1234',
  ]
  for (const bad of notFolders) {
    test(`XDG_RUNTIME_DIR=${JSON.stringify(bad)} is not used`, async ($, on) => {
      const { world } = stage(on, {
        files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
        env: { HOME, XDG_RUNTIME_DIR: bad },
      })
      await start($)
      expect(world.asked).toEqual([
        'run printenv HOME',
        'run printenv XDG_RUNTIME_DIR',
        'run id -u',
        `read ${WEEK_FILE}`,
        `read ${FIGURES_FILE}`,
        `read ${API_FILE}`,
      ])
      expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64'])
    })
  }

  // /run/user/<uid> is built from `id -u` only when that printed a number.
  const notUids = ['root', '', '12a', '-1', '12 34', '1234\n5678', ' 1234', '1.5']
  for (const bad of notUids) {
    test(`a user id that reads ${JSON.stringify(bad)} builds no path, and the API half is unknown`, async ($, on) => {
      const { world } = stage(on, {
        files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
        env: { HOME },
        uid: `${bad}\n`,
      })
      await start($)
      expect(world.asked).toEqual([
        'run printenv HOME',
        'run printenv XDG_RUNTIME_DIR',
        'run id -u',
        `read ${WEEK_FILE}`,
        `read ${FIGURES_FILE}`,
      ])
      expect(world.pinned).toEqual(['day ? · wk 33% · api ?'])
    })
  }

  test('a failing `id -u` builds no path either', async ($, on) => {
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
      env: { HOME },
      uid: undefined, // `id -u` exits 1
    })
    await start($)
    expect(world.asked).not.toContain(`read ${API_FILE}`)
    expect(world.pinned).toEqual(['day ? · wk 33% · api ?'])
  })

  // The same rule for the home folder, which has no fallback: the week half is unknown.
  const notHomes = ['', 'tester', '~', '.', ' /home/tester', '/home/tester\nx']
  for (const bad of notHomes) {
    test(`HOME=${JSON.stringify(bad)} is not used, and the week half is unknown`, async ($, on) => {
      const { world } = stage(on, {
        files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
        env: { HOME: bad, XDG_RUNTIME_DIR: RUN },
      })
      await start($)
      expect(world.asked).toEqual(['run printenv HOME', 'run printenv XDG_RUNTIME_DIR', `read ${API_FILE}`])
      expect(world.pinned).toEqual(['day ? · wk ? · api 16/64'])
    })
  }

  test('HOME not set at all is the same', async ($, on) => {
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
      env: { XDG_RUNTIME_DIR: RUN },
    })
    await start($)
    expect(world.pinned).toEqual(['day ? · wk ? · api 16/64'])
  })
})

describe('display only', () => {
  test('session.start is answered as the engine answers it', async ($, on) => {
    stage(on, { files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) } })
    expect(await start($)).toEqual({ cwd: '/w' })
  })

  test('pins text and nothing else: never undefined, never a second line', async ($, on) => {
    const { world, clock } = stage(on, { files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) } })
    await start($)
    delete world.files[API_FILE]
    await clock.advance(REFRESH_MS)
    world.files[API_FILE] = liveApi(17, 0)
    await clock.advance(REFRESH_MS)
    expect(world.pinned.length).toBe(3)
    for (const text of world.pinned) expect(text).toMatch(/^day (\d+%|\?) · wk (\d+%|\?) · api (\d+\+?\/64|\?)$/)
  })

  // Nothing beneath the mod works: no command runs, no file reads. The session starts
  // as it would, the line says so in both halves, and no tick throws either.
  test('nothing may throw out of the hook or the timer: every failure is "?" in its half', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
      failReads: true,
      failRuns: true,
    })
    expect(await start($)).toEqual({ cwd: '/w' })
    expect(world.pinned).toEqual(['day ? · wk ? · api ?'])
    await clock.advance(3 * REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk ? · api ?'])
  })

  test('reads that start failing between ticks turn the line to "?", and it comes back when they work again', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) },
    })
    await start($)
    world.failReads = true
    await clock.advance(REFRESH_MS)
    expect(world.pinned).toEqual(['day ? · wk 33% · api 16/64', 'day ? · wk ? · api ?'])
    world.failReads = false
    await clock.advance(REFRESH_MS)
    expect(world.pinned.at(-1)).toBe('day ? · wk 33% · api 16/64')
  })

  test('commands that fail leave their halves unknown and the session starting', async ($, on) => {
    const { world } = stage(on, {
      files: { [WEEK_FILE]: weekFile(33), [API_FILE]: apiFile(16, 1) },
      failRuns: true,
    })
    expect(await start($)).toEqual({ cwd: '/w' })
    expect(world.asked).toEqual(['run printenv HOME', 'run printenv XDG_RUNTIME_DIR', 'run id -u'])
    expect(world.pinned).toEqual(['day ? · wk ? · api ?'])
  })

  test('a status line that is refused neither fails the session start nor stops the ticks', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: liveWeek(33), [API_FILE]: liveApi(16) },
      refuseStatus: true,
    })
    expect(await start($)).toEqual({ cwd: '/w' })
    world.asked.length = 0
    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${WEEK_FILE}`, `read ${FIGURES_FILE}`, `read ${API_FILE}`])
  })

  // week.json is the popup's to write, as the limits file is statusline-command.sh's.
  test('only reads: no file is written, week.json included', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [WEEK_FILE]: liveWeek(33), [FIGURES_FILE]: '{"figures": []}', [API_FILE]: liveApi(16) },
    })
    await start($)
    await clock.advance(2 * REFRESH_MS)
    expect(world.asked.filter(call => call.startsWith('write '))).toEqual([])
  })
})
