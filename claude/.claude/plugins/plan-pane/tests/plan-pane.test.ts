// Run with `claude plugin test <this mod's folder>`. Each test stands in for
// the world beneath the mod (the files it reads and lists, `printenv HOME` and
// `printenv CREW_NAME`, the clock, whether a pane may open) and reads back what
// the pane draws.
import { describe, expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

import type { PlanSnapshot, Target } from '../types'

// The home folder the sessions below run under, where the mod looks for the
// findings from it, the findings file of the crew member the sessions run as
// unless a test says otherwise (`gmp-deploy`), the mod's two intervals, and
// where the mocked clock starts.
const HOME = '/home/tester'
const FINDINGS = `${HOME}/.local/state/crew/findings`
const OWN = `${FINDINGS}/gmp-deploy.md`
const REFRESH_MS = 5000
const LOOK_MS = 60_000
const T0 = 1_700_000_000_000

// The two tables, laid out as a captain's findings file lays them out.
const MR_TABLE = [
  '## Plan: merge requests, in order',
  '',
  '| # | MR | id | Branch | Worktree in `$C` | Head | Pipeline | Next step | Go |',
  '| --- | --- | --- | --- | --- | --- | --- | --- | --- |',
]
const BLOCKED_LOG = [
  '## Decisions asked (BLOCKED log)',
  '',
  '| Id | Sent | Asks | Answer |',
  '| --- | --- | --- | --- |',
]
const mr = (n: number, ref: string, id: string, next: string, go = '', pipeline = '175053 passed') =>
  `| ${n} | ${ref} | ${id} | \`feat/${id}\` | \`feat_${id}\` | \`0f0f0f0f0\` | ${pipeline} | ${next} | ${go} |`
const ask = (id: string, sent: string, asks: string, answer: string) =>
  `| ${id} | ${sent} | ${asks} | ${answer} |`

const PLAN = [
  '# gmp-deploy findings',
  '',
  ...MR_TABLE,
  mr(1, '!4053', 'ksm', 'merged 14:02'),
  mr(2, '!4060', 'thanos', 'pipeline running, then ask for review', 'user go'),
  mr(3, 'new', 'alloy', 'not started: waits for thanos', 'B2'),
  mr(4, '!4011', 'otel', 'dropped: folded into alloy'),
  mr(5, '!4070', 'ruler', 'blocked on B1', 'B1'),
  '',
  '## Rollout plan after the design change (13:39)',
  '',
  'Prose between the tables.',
  '',
  ...BLOCKED_LOG,
  ask('B1', '10:37', 'Go to rebase ksm onto main?', 'open'),
  ask('B2', '11:05', 'Which registry for alloy?', ''),
  ask('B3', '11:40', 'Drop otel?', 'yes, 11:52'),
  '',
  '## Ships',
  '',
].join('\n')

// The world beneath the mod, and a record of everything the mod asked of it.
type Given = {
  // What $.fs.read answers from; a path not here is missing.
  files: Record<string, string>
  // The crew member the session runs as, `CREW_NAME`: the one whose findings
  // file is OWN unless a test says another, and null for no crew name at all.
  crew?: string | null
  // What `printenv NAME` prints beside those two; a name not here is unset.
  env?: Record<string, string>
  // What $.fs.list shows of the findings folder beside the files that are
  // directly in it: its subfolders, by name, and the files that are listed
  // but cannot be read.
  dirs?: string[]
  unreadable?: string[]
  // The size $.fs.list gives a file, when it is not the length of its text.
  sizes?: Record<string, number>
  // The ids of the panes the engine says are open when the session starts.
  panes?: string[]
  // A ui.open hook that refuses every pane.
  refuseOpen?: boolean
  // Calls that are never answered, as they appear in `asked`.
  hang?: string[]
}
type World = {
  files: Record<string, string>
  // What `printenv NAME` prints, by name; a name not here is unset (exit 1).
  env: Record<string, string>
  dirs?: string[]
  unreadable?: string[]
  sizes?: Record<string, number>
  panes?: string[]
  refuseOpen?: boolean
  hang?: string[]
  // While set, every read waits for it before it answers; `holds` does the
  // same for the reads of one path.
  gate?: Promise<void>
  holds?: Record<string, Promise<void>>
  // Every call the mod made on the world beneath it, as `read <path>`, `run
  // <argv>`, in order.
  asked: string[]
  commands: string[]
  // The id of every pane the mod asked to open, in order.
  opened: string[]
  // The period of every timer the mod asked for, in order (each one is asked
  // again as it goes off).
  timers: number[]
  // Every value the mod wrote to its own state, by key, in the order written.
  writes: { key: string; value: unknown }[]
  // While set, what the mod writes is rewritten into the shape the version
  // before this one wrote: the target a bare path with no record of how it was
  // chosen, the snapshot with no shape number, a read time and a signature of
  // its own. The test stands in for that version this way, as nothing but the
  // module itself may write its state.
  oldTarget?: boolean
  oldSnap?: boolean
}

function stage(on: On, given: Given) {
  const crew = given.crew === undefined ? 'gmp-deploy' : given.crew
  const world: World = {
    ...given,
    // Copies: a test that edits a file must not change what a later test is given.
    files: { ...given.files },
    env: { HOME, ...(crew === null ? {} : { CREW_NAME: crew }), ...given.env },
    asked: [],
    commands: [],
    opened: [],
    timers: [],
    writes: [],
  }
  // The first hook is the outermost: it sees every call and passes it on.
  on('*', (_$, e, next) => {
    if (next.event === 'clock.every') world.timers.push((e as { ms: number }).ms)
    if (next.event === 'state.set') {
      const written = e as { key: string; value: unknown }
      world.writes.push({ key: written.key, value: written.value })
      if (world.oldTarget && written.key === 'target' && written.value !== null) {
        return next({ ...written, value: (written.value as Target).file })
      }
      if (world.oldSnap && written.key === 'snap') {
        const kept = Object.entries(written.value as PlanSnapshot).filter(([k]) => k !== 'v')
        return next({ ...written, value: { ...Object.fromEntries(kept), sig: 'old', readAt: T0 } })
      }
    }
    return next(e)
  })
  const clock = mock.clock(on, { now: T0 })
  // Records a call, and never answers it when the test says it hangs.
  const ask = async (call: string) => {
    world.asked.push(call)
    if (world.hang?.includes(call)) await new Promise(() => {})
  }
  on('fs.read', async (_$, e) => {
    await ask(`read ${e.path}`)
    await world.gate
    await world.holds?.[e.path]
    if (world.unreadable?.includes(e.path)) return { deny: `EACCES: ${e.path}` }
    const text = world.files[e.path]
    return text === undefined ? { deny: `ENOENT: ${e.path}` } : { value: text }
  })
  // Only the findings folder exists. Its entries come back in an order of
  // their own, the reverse of name order, as a directory's may.
  on('fs.list', async (_$, e) => {
    await ask(`list ${e.path}`)
    if (e.path !== FINDINGS) return { deny: `ENOENT: ${e.path}` }
    const inside = (path: string) => path.startsWith(`${FINDINGS}/`) && !path.slice(FINDINGS.length + 1).includes('/')
    const entry = (path: string) => ({
      name: path.slice(FINDINGS.length + 1),
      kind: 'file' as const,
      size: world.sizes?.[path] ?? (world.files[path] ?? '').length,
      mtimeMs: T0,
      isLink: false,
    })
    const listed = [...Object.keys(world.files).filter(inside), ...(world.unreadable ?? [])].map(entry)
    const folders = (world.dirs ?? []).map(name => ({ name, kind: 'dir' as const, size: 0, mtimeMs: 0, isLink: false }))
    return { value: [...listed, ...folders].sort((a, b) => (a.name < b.name ? 1 : -1)) }
  })
  on('ui.panes', () => ({
    value: (world.panes ?? []).map(id => ({ id, title: 'Plan', isShown: true, isFocused: false, isPlaced: true })),
  }))
  on('process.run', async (_$, e) => {
    await ask(`run ${e.argv.join(' ')}`)
    const [cmd, name] = e.argv
    const printed = cmd === 'printenv' && name !== undefined ? world.env[name] : undefined
    return {
      value: {
        exitCode: printed === undefined ? 1 : 0,
        stdout: printed === undefined ? '' : `${printed}\n`,
        stderr: '',
        isStdoutTruncated: false,
        isStderrTruncated: false,
      },
    }
  })
  on('ui.open', (_$, e) => {
    world.opened.push(e.id)
    return world.refuseOpen ? { deny: 'no panes here' } : { value: { isPlaced: true } }
  })
  on('command.register', (_$, e) => {
    world.commands.push(e.name)
    return { value: { command: e.name } }
  })
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  // A session starting, then what that start left running unawaited going as
  // far as it can without the clock moving.
  const boot = async ($: Engine) => {
    const started = await start($)
    await clock.settle()
    return started
  }
  return { world, clock, boot }
}

// A session starting, which is also what a reload or a worker respawn raises.
const start = ($: Engine) =>
  $.session.start({ cwd: '/w', surface: 'terminal', isInteractive: true })

// `/plan-pane <args>`, as the person typing it raises it.
const planPane = ($: Engine, args: string) =>
  $.command.run({
    command: 'plan-pane',
    args,
    origin: { kind: 'composer' },
    presentation: { isFullscreen: true, columns: 150 },
  })

// The pane as a terminal `rows` tall draws it.
const mountPane = ($: Engine, rows = 40) =>
  $.ui.mount({
    plugin: 'plan-pane',
    surface: 'terminal',
    component: 'Pane',
    requestId: 'plan',
    props: {
      title: 'Plan',
      isFocused: false,
      bodyColumns: 60,
      placement: 'dock',
      scroll: { offset: 0, bodyRows: rows },
      view: {},
    },
    viewport: { columns: 150, rows },
  })
type Pane = Awaited<ReturnType<typeof mountPane>>

// Every line of text the pane shows, top to bottom.
const shown = async (ui: Pane) => (await ui.findAll({ type: 'Text' })).map(t => t.text)
// The todo list's numbered lines alone, without each row's next step.
const todoLines = async (ui: Pane) => (await shown(ui)).filter(t => /^\d+\. /.test(t))
// Local HH:MM, as the pane writes the time of a plan change.
const hhmm = (ms: number) => {
  const d = new Date(ms)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}
// The Buttons of the chooser, as the entries it offers.
const entries = async (ui: Pane) => (await ui.findAll({ type: 'Button' })).map(b => b.text)

// The crew members the sessions of the later tests run as, and what their
// findings files hold.
const ALPHA = `${FINDINGS}/alpha.md`
const BETA = `${FINDINGS}/beta.md`
const alphaPlan = [...MR_TABLE, mr(1, '!9', 'own', 'review')].join('\n')
const betaPlan = [...MR_TABLE, mr(1, '!7', 'one', 'review'), mr(2, '!8', 'two', 'merged 10:00')].join('\n')
const noTable = '# alpha findings\n\nNothing tabular yet.\n'
// The targets the mod wrote, in order: what it pointed the pane at, and who chose.
const aimedAt = (world: World) => world.writes.filter(w => w.key === 'target').map(w => w.value)

// A hook above the engine that awaits something after next(e), as another
// plugin's may: the answer to a read of the state key `key` is worked out when
// the read is made, and handed back only once `release` is called. `arm(skip)`
// picks the read: the one after the next `skip` reads of that key. It must be
// called before the test first uses `$`, as any hook must.
const lateAnswer = (on: On, key: string) => {
  let skipping = -1
  let held = false
  let release = () => {}
  const gate = new Promise<void>(resolve => {
    release = resolve
  })
  on('state.get', async (_$, e, next) => {
    if (e.key !== key || skipping < 0) return next(e)
    if (skipping > 0) {
      skipping -= 1
      return next(e)
    }
    skipping = -1
    const answer = await next(e)
    held = true
    await gate
    return answer
  })
  return {
    arm: (skip = 0) => {
      skipping = skip
    },
    release: () => release(),
    isHeld: () => held,
  }
}

describe('the merge request table', () => {
  test('draws progress, the todo in plan order with next steps and go gates, and what merged', async ($, on) => {
    const { boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)
    expect(await shown(ui)).toEqual([
      'gmp-deploy.md — 1/5 merged',
      'Todo, in order',
      '1. thanos (!4060) — running  · go: user go',
      'pipeline running, then ask for review',
      '2. alloy — pending  · go: B2',
      'not started: waits for thanos',
      '3. otel (!4011) — dropped',
      'dropped: folded into alloy',
      '4. ruler (!4070) — blocked  · go: B1',
      'blocked on B1',
      'Needs your call',
      'B1 (10:37)',
      'Go to rebase ksm onto main?',
      'B2 (11:05)',
      'Which registry for alloy?',
      'done: ksm',
      'no plan change seen this session',
    ])
  })

  // Rows 1, 3, 7, 8, 9 and 13 of the live plan, in its own wording. Row 1 is
  // the one the pane once hid: "dropped" in its prose was read as the row's
  // own state. Rows 8 and 9 are merge requests somebody still has to close.
  test('only a merged row leaves the todo list; superseded and dropped rows stay, labelled', async ($, on) => {
    const plan = [
      ...MR_TABLE,
      mr(1, '!4053', 'ksm', 'R1 (15:39): 2 unresolved, neither blocks: F1 imageTag silently dropped on a cluster'),
      mr(3, '!4055', 'sample', "MERGED 16:05:52 by the captain on the user's go"),
      mr(7, '!4050', 'gamma', "After beta's MERGED. G1 answered yes by U15"),
      mr(8, '!4047', 'alpha', 'Superseded by U3 and U5: its presets move'),
      mr(9, '!4048', 'zeta, Draft', 'Dropped by the user at 11:26: settled'),
      mr(13, '!4085', 'crds', "MERGED 15:59:13 by the captain on the user's go"),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: plan } })
    await boot($)
    const ui = await mountPane($)
    const lines = await shown(ui)
    expect(lines[0]).toBe('gmp-deploy.md — 2/6 merged')
    expect(await todoLines(ui)).toEqual([
      '1. ksm (!4053)',
      '2. gamma (!4050)',
      '3. alpha (!4047) — superseded',
      '4. zeta, Draft (!4048) — dropped',
    ])
    expect(lines).toContain('done: sample, crds')
  })

  test('a row is merged when its next step opens with "merged" and then ends or goes on with ".", ":", a clock time or "by"', async ($, on) => {
    const plan = [
      ...MR_TABLE,
      mr(1, '!1', 'm1', 'MERGED'),
      mr(2, '!2', 'm2', 'Merged.'),
      mr(3, '!3', 'm3', 'merged: squash abc123'),
      mr(4, '!4', 'm4', 'Merged 16:05'),
      mr(5, '!5', 'm5', "MERGED 16:05:52 by the captain on the user's go"),
      mr(6, '!6', 'm6', 'Merged by the admiral'),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: plan } })
    await boot($)
    const ui = await mountPane($)
    const lines = await shown(ui)
    expect(lines[0]).toBe('gmp-deploy.md — 6/6 merged')
    expect(await todoLines(ui)).toEqual([])
    expect(lines).toContain('nothing open')
    expect(lines).toContain('done: m1, m2, m3, m4, m5, m6')
  })

  // The review's seven strings (F1). Each opens with a state word followed by
  // a backtick, a bare number, a hyphen or a parenthesis, and each is an open
  // merge request: none may count as merged, and all must be listed.
  test('a state word followed by a backtick, a number, a hyphen or a parenthesis is prose', async ($, on) => {
    const plan = [
      ...MR_TABLE,
      mr(1, '!1', 'r1', 'Merged `master` into the branch; pipeline running'),
      mr(2, '!2', 'r2', 'Merged `cb817c36a` into the branch and regated; push next'),
      mr(3, '!3', 'r3', 'Merged 2 review fixes; R1b running'),
      mr(4, '!4', 'r4', 'Merged-results pipeline 175300 running'),
      mr(5, '!5', 'r5', 'Merged (locally) the fix commits; push with lease'),
      mr(6, '!6', 'r6', 'Dropped `9be5d2cf0` (the enable commit); push with lease, then R1'),
      mr(7, '!7', 'r7', 'Dropped 1 commit; regate'),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: plan } })
    await boot($)
    const ui = await mountPane($)
    const lines = await shown(ui)
    expect(lines[0]).toBe('gmp-deploy.md — 0/7 merged')
    expect(await todoLines(ui)).toEqual([
      '1. r1 (!1) — running',
      '2. r2 (!2)',
      '3. r3 (!3) — running',
      '4. r4 (!4) — running',
      '5. r5 (!5)',
      '6. r6 (!6)',
      '7. r7 (!7)',
    ])
    expect(lines.some(t => t.startsWith('done:'))).toBe(false)
  })

  // "by" after the word is taken at its word, right or wrong: the first three
  // are the review's own and none of them is a finished row. So such a row is
  // labelled and never removed, and the worst a misreading does is mislabel.
  test('a row that opens "Superseded by" or "Dropped by" is listed with that label, other openings without', async ($, on) => {
    const plan = [
      ...MR_TABLE,
      mr(1, '!1', 'a', 'Superseded by the next push; wait for pipeline 175300'),
      mr(2, '!2', 'b', 'Superseded by the rebase: regate, then push'),
      mr(3, '!3', 'c', 'Dropped by the rebase: the enable commit. Then push, R1, merge menu'),
      mr(4, '!4', 'd', 'Dropped the stale commit; regate'),
      mr(5, '!5', 'e', 'Merged master into the branch; pipeline running'),
      mr(6, '!6', 'f', 'Superseded pipeline; wait for the next one'),
      mr(7, '!7', 'g', 'Merged in the review fixes; regate'),
      mr(8, '!8', 'h', 'Dropped on EKS: the imageTag knob'),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: plan } })
    await boot($)
    const ui = await mountPane($)
    expect((await shown(ui))[0]).toBe('gmp-deploy.md — 0/8 merged')
    expect(await todoLines(ui)).toEqual([
      '1. a (!1) — superseded',
      '2. b (!2) — superseded',
      '3. c (!3) — dropped',
      '4. d (!4)',
      '5. e (!5) — running',
      '6. f (!6)',
      '7. g (!7)',
      '8. h (!8)',
    ])
  })

  test('labels an open row from its MR, id and next-step cells, never from the pipeline cell', async ($, on) => {
    const plan = [
      ...MR_TABLE,
      mr(1, '!1', 'a', 'held for the freeze'),
      mr(2, '!2', 'b', 'blocked on B1'),
      mr(3, '!3 (Draft)', 'c', 'a builder adds the rules'),
      mr(4, '!4', 'd', 'pipeline running'),
      mr(5, '!5', 'e', 'green, waits for the go'),
      mr(6, 'new', 'f', 'Built and verified: 4 files'),
      mr(7, '!7', 'g', 'Review fixes folded', '', '175099 running'),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: plan } })
    await boot($)
    expect(await todoLines(await mountPane($))).toEqual([
      '1. a (!1) — held',
      '2. b (!2) — blocked',
      '3. c (!3 (Draft)) — draft',
      '4. d (!4) — running',
      '5. e (!5) — green',
      '6. f — pending',
      '7. g (!7)',
    ])
  })

  test('says how many todo rows a short terminal leaves out', async ($, on) => {
    const { boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($, 14)
    expect(await todoLines(ui)).toEqual([
      '1. thanos (!4060) — running  · go: user go',
      '2. alloy — pending  · go: B2',
    ])
    expect(await shown(ui)).toContain('...+2 more below')
  })
})

