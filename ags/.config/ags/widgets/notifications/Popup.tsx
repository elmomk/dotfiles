import { createState, For } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Notifd from "gi://AstalNotifd"
import Notification from "./Notification"
import config from "../../config/config"

const [popups, setPopups] = createState<Notifd.Notification[]>([])

export function setupNotifications() {
  const notifd = Notifd.get_default()
  const timeouts = new Map<number, number>()

  notifd.connect("notified", (_self: Notifd.Notifd, id: number) => {
    const n = notifd.get_notification(id)
    if (!n) return

    setPopups([n, ...popups.peek()])

    const expireMs = n.expireTimeout > 0
      ? n.expireTimeout
      : config.config.notifs.defaultExpireTimeout

    if (config.config.notifs.expire) {
      const tid = GLib.timeout_add(GLib.PRIORITY_DEFAULT, expireMs, () => {
        dismiss(id)
        timeouts.delete(id)
        return GLib.SOURCE_REMOVE
      })
      timeouts.set(id, tid)
    }
  })

  notifd.connect("resolved", (_self: Notifd.Notifd, id: number) => {
    dismiss(id)
    const tid = timeouts.get(id)
    if (tid) {
      GLib.source_remove(tid)
      timeouts.delete(id)
    }
  })

  function dismiss(id: number) {
    setPopups(popups.peek().filter(n => n.id !== id))
  }
}

export default function NotificationPopup(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={popups.as(p => p.length > 0)}
      name={`notifications-${gdkmonitor.get_connector()}`}
      cssClasses={["Notifications"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      layer={Astal.Layer.OVERLAY}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <For each={popups} id={(n: Notifd.Notification) => n.id}>
          {(n: Notifd.Notification) => (
            <Notification
              notification={n}
              onDismiss={() => setPopups(popups.peek().filter(p => p.id !== n.id))}
            />
          )}
        </For>
      </box>
    </window>
  )
}
