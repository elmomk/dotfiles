export type Status =
  | 'merged'
  | 'running'
  | 'green'
  | 'draft'
  | 'held'
  | 'superseded'
  | 'dropped'
  | 'pending'
  | 'blocked'
  | 'unknown'

export type MrRow = {
  n: string
  id: string
  mr: string
  status: Status
  next: string
  go: string
}
export type Decision = { id: string; sent: string; asks: string }
export type PlanVersion = { title: string; at: string }

export type PlanSnapshot = {
  // Which shape this is. State outlives a hot reload, so a snapshot an earlier
  // version of the module left (it has no `v`, and a `readAt`) can be found here.
  v: 2
  file: string
  ok: boolean
  error?: string
  // Whether the file holds each table at all: its heading, with table lines
  // under it. A plan kept as a list under the heading is no table.
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
  changedAt: number | null
  changes: string[]
}

// The file the pane follows, and how it came to be: `auto` when the module
// itself pointed the pane at the session's own plan, `hand` when the person did
// (`/plan-pane`, or a press in the chooser). The module changes an `auto`
// target at a session start, and never a `hand` one.
//
// An earlier version of the module kept the path alone, a string, with no
// record of how it was chosen; state outlives a hot reload, so one can be found.
export type Target = {
  file: string
  by: 'auto' | 'hand'
}

// A findings file that holds a merge request table, as the chooser lists it.
export type Choice = {
  file: string
  merged: number
  total: number
}

declare module 'claude-code' {
  interface PluginState {
    'plan-pane': {
      snap: PlanSnapshot | null
      // Null while the pane follows nothing: it then shows the chooser.
      target: Target | null
      // What the last look through the findings folder found, in name order;
      // it is the chooser's list.
      choices: Choice[]
    }
  }
}