describe('the BLOCKED log', () => {
  const owed = async (ui: Pane) => {
    const lines = await shown(ui)
    return lines.slice(lines.indexOf('Needs your call') + 1, -1)
  }

  test('only a decision whose answer is empty or "open" is owed', async ($, on) => {
    const log = [
      ...BLOCKED_LOG,
      ask('B1', '10:37', 'first', 'open'),
      ask('B2', '11:05', 'second', ''),
      ask('B3', '11:40', 'third', 'yes, 11:52'),
      ask('B4', '12:00', 'fourth', 'OPEN'),
      ask('B5', '12:10', 'fifth', '11:02: decide later; an open question for B6'),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: log } })
    await boot($)
    await planPane($, OWN)
    expect(await owed(await mountPane($))).toEqual([
      'B1 (10:37)',
      'first',
      'B2 (11:05)',
      'second',
      'B4 (12:00)',
      'fourth',
    ])
  })

  test('lists four owed decisions and says how many more are open', async ($, on) => {
    const log = [
      ...BLOCKED_LOG,
      ...[1, 2, 3, 4, 5, 6].map(i => ask(`B${i}`, `10:0${i}`, `question ${i}`, 'open')),
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: log } })
    await boot($)
    await planPane($, OWN)
    expect(await owed(await mountPane($))).toEqual([
      'B1 (10:01)',
      'question 1',
      'B2 (10:02)',
      'question 2',
      'B3 (10:03)',
      'question 3',
      'B4 (10:04)',
      'question 4',
      '...+2 more open',
    ])
  })
})

