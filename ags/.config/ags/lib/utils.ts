import GLib from "gi://GLib"
import Gio from "gi://Gio"

export function exec(cmd: string): string {
  const [ok, out] = GLib.spawn_command_line_sync(cmd)
  if (!ok) return ""
  return new TextDecoder().decode(out).trim()
}

export function execAsync(cmd: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    const proc = Gio.Subprocess.new(cmd, Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE)
    proc.communicate_utf8_async(null, null, (_proc, res) => {
      try {
        const [, stdout, stderr] = proc.communicate_utf8_finish(res)
        if (proc.get_successful()) {
          resolve(stdout?.trim() ?? "")
        } else {
          reject(new Error(stderr?.trim() ?? "Command failed"))
        }
      } catch (e) {
        reject(e)
      }
    })
  })
}

export function readFile(path: string): string | null {
  try {
    const file = Gio.File.new_for_path(path)
    const [ok, contents] = file.load_contents(null)
    if (ok) return new TextDecoder().decode(contents)
  } catch { /* */ }
  return null
}

export function timeout(ms: number, fn: () => void): number {
  return GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
    fn()
    return GLib.SOURCE_REMOVE
  })
}

export function interval(ms: number, fn: () => void): number {
  return GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
    fn()
    return GLib.SOURCE_CONTINUE
  })
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

export function formatTime(date: Date, use12h: boolean): string {
  const h = date.getHours()
  const m = date.getMinutes().toString().padStart(2, "0")
  if (use12h) {
    const period = h >= 12 ? "PM" : "AM"
    const h12 = h % 12 || 12
    return `${h12}:${m} ${period}`
  }
  return `${h.toString().padStart(2, "0")}:${m}`
}

export function formatDate(date: Date): string {
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  return `${days[date.getDay()]}, ${months[date.getMonth()]} ${date.getDate()}`
}

export function iconName(name: string): string {
  return name
}

import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"

export function onKeyPress(
  widget: Gtk.Widget,
  handler: (keyval: number, keycode: number, state: Gdk.ModifierType) => boolean,
) {
  const controller = new Gtk.EventControllerKey()
  controller.connect("key-pressed", (_ctrl: Gtk.EventControllerKey, keyval: number, keycode: number, state: Gdk.ModifierType) => {
    return handler(keyval, keycode, state)
  })
  widget.add_controller(controller)
}
