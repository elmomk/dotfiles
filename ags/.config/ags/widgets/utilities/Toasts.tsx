import { createState, For } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import config from "../../config/config"

interface Toast {
  id: number
  title: string
  body: string
  icon: string
}

let nextId = 0
const [toasts, setToasts] = createState<Toast[]>([])

export function toast(title: string, body: string, icon: string = "info") {
  const id = nextId++
  const maxToasts = config.config.utilities.maxToasts
  const current = toasts.peek()
  const updated = [{ id, title, body, icon }, ...current].slice(0, maxToasts)
  setToasts(updated)

  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 4000, () => {
    setToasts(toasts.peek().filter(t => t.id !== id))
    return GLib.SOURCE_REMOVE
  })
}

export default function Toasts(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={toasts.as(t => t.length > 0)}
      name={`toasts-${gdkmonitor.get_connector()}`}
      cssClasses={["Toasts"]}
      gdkmonitor={gdkmonitor}
      anchor={BOTTOM | RIGHT}
      layer={Astal.Layer.OVERLAY}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <For each={toasts} id={(t: Toast) => t.id}>
          {(t: Toast) => (
            <box cssClasses={["Toast"]} spacing={8}>
              <label cssClasses={["toast-icon"]} label={t.icon} />
              <box orientation={Gtk.Orientation.VERTICAL}>
                <label cssClasses={["toast-title"]} label={t.title} halign={0} />
                {t.body && <label cssClasses={["toast-body"]} label={t.body} halign={0} />}
              </box>
            </box>
          )}
        </For>
      </box>
    </window>
  )
}