describe('a plan file that is missing or has no tables', () => {
  // The pane is pointed at the file before the first read of it has answered.
  test('before the first read of the file it follows has answered, the pane says it is reading', async ($, on) => {
    const { world, clock } = stage(on, { files: {}, crew: null })
    let release = () => {}
    world.holds = {
      '/w/slow.md': new Promise<void>(resolve => {
        release = resolve
      }),
    }
    const command = planPane($, '/w/slow.md')
    await clock.settle()
    expect(await shown(await mountPane($))).toEqual(['Reading plan...'])

    // The read answers now, so that nothing is left waiting when the test ends:
    // the kit gives up on a call that hangs some seconds later, and what the
    // command does then reaches whichever test is running, and writes its state.
    release()
    await command
  })

  test('/plan-pane <a path that does not exist> draws "plan: unavailable" and the path, and the file is picked up once it appears', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)
    expect(await planPane($, '/no/such/plan.md')).toEqual({ text: 'Plan pane -> /no/such/plan.md' })
    expect(await shown(ui)).toEqual(['plan: unavailable', 'cannot read /no/such/plan.md'])

    world.files['/no/such/plan.md'] = PLAN
    await clock.advance(REFRESH_MS)
    expect((await shown(ui))[0]).toBe('plan.md — 1/5 merged')
  })

  // The pane used to draw such a file as "0/0 merged", "nothing open", "no
  // open decisions": all clear, when it had simply found no table (review F3).
  test('a file with neither table says so in both sections and claims no progress', async ($, on) => {
    const { boot } = stage(on, { files: { [OWN]: PLAN, '/w/notes.md': '# notes\n\nNothing tabular here.\n' } })
    await boot($)
    const ui = await mountPane($)
    await planPane($, '/w/notes.md')
    expect(await shown(ui)).toEqual([
      'notes.md',
      'Todo, in order',
      'no merge request table in notes.md',
      'Needs your call',
      'no BLOCKED log in notes.md',
      'no plan change seen this session',
    ])
  })

  // The shape of a findings file that keeps its plan as a numbered list and
  // its questions under another heading: the heading is there, no table is.
  test('a plan kept as a list under the heading is no table either', async ($, on) => {
    const listed = [
      '## Plan (merge requests), as of 13:42',
      '',
      '1. **configs!4061**: pushed; waits for the merge go.',
      '2. **configs!3962**: after !4061, one ship rebases again.',
      '',
      '## Questions to the admiral (BLOCKED)',
      '',
      '- Q9: may the admiral merge !4061?',
      '',
    ].join('\n')
    const { boot } = stage(on, { files: { [OWN]: PLAN, '/w/listed.md': listed } })
    await boot($)
    const ui = await mountPane($)
    await planPane($, '/w/listed.md')
    expect(await shown(ui)).toEqual([
      'listed.md',
      'Todo, in order',
      'no merge request table in listed.md',
      'Needs your call',
      'no BLOCKED log in listed.md',
      'no plan change seen this session',
    ])
  })

  test('an empty file says the same; tables that are there with no rows draw "nothing open" and "no open decisions"', async ($, on) => {
    const headings = [...MR_TABLE, '', ...BLOCKED_LOG, ''].join('\n')
    const { boot } = stage(on, { files: { [OWN]: PLAN, '/w/empty.md': '', '/w/bare.md': headings } })
    await boot($)
    const ui = await mountPane($)

    await planPane($, '/w/empty.md')
    expect(await shown(ui)).toEqual([
      'empty.md',
      'Todo, in order',
      'no merge request table in empty.md',
      'Needs your call',
      'no BLOCKED log in empty.md',
      'no plan change seen this session',
    ])

    await planPane($, '/w/bare.md')
    expect(await shown(ui)).toEqual([
      'bare.md — 0/0 merged',
      'Todo, in order',
      'nothing open',
      'Needs your call',
      'no open decisions',
      'no plan change seen this session',
    ])
  })

  test('with one table and not the other, each section speaks for its own table', async ($, on) => {
    const logOnly = [...BLOCKED_LOG, ask('B1', '10:37', 'first', 'open')].join('\n')
    const planOnly = [...MR_TABLE, mr(1, '!9', 'own', 'review')].join('\n')
    const { boot } = stage(on, { files: { [OWN]: PLAN, '/w/log.md': logOnly, '/w/plan-only.md': planOnly } })
    await boot($)
    const ui = await mountPane($)

    await planPane($, '/w/log.md')
    expect(await shown(ui)).toEqual([
      'log.md',
      'Todo, in order',
      'no merge request table in log.md',
      'Needs your call',
      'B1 (10:37)',
      'first',
      'no plan change seen this session',
    ])

    await planPane($, '/w/plan-only.md')
    expect(await shown(ui)).toEqual([
      'plan-only.md — 0/1 merged',
      'Todo, in order',
      '1. own (!9)',
      'review',
      'Needs your call',
      'no BLOCKED log in plan-only.md',
      'no plan change seen this session',
    ])
  })

  test('a row with cells missing is still listed, by its number', async ($, on) => {
    const { boot } = stage(on, { files: { [OWN]: [...MR_TABLE, '| 7 |', mr(8, '!8', 'whole', 'review')].join('\n') } })
    await boot($)
    const ui = await mountPane($)
    expect((await shown(ui))[0]).toBe('gmp-deploy.md — 0/2 merged')
    expect(await todoLines(ui)).toEqual(['1. 7', '2. whole (!8)'])
  })
})

describe('following the file', () => {
  test('a plan edit shows within one refresh, with the time and what changed', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)

    world.files[OWN] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS - 1)
    expect((await shown(ui))[0]).toBe('gmp-deploy.md — 1/5 merged')
    expect((await shown(ui)).at(-1)).toBe('no plan change seen this session')

    await clock.advance(1)
    const lines = await shown(ui)
    expect(lines[0]).toBe('gmp-deploy.md — 2/5 merged')
    expect(lines.slice(-2)).toEqual([
      'done: ksm, thanos',
      `plan updated ${hhmm(T0 + REFRESH_MS)} — thanos: running -> merged`,
    ])
  })

  // Neither edit changes a row's state or adds or removes one: the plan used
  // to be read as unchanged.
  test('an edit to a next-step cell alone is a plan change, named by its row', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)

    world.files[OWN] = PLAN.replace('not started: waits for thanos', 'not started: waits for thanos and ksm')
    await clock.advance(REFRESH_MS)
    const lines = await shown(ui)
    expect(lines).toContain('2. alloy — pending  · go: B2')
    expect(lines.at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)} — alloy: next step edited`)
  })

  test('an edit to a go gate alone is a plan change, with the gate it was and the gate it is', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)

    world.files[OWN] = PLAN.replace('not started: waits for thanos | B2 |', 'not started: waits for thanos | B3 |')
    await clock.advance(REFRESH_MS)
    expect((await shown(ui)).at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)} — alloy: go B2 -> B3`)

    world.files[OWN] = PLAN.replace('not started: waits for thanos | B2 |', 'not started: waits for thanos |  |')
    await clock.advance(REFRESH_MS)
    expect((await shown(ui)).at(-1)).toBe(`plan updated ${hhmm(T0 + 2 * REFRESH_MS)} — alloy: go B3 -> -`)
  })

  // The header no longer shows a plan heading (it showed the last one in the
  // file, which is not the newest plan), but a new one is still a plan change.
  test('a plan heading added to the file is a plan change, though no heading is drawn', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)
    expect((await shown(ui)).some(t => t.includes('Rollout plan'))).toBe(false)

    world.files[OWN] = `${PLAN}\n## Friday plan (16:59)\n\nF1 to F4.\n`
    await clock.advance(REFRESH_MS)
    const lines = await shown(ui)
    expect(lines.at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)}`)
    expect(lines.some(t => t.includes('Friday plan'))).toBe(false)
  })

  test('a refresh that finds the plan as it was reports no change', async ($, on) => {
    const { clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)
    await clock.advance(3 * REFRESH_MS)
    expect((await shown(ui)).at(-1)).toBe('no plan change seen this session')
  })

  // The snapshot used to carry the time it was read at, so every 5 s read
  // wrote it again and the pane was drawn again for nothing.
  test('a read that finds the file as it was writes no state, however many ticks pass', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    expect(world.writes.map(w => w.key)).toEqual(['target', 'snap'])

    await clock.advance(3 * REFRESH_MS)
    expect(world.writes.map(w => w.key)).toEqual(['target', 'snap'])

    world.files[OWN] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS)
    expect(world.writes.map(w => w.key)).toEqual(['target', 'snap', 'snap'])
    await clock.advance(3 * REFRESH_MS)
    expect(world.writes).toHaveLength(3)
  })

  test('a file that stays unreadable is written about once, not at every tick', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: {}, crew: null })
    await boot($)
    await planPane($, '/no/such/plan.md')
    await clock.advance(3 * REFRESH_MS)
    expect(world.writes.map(w => w.key)).toEqual(['target', 'snap'])
  })

  // State outlives a hot reload, so a snapshot the version before this one
  // wrote can be found. It is not drawn as a plan, and the read that replaces
  // it is not compared with it: its signature is worked out another way, so
  // the plan would seem to have changed.
  test('a snapshot an earlier version left is drawn as "Reading plan...", then replaced without a plan change', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    world.oldSnap = true
    await boot($)
    world.oldSnap = false
    const ui = await mountPane($)
    expect(await shown(ui)).toEqual(['Reading plan...'])

    await clock.advance(REFRESH_MS)
    const lines = await shown(ui)
    expect(lines[0]).toBe('gmp-deploy.md — 1/5 merged')
    expect(lines.at(-1)).toBe('no plan change seen this session')
  })

  // The pane used to compare the new file with the one it showed before, and
  // announce "plan updated HH:MM — - ksm" for a plan nobody had touched.
  test('pointing the pane at another file is not a plan change, and carries none over', async ($, on) => {
    const other = [...MR_TABLE, mr(1, '!9', 'own', 'review')].join('\n')
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN, '/w/other.md': other } })
    await boot($)
    const ui = await mountPane($)

    world.files[OWN] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS)
    expect((await shown(ui)).at(-1)).toBe(
      `plan updated ${hhmm(T0 + REFRESH_MS)} — thanos: running -> merged`,
    )

    await planPane($, '/w/other.md')
    expect(await shown(ui)).toEqual([
      'other.md — 0/1 merged',
      'Todo, in order',
      '1. own (!9)',
      'review',
      'Needs your call',
      'no BLOCKED log in other.md',
      'no plan change seen this session',
    ])
  })

  // A read of the file the pane followed is still under way when the person
  // points the pane at another: what it read must not be written over what the
  // new file's read wrote.
  test('a read that is still under way when the pane is pointed at another file is let go', async ($, on) => {
    const other = [...MR_TABLE, mr(1, '!9', 'own', 'review')].join('\n')
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN, '/w/other.md': other } })
    await boot($)
    const ui = await mountPane($)

    let release = () => {}
    world.holds = {
      [OWN]: new Promise<void>(resolve => {
        release = resolve
      }),
    }
    world.files[OWN] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS)
    await planPane($, '/w/other.md')
    expect((await shown(ui))[0]).toBe('other.md — 0/1 merged')

    release()
    await clock.settle()
    const lines = await shown(ui)
    expect(lines[0]).toBe('other.md — 0/1 merged')
    expect(lines.at(-1)).toBe('no plan change seen this session')
  })

  // Two refreshes of one file can overlap: a tick's, and the one `/plan-pane`
  // makes. The one that started first has its read answered last, with the file
  // as it was before the edit the other one has read: it must not be written
  // over the other's, or the pane announces the edit run backwards. A held read
  // answers with the file as it stands when it is let go, so the text the file
  // had before the edit is put back first.
  test('a read answered after a later read of the same file has written is let go', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)

    let release = () => {}
    world.holds = {
      [OWN]: new Promise<void>(resolve => {
        release = resolve
      }),
    }
    await clock.advance(REFRESH_MS)
    world.holds = undefined
    world.files[OWN] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await planPane($, '')
    const read = await shown(ui)
    expect(read[0]).toBe('gmp-deploy.md — 2/5 merged')
    expect(read.at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)} — thanos: running -> merged`)

    world.files[OWN] = PLAN
    release()
    await clock.settle()
    expect(await shown(ui)).toEqual(read)
  })

  // The same across a hand choice. A tick's refresh has read the file and passed
  // the check that the pane still follows it; while it waits to look at the
  // snapshot the person points the pane at another file, which is read and
  // written. The tick's refresh must not write the old file's snapshot over it:
  // the pane would say "Reading plan..." until the next tick.
  test('a refresh of the file the pane has left is let go, though it passed the check on the file', async ($, on) => {
    const other = [...MR_TABLE, mr(1, '!9', 'own', 'review')].join('\n')
    const { clock, boot } = stage(on, { files: { [OWN]: PLAN, '/w/other.md': other } })
    // Once `hold` is set, the next read of the snapshot waits until it is let
    // go, and then reads what stands by then.
    let hold = false
    let waiting = false
    let release = () => {}
    on('state.get', async (_$, e, next) => {
      if (hold && e.key === 'snap') {
        hold = false
        waiting = true
        await new Promise<void>(resolve => {
          release = resolve
        })
      }
      return next(e)
    })
    await boot($)

    hold = true
    await clock.advance(REFRESH_MS)
    expect(waiting).toBe(true)
    await planPane($, '/w/other.md')

    release()
    await clock.settle()
    expect((await shown(await mountPane($)))[0]).toBe('other.md — 0/1 merged')
  })

  // The guard keeps the later read over the earlier one, not the other way round:
  // two refreshes that overlap and are answered in the order they started both
  // write, and the later one's text stands.
  test('reads answered in the order they started each write', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    const ui = await mountPane($)

    let first = () => {}
    let second = () => {}
    world.holds = {
      [OWN]: new Promise<void>(resolve => {
        first = resolve
      }),
    }
    await clock.advance(REFRESH_MS)
    world.holds = {
      [OWN]: new Promise<void>(resolve => {
        second = resolve
      }),
    }
    const command = planPane($, '')
    await clock.settle()

    const merged = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    world.files[OWN] = merged
    first()
    await clock.settle()
    expect((await shown(ui))[0]).toBe('gmp-deploy.md — 2/5 merged')

    world.files[OWN] = merged.replace('not started: waits for thanos', 'merged 15:20')
    second()
    await command
    const lines = await shown(ui)
    expect(lines[0]).toBe('gmp-deploy.md — 3/5 merged')
    expect(lines.at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)} — alloy: pending -> merged`)
  })
})

describe('timers', () => {
  // session.start fires again on a reload or a worker respawn. One timer reads
  // the file at every tick, so a second one would read it twice.
  test('a second session.start leaves exactly one timer, and so does a third', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    await boot($)
    await boot($)
    world.asked.length = 0

    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${OWN}`])
    await clock.advance(2 * REFRESH_MS)
    expect(world.asked).toHaveLength(3)
  })

  // A read that takes longer than a period: the ticks that come while it waits
  // start nothing, and the first tick after it ends reads again.
  test('a tick that finds the refresh before it still reading starts none', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    world.asked.length = 0

    let release = () => {}
    world.gate = new Promise<void>(resolve => {
      release = resolve
    })
    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${OWN}`])
    await clock.advance(3 * REFRESH_MS)
    expect(world.asked).toEqual([`read ${OWN}`])

    world.gate = undefined
    release()
    await clock.settle()
    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${OWN}`, `read ${OWN}`])
  })
})

describe("the session's own plan", () => {
  test('a session with no crew name opens no pane, reads no file and starts no timer', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN, [ALPHA]: alphaPlan }, crew: null })
    await boot($)
    await clock.advance(10 * LOOK_MS)
    expect(world.asked).toEqual(['run printenv HOME', 'run printenv CREW_NAME'])
    expect(world.opened).toEqual([])
    expect(world.timers).toEqual([])
    expect(world.writes).toEqual([])
  })

  test('a crew session whose findings file holds a merge request table follows it and opens the pane unasked', async ($, on) => {
    const { world, boot } = stage(on, { files: { [OWN]: PLAN, [ALPHA]: alphaPlan }, crew: 'alpha' })
    await boot($)
    expect(world.asked).toEqual([
      'run printenv HOME',
      'run printenv CREW_NAME',
      `read ${ALPHA}`,
      `read ${ALPHA}`,
    ])
    expect(world.opened).toEqual(['plan'])
    expect(world.timers).toEqual([REFRESH_MS])
    expect(aimedAt(world)).toEqual([{ file: ALPHA, by: 'auto' }])
    expect((await shown(await mountPane($)))[0]).toBe('alpha.md — 0/1 merged')
  })

  test('a crew session whose file holds no table opens no pane, and opens it when the table appears at a one-minute check', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [ALPHA]: noTable }, crew: 'alpha' })
    await boot($)
    expect(world.opened).toEqual([])
    expect(world.timers).toEqual([LOOK_MS])
    expect(aimedAt(world)).toEqual([])
    expect(world.asked).toHaveLength(3)

    await clock.advance(LOOK_MS - 1)
    expect(world.asked).toHaveLength(3)
    await clock.advance(1)
    expect(world.asked).toHaveLength(4)
    expect(world.opened).toEqual([])

    world.files[ALPHA] = alphaPlan
    await clock.advance(LOOK_MS)
    expect(world.opened).toEqual(['plan'])
    expect(aimedAt(world)).toEqual([{ file: ALPHA, by: 'auto' }])
    expect((await shown(await mountPane($)))[0]).toBe('alpha.md — 0/1 merged')

    // From then on the file is followed every tick, and not looked for at all.
    world.asked.length = 0
    await clock.advance(LOOK_MS)
    expect(world.asked).toEqual(Array(LOOK_MS / REFRESH_MS).fill(`read ${ALPHA}`))
  })

  test('a findings file that is not there yet is looked for the same way', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: {}, crew: 'alpha' })
    await boot($)
    expect(world.opened).toEqual([])

    world.files[ALPHA] = alphaPlan
    await clock.advance(LOOK_MS)
    expect(world.opened).toEqual(['plan'])
    expect((await shown(await mountPane($)))[0]).toBe('alpha.md — 0/1 merged')
  })

  // The name becomes part of a path: one that is not a crew name is never
  // looked up at all, so no path is ever built from it.
  test('never builds a path from a CREW_NAME that is not a crew name', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN, [ALPHA]: alphaPlan }, crew: null })
    const notCrewNames = [
      '../../etc/passwd',
      '..',
      'a/b',
      '/etc/passwd',
      'alpha/../alpha',
      'a..b',
      '.hidden',
      'alpha.md',
      'Alpha',
      'alpha beta',
      ' alpha',
      'alpha\nbeta',
      'alpha\n',
      '-alpha',
      '',
      'a'.repeat(41),
    ]
    for (const name of notCrewNames) {
      world.env.CREW_NAME = name
      world.asked.length = 0
      await boot($)
      expect(world.asked, JSON.stringify(name)).toEqual(['run printenv HOME', 'run printenv CREW_NAME'])
    }
    await clock.advance(10 * LOOK_MS)
    expect(world.asked).toHaveLength(2)
    expect(world.opened).toEqual([])
    expect(world.timers).toEqual([])
  })

  // session.start fires again on a reload or a worker respawn, and what the
  // person chose must outlive that, whatever CREW_NAME says now.
  test('a path chosen with /plan-pane outlives a later session start, whatever CREW_NAME says', async ($, on) => {
    const { world, clock, boot } = stage(on, {
      files: { [ALPHA]: alphaPlan, [BETA]: betaPlan, '/w/mine.md': alphaPlan },
      crew: 'alpha',
    })
    await boot($)
    const ui = await mountPane($)
    expect((await shown(ui))[0]).toBe('alpha.md — 0/1 merged')

    await planPane($, '/w/mine.md')
    expect((await shown(ui))[0]).toBe('mine.md — 0/1 merged')

    world.env.CREW_NAME = 'beta'
    world.asked.length = 0
    world.opened.length = 0
    await boot($)
    expect(world.asked).toEqual(['run printenv HOME', 'run printenv CREW_NAME', 'read /w/mine.md'])
    expect(world.opened).toEqual([])
    expect(aimedAt(world)).toEqual([
      { file: ALPHA, by: 'auto' },
      { file: '/w/mine.md', by: 'hand' },
    ])
    expect((await shown(ui))[0]).toBe('mine.md — 0/1 merged')

    // And it is still followed.
    world.files['/w/mine.md'] = [...MR_TABLE, mr(1, '!9', 'own', 'merged 16:00')].join('\n')
    await clock.advance(REFRESH_MS)
    expect((await shown(ui))[0]).toBe('mine.md — 1/1 merged')
  })

  // The person's choice can land while the start is still reading the
  // session's own file: that file must not replace it, nor the timer be left
  // looking for a plan.
  test('what the module finds for the session never replaces what the person chose, even when the choice comes while it looks', async ($, on) => {
    const { world, clock } = stage(on, {
      files: { [ALPHA]: alphaPlan, '/w/mine.md': PLAN },
      crew: 'alpha',
    })
    let release = () => {}
    world.gate = new Promise<void>(resolve => {
      release = resolve
    })
    await start($)
    await clock.settle()
    void planPane($, '/w/mine.md')
    await clock.settle()
    world.gate = undefined
    release()
    await clock.settle()

    expect(aimedAt(world)).toEqual([{ file: '/w/mine.md', by: 'hand' }])
    expect((await shown(await mountPane($)))[0]).toBe('mine.md — 1/5 merged')
    world.asked.length = 0
    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual(['read /w/mine.md'])
  })

  test('a target the module chose is resolved afresh at the next session start: dropped when the plan has gone, found again when it is back', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [ALPHA]: alphaPlan }, crew: 'alpha' })
    await boot($)
    const ui = await mountPane($)
    expect((await shown(ui))[0]).toBe('alpha.md — 0/1 merged')

    world.files[ALPHA] = noTable
    await boot($)
    expect(aimedAt(world)).toEqual([{ file: ALPHA, by: 'auto' }, null])
    expect(world.timers).toEqual([REFRESH_MS, LOOK_MS])

    world.files[ALPHA] = alphaPlan
    await clock.advance(LOOK_MS)
    expect(aimedAt(world)).toEqual([{ file: ALPHA, by: 'auto' }, null, { file: ALPHA, by: 'auto' }])
    expect((await shown(ui))[0]).toBe('alpha.md — 0/1 merged')
  })

})

describe('the chooser', () => {
  // `/plan-pane` with nothing to follow. The files are the findings folder's:
  // three hold a plan; one has no table, one cannot be read, one is too big, one
  // is no .md file, and a subfolder holds a plan of its own. Another subfolder
  // is named like a plan file, and must not be read as one.
  const folder = {
    [`${FINDINGS}/gmp-deploy.md`]: PLAN,
    [`${FINDINGS}/alpha.md`]: alphaPlan,
    [`${FINDINGS}/beta.md`]: betaPlan,
    [`${FINDINGS}/notes.md`]: noTable,
    [`${FINDINGS}/huge.md`]: PLAN,
    [`${FINDINGS}/readme.txt`]: PLAN,
    [`${FINDINGS}/mods/inner.md`]: PLAN,
  }
  const given = {
    files: folder,
    crew: null,
    dirs: ['mods', 'old.md'],
    unreadable: [`${FINDINGS}/locked.md`],
    sizes: { [`${FINDINGS}/huge.md`]: 5 * 1024 * 1024 },
  }

  test('offers the files that hold a merge request table, in name order, each with its progress', async ($, on) => {
    const { world, boot } = stage(on, given)
    await boot($)
    // Nothing is looked through until the chooser is about to be shown.
    expect(world.asked).toEqual(['run printenv HOME', 'run printenv CREW_NAME'])
    expect(world.opened).toEqual([])

    expect(await planPane($, '')).toEqual({ text: 'Plan pane opened.' })
    expect(world.opened).toEqual(['plan'])
    expect(world.asked.filter(call => call.startsWith('list '))).toEqual([`list ${FINDINGS}`])
    // Every .md directly in the folder was read but the one too big to read.
    expect(world.asked.filter(call => call.startsWith('read ')).sort()).toEqual(
      ['alpha', 'beta', 'gmp-deploy', 'locked', 'notes'].map(name => `read ${FINDINGS}/${name}.md`),
    )

    const ui = await mountPane($)
    expect(await entries(ui)).toEqual([
      'alpha.md — 0/1 merged',
      'beta.md — 1/2 merged',
      'gmp-deploy.md — 1/5 merged',
    ])
    expect(await shown(ui)).toEqual(['or type /plan-pane <name>'])
  })

  test('pressing an entry points the pane at that file by hand, and the pane shows the plan', async ($, on) => {
    const { world, clock, boot } = stage(on, given)
    await boot($)
    await planPane($, '')
    const ui = await mountPane($)

    await ui.press({ key: 'plan:beta.md' })
    expect(aimedAt(world)).toEqual([{ file: BETA, by: 'hand' }])
    expect((await shown(ui))[0]).toBe('beta.md — 1/2 merged')
    expect(await ui.findAll({ type: 'Button' })).toEqual([])

    // The file is followed from then on.
    world.files[BETA] = [...MR_TABLE, mr(1, '!7', 'one', 'merged 11:00'), mr(2, '!8', 'two', 'merged 10:00')].join('\n')
    await clock.advance(REFRESH_MS)
    expect((await shown(ui))[0]).toBe('beta.md — 2/2 merged')
  })

  test('looks again each time it is asked for, so a plan that has appeared is offered', async ($, on) => {
    const { world, boot } = stage(on, given)
    await boot($)
    await planPane($, '')
    const ui = await mountPane($)
    expect(await entries(ui)).toHaveLength(3)

    world.files[`${FINDINGS}/zeta.md`] = alphaPlan
    await planPane($, '')
    expect(await entries(ui)).toEqual([
      'alpha.md — 0/1 merged',
      'beta.md — 1/2 merged',
      'gmp-deploy.md — 1/5 merged',
      'zeta.md — 0/1 merged',
    ])
  })

  test('with nothing to offer says that no findings file holds a plan, and how to point the pane at one', async ($, on) => {
    const { world, boot } = stage(on, { files: { [`${FINDINGS}/notes.md`]: noTable }, crew: null })
    await boot($)
    expect(await planPane($, '')).toEqual({ text: 'Plan pane opened.' })
    expect(world.opened).toEqual(['plan'])
    const ui = await mountPane($)
    expect(await shown(ui)).toEqual([
      'no findings file holds a merge request table',
      'point the pane at a file: /plan-pane <name> or /plan-pane /path/to/file.md',
    ])
    expect(await entries(ui)).toEqual([])
  })

  test('an empty findings folder, or none, offers nothing either', async ($, on) => {
    const { world, boot } = stage(on, { files: {}, crew: null, env: { HOME: '/nowhere' } })
    await boot($)
    await planPane($, '')
    expect(world.asked).toContain('list /nowhere/.local/state/crew/findings')
    expect((await shown(await mountPane($)))[0]).toBe('no findings file holds a merge request table')
  })

  test('is never opened unasked: a session with nothing to follow opens no pane', async ($, on) => {
    const { world, clock, boot } = stage(on, given)
    await boot($)
    await clock.advance(10 * LOOK_MS)
    expect(world.opened).toEqual([])
    expect(world.timers).toEqual([])
  })

  // Opening the chooser follows nothing: no 5 s timer. A session with no crew
  // name has none at all, a crew session keeps its one-minute look.
  test('asked for by a session with no crew name, starts no timer', async ($, on) => {
    const { world, clock, boot } = stage(on, given)
    await boot($)
    await planPane($, '')
    expect(world.opened).toEqual(['plan'])
    expect(world.timers).toEqual([])

    world.asked.length = 0
    await clock.advance(10 * LOOK_MS)
    expect(world.asked).toEqual([])
  })

  test('asked for by a crew session with no plan of its own, leaves it its one-minute look and no more', async ($, on) => {
    const { world, clock, boot } = stage(on, { ...given, crew: 'notes' })
    await boot($)
    expect(world.timers).toEqual([LOOK_MS])
    await planPane($, '')
    expect(world.opened).toEqual(['plan'])
    expect(world.timers).toEqual([LOOK_MS])

    world.asked.length = 0
    await clock.advance(LOOK_MS)
    expect(world.asked).toEqual([`read ${FINDINGS}/notes.md`])
  })

  // The engine keeps the record of the panes, and a pane outlives a reload of
  // the module: one left open (by an earlier version of the module, say) now
  // follows nothing, and shows the chooser.
  test('a pane that is up when a session starts with nothing to follow shows the chooser', async ($, on) => {
    const { world, boot } = stage(on, { ...given, panes: ['plan'] })
    await boot($)
    expect(world.opened).toEqual([])
    expect(world.asked.filter(call => call.startsWith('list '))).toEqual([`list ${FINDINGS}`])
    expect(await entries(await mountPane($))).toHaveLength(3)
  })

  test('the findings folder is not looked through for a session that follows a plan', async ($, on) => {
    const { world, boot } = stage(on, { ...given, crew: 'alpha', panes: ['plan'] })
    await boot($)
    expect(world.asked.filter(call => call.startsWith('list '))).toEqual([])
  })
})

describe('state an earlier version left', () => {
  // The version before this one kept the path alone, so there is no telling
  // whether the person chose it: it is not taken for a choice by hand.
  test('a target with no record of how it was chosen is not drawn as a plan, and the next session start resolves it afresh', async ($, on) => {
    const { world, boot } = stage(on, { files: { [ALPHA]: alphaPlan, '/w/mine.md': PLAN }, crew: null })
    await boot($)
    world.oldTarget = true
    await planPane($, '/w/mine.md')
    world.oldTarget = false
    const ui = await mountPane($)
    expect(await shown(ui)).toEqual(['Reading plan...'])

    // Now the session is a crew member's, with a plan of its own.
    world.env.CREW_NAME = 'alpha'
    await boot($)
    expect((await shown(ui))[0]).toBe('alpha.md — 0/1 merged')
    expect(aimedAt(world).at(-1)).toEqual({ file: ALPHA, by: 'auto' })
  })

  test('and is cleared when the session has no plan of its own, with no timer left', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { '/w/mine.md': PLAN }, crew: null })
    await boot($)
    world.oldTarget = true
    await planPane($, '/w/mine.md')
    world.oldTarget = false

    world.opened.length = 0
    await boot($)
    expect(aimedAt(world).at(-1)).toBeNull()
    expect(world.opened).toEqual([])
    world.asked.length = 0
    await clock.advance(10 * LOOK_MS)
    expect(world.asked).toEqual([])
  })
})

describe('the home folder', () => {
  test('the findings folder is under the home folder printenv prints', async ($, on) => {
    const OTHER = '/srv/other/.local/state/crew/findings/alpha.md'
    const { world, boot } = stage(on, {
      files: { [ALPHA]: alphaPlan, [OTHER]: PLAN },
      crew: 'alpha',
      env: { HOME: '/srv/other' },
    })
    await boot($)
    expect(world.asked).toEqual([
      'run printenv HOME',
      'run printenv CREW_NAME',
      `read ${OTHER}`,
      `read ${OTHER}`,
    ])
    expect((await shown(await mountPane($)))[0]).toBe('alpha.md — 1/5 merged')
  })

  // The folder becomes part of a path, and a relative one would be read under
  // the session's directory. A value that is not an absolute path with no
  // newline is not used at all: the mod has no findings folder, and stays shut.
  test('an unusable home folder leaves the mod closed: no read, no pane, no timer', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [ALPHA]: alphaPlan, [OWN]: PLAN }, crew: 'alpha' })
    for (const home of ['', 'home/tester', '~', '.', '/home/tester\nx']) {
      world.env.HOME = home
      world.asked.length = 0
      await boot($)
      expect(world.asked, JSON.stringify(home)).toEqual(['run printenv HOME'])
    }
    delete world.env.HOME
    world.asked.length = 0
    await boot($)
    expect(world.asked).toEqual(['run printenv HOME'])

    await clock.advance(10 * LOOK_MS)
    expect(world.asked).toEqual(['run printenv HOME'])
    expect(world.opened).toEqual([])
    expect(world.timers).toEqual([])
    expect(world.writes).toEqual([])
  })

  test('without it a crew name cannot be looked up, and a path still can', async ($, on) => {
    const { world, boot } = stage(on, { files: { [ALPHA]: alphaPlan, '/w/mine.md': PLAN }, crew: null })
    delete world.env.HOME
    await boot($)
    const ui = await mountPane($)

    const refused = await planPane($, 'alpha')
    expect(refused).toEqual({ text: expect.stringContaining('no findings folder') })
    expect(aimedAt(world)).toEqual([])
    expect(world.opened).toEqual([])

    expect(await planPane($, '/w/mine.md')).toEqual({ text: 'Plan pane -> /w/mine.md' })
    expect((await shown(ui))[0]).toBe('mine.md — 1/5 merged')
  })
})

describe('/plan-pane with an argument', () => {
  test('a crew name means that crew member\'s file in the findings folder, a path starting with "/" is taken as it is', async ($, on) => {
    const { world, boot } = stage(on, { files: { [ALPHA]: alphaPlan, '/w/mine.md': PLAN }, crew: null })
    await boot($)
    const ui = await mountPane($)

    expect(await planPane($, 'alpha')).toEqual({ text: `Plan pane -> ${ALPHA}` })
    expect((await shown(ui))[0]).toBe('alpha.md — 0/1 merged')
    expect(await planPane($, '/w/mine.md')).toEqual({ text: 'Plan pane -> /w/mine.md' })
    expect((await shown(ui))[0]).toBe('mine.md — 1/5 merged')

    // Both are the person's choice, and the pane is opened for each.
    expect(aimedAt(world)).toEqual([
      { file: ALPHA, by: 'hand' },
      { file: '/w/mine.md', by: 'hand' },
    ])
    expect(world.opened).toEqual(['plan', 'plan'])
  })

  test('anything else is refused, and the pane is left as it was', async ($, on) => {
    const { world, boot } = stage(on, { files: { [ALPHA]: alphaPlan }, crew: 'alpha' })
    await boot($)
    const ui = await mountPane($)
    world.opened.length = 0
    world.writes.length = 0

    for (const arg of ['alpha.md', 'Alpha', 'a/b', '../alpha', 'two words', '~/plan.md', 'a'.repeat(41)]) {
      expect(await planPane($, arg), arg).toEqual({
        text: `Plan pane: "${arg}" is neither a crew name nor a path starting with "/".`,
      })
    }
    expect(world.opened).toEqual([])
    expect(world.writes).toEqual([])
    expect((await shown(ui))[0]).toBe('alpha.md — 0/1 merged')
  })

  test('with none it opens the pane on the file it follows', async ($, on) => {
    const { world, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    world.opened.length = 0

    expect(await planPane($, '')).toEqual({ text: 'Plan pane opened.' })
    expect(world.opened).toEqual(['plan'])
    expect((await shown(await mountPane($)))[0]).toBe('gmp-deploy.md — 1/5 merged')
  })

  // The file is followed whether or not the pane opens. A refusal to open still
  // reaches the caller (the hook fails, and nothing beneath it answers), but the
  // person's choice must not be left without a timer for it: a later
  // `/plan-pane` would then show one read of the file, and never a later edit.
  test('follows the file whether or not the pane opens, and the refusal still reaches the caller', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { '/w/mine.md': PLAN }, crew: null, refuseOpen: true })
    await boot($)

    await expect(planPane($, '/w/mine.md')).rejects.toThrow('no implementation for command.run')
    expect(world.opened).toEqual(['plan'])
    expect(aimedAt(world)).toEqual([{ file: '/w/mine.md', by: 'hand' }])
    expect(world.timers).toEqual([REFRESH_MS])
    const ui = await mountPane($)
    expect((await shown(ui))[0]).toBe('mine.md — 1/5 merged')

    const edited = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    world.files['/w/mine.md'] = edited
    await clock.advance(REFRESH_MS)
    let lines = await shown(ui)
    expect(lines[0]).toBe('mine.md — 2/5 merged')
    expect(lines.at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)} — thanos: running -> merged`)

    // `/plan-pane` alone, the pane opening this time: the file is still followed.
    world.refuseOpen = false
    expect(await planPane($, '')).toEqual({ text: 'Plan pane opened.' })
    world.files['/w/mine.md'] = edited.replace('not started: waits for thanos', 'merged 15:20')
    await clock.advance(REFRESH_MS)
    lines = await shown(ui)
    expect(lines[0]).toBe('mine.md — 3/5 merged')
    expect(lines.at(-1)).toBe(`plan updated ${hhmm(T0 + 2 * REFRESH_MS)} — alloy: pending -> merged`)
  })

  // The pane's refusal can come while the file is still being read. Nothing may
  // be left rejected with nobody to handle it for as long as the read takes.
  test('a refusal that comes before the file has been read is not left unhandled', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { '/w/mine.md': PLAN }, crew: null, refuseOpen: true })
    await boot($)

    let release = () => {}
    world.gate = new Promise<void>(resolve => {
      release = resolve
    })
    const outcome = planPane($, '/w/mine.md').then(
      () => 'answered',
      () => 'refused',
    )
    await clock.settle()
    expect(world.opened).toEqual(['plan'])
    expect(world.timers).toEqual([REFRESH_MS])

    world.gate = undefined
    release()
    expect(await outcome).toBe('refused')
  })

  // `/plan-pane` with nothing typed after it, and a file chosen, follows it
  // again, so a timer that was lost comes back; it never leaves two.
  test('with none and a file chosen, starts the timer afresh and leaves one', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [OWN]: PLAN } })
    await boot($)
    expect(world.timers).toEqual([REFRESH_MS])

    expect(await planPane($, '')).toEqual({ text: 'Plan pane opened.' })
    expect(world.timers).toEqual([REFRESH_MS, REFRESH_MS])
    world.asked.length = 0
    await clock.advance(REFRESH_MS)
    expect(world.asked).toEqual([`read ${OWN}`])
  })
})

describe('a session start', () => {
  // session.start is awaited before the first prompt: a lookup or a read that
  // is slow, or never answers, must not hold the session up. It is `start`
  // that must resolve here, not the work it leaves behind.
  test('is not held up by a printenv HOME that never answers', async ($, on) => {
    const { world, clock } = stage(on, { files: { [OWN]: PLAN }, hang: ['run printenv HOME'] })
    expect(await start($)).toEqual({ cwd: '/w' })
    await clock.settle()
    expect(world.asked).toEqual(['run printenv HOME'])
  })

  test('is not held up by a printenv CREW_NAME that never answers', async ($, on) => {
    const { world, clock } = stage(on, { files: { [OWN]: PLAN }, hang: ['run printenv CREW_NAME'] })
    expect(await start($)).toEqual({ cwd: '/w' })
    await clock.settle()
    expect(world.asked).toEqual(['run printenv HOME', 'run printenv CREW_NAME'])
  })

  test('is not held up by a first read that never answers', async ($, on) => {
    const { world, clock } = stage(on, { files: { [OWN]: PLAN }, hang: [`read ${OWN}`] })
    expect(await start($)).toEqual({ cwd: '/w' })
    await clock.settle()
    expect(world.asked).toEqual(['run printenv HOME', 'run printenv CREW_NAME', `read ${OWN}`])
  })

  // What the person chose does not depend on the lookup of the environment: a
  // `printenv` can take as long as $.process.run's timeout to answer, and until it
  // does the pane would not be followed. The lookup is still started, and the
  // commands wait for it.
  test('follows a file the person chose at once, without waiting for a printenv that never answers', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { [ALPHA]: alphaPlan, '/w/mine.md': PLAN }, crew: 'alpha' })
    await boot($)
    await planPane($, '/w/mine.md')
    const ui = await mountPane($)
    expect((await shown(ui))[0]).toBe('mine.md — 1/5 merged')

    // Another start, as a reload raises it: the file changed meanwhile.
    const edited = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    world.files['/w/mine.md'] = edited
    world.hang = ['run printenv HOME']
    world.asked.length = 0
    world.timers.length = 0
    expect(await boot($)).toEqual({ cwd: '/w' })
    expect(world.asked).toEqual(['run printenv HOME', 'read /w/mine.md'])
    expect(world.timers).toEqual([REFRESH_MS])
    expect((await shown(ui))[0]).toBe('mine.md — 2/5 merged')

    // And the file is read again at the next tick.
    world.files['/w/mine.md'] = edited.replace('not started: waits for thanos', 'merged 15:20')
    await clock.advance(REFRESH_MS)
    const lines = await shown(ui)
    expect(lines[0]).toBe('mine.md — 3/5 merged')
    expect(lines.at(-1)).toBe(`plan updated ${hhmm(T0 + REFRESH_MS)} — alloy: pending -> merged`)
  })

  // A target of a shape the module does not write is none, and the pane follows
  // nothing: that is settled at the start, not once the lookup has answered.
  test('clears a target of a shape the module does not write without waiting for a printenv that never answers', async ($, on) => {
    const { world, clock, boot } = stage(on, { files: { '/w/mine.md': PLAN }, crew: null })
    await boot($)
    world.oldTarget = true
    await planPane($, '/w/mine.md')
    world.oldTarget = false
    const ui = await mountPane($)
    expect(await shown(ui)).toEqual(['Reading plan...'])

    world.hang = ['run printenv HOME']
    world.asked.length = 0
    expect(await boot($)).toEqual({ cwd: '/w' })
    expect(world.asked).toEqual(['run printenv HOME'])
    expect(aimedAt(world).at(-1)).toBeNull()
    expect((await shown(ui))[0]).toBe('no findings file holds a merge request table')

    // However long the clock runs, the old file is not read again: with no target
    // there is nothing to follow, whatever timer the command left behind.
    await clock.advance(10 * LOOK_MS)
    expect(world.asked).toEqual(['run printenv HOME'])
  })

  // The start looks at the target once more before it settles its timer, and the
  // answer to that look can reach it late: a hook above the engine may await
  // something after next(e). Here the answer was worked out before the person
  // chose a file, and says there is no target. By the time it arrives the choice
  // has set its own timer, and the start must not change it.
  test('does not undo a choice made while the answer to its last look at the target was on its way', async ($, on) => {
    const { world, clock } = stage(on, { files: { '/w/mine.md': PLAN }, crew: null })
    // The start reads the target twice: when it begins, and before it settles its timer.
    const late = lateAnswer(on, 'target')
    late.arm(1)
    await start($)
    await clock.settle()
    expect(late.isHeld()).toBe(true)

    await planPane($, '/w/mine.md')
    expect(world.timers).toEqual([REFRESH_MS])
    late.release()
    await clock.settle()

    world.files['/w/mine.md'] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS)
    expect((await shown(await mountPane($)))[0]).toBe('mine.md — 2/5 merged')
  })

  // The same in a crew session, where the start would put the one-minute look in
  // the place of the 5 s timer of the choice.
  test('and a crew session keeps the 5 s timer of the choice, not the one-minute look', async ($, on) => {
    const { world, clock } = stage(on, { files: { [ALPHA]: noTable, '/w/mine.md': PLAN }, crew: 'alpha' })
    const late = lateAnswer(on, 'target')
    late.arm(1)
    await start($)
    await clock.settle()
    expect(late.isHeld()).toBe(true)

    await planPane($, '/w/mine.md')
    late.release()
    await clock.settle()
    expect(world.timers).toEqual([REFRESH_MS])

    world.files['/w/mine.md'] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS)
    expect((await shown(await mountPane($)))[0]).toBe('mine.md — 2/5 merged')
  })

  // A choice can be under way when the start looks at the target: it has begun, but
  // its write has not landed, so the look does not see it. It writes and sets its
  // timer before the answer arrives. A choice counts when it is made, that is when
  // the target holds it, not when it began.
  test('does not undo a choice that began before its last look at the target and wrote after it', async ($, on) => {
    const { world, clock } = stage(on, { files: { [ALPHA]: noTable, '/w/mine.md': PLAN }, crew: 'alpha' })
    const late = lateAnswer(on, 'target')
    // The write of the choice waits until `letWrite` is called.
    let holdWrite = false
    let writing = false
    let letWrite = () => {}
    on('state.set', async (_$, e, next) => {
      if (holdWrite && e.key === 'target') {
        holdWrite = false
        writing = true
        await new Promise<void>(resolve => {
          letWrite = resolve
        })
      }
      return next(e)
    })
    // The start waits for the first read of its own findings file, ...
    let letRead = () => {}
    world.gate = new Promise<void>(resolve => {
      letRead = resolve
    })
    await start($)
    await clock.settle()

    // ... while the person chooses a file, and the choice waits to write.
    holdWrite = true
    const command = planPane($, '/w/mine.md')
    await clock.settle()
    expect(writing).toBe(true)

    // The start goes on and looks at the target, which holds no choice yet.
    late.arm()
    world.gate = undefined
    letRead()
    await clock.settle()
    expect(late.isHeld()).toBe(true)

    // The choice writes and sets its timer, and then the answer arrives.
    letWrite()
    await command
    expect(world.timers).toEqual([REFRESH_MS])
    late.release()
    await clock.settle()

    world.files['/w/mine.md'] = PLAN.replace('pipeline running, then ask for review', 'merged 15:10')
    await clock.advance(REFRESH_MS)
    expect((await shown(await mountPane($)))[0]).toBe('mine.md — 2/5 merged')
  })
})

describe('display only', () => {
  test('registers /plan-pane, and a refused pane neither fails the session start nor stops the reads', async ($, on) => {
    const { world, boot } = stage(on, { files: { [OWN]: PLAN }, refuseOpen: true })
    expect(await boot($)).toEqual({ cwd: '/w' })
    expect(world.commands).toEqual(['plan-pane'])
    expect(world.asked).toEqual([
      'run printenv HOME',
      'run printenv CREW_NAME',
      `read ${OWN}`,
      `read ${OWN}`,
    ])
    expect((await shown(await mountPane($)))[0]).toBe('gmp-deploy.md — 1/5 merged')
  })
})
