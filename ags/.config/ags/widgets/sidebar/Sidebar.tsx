import { createBinding, For } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Notifd from "gi://AstalNotifd"
import Notification from "../notifications/Notification"
import { onKeyPress } from "../../lib/utils"

export default function Sidebar(gdkmonitor: Gdk.Monitor) {
  const notifd = Notifd.get_default()
  const notifs = createBinding(notifd, "notifications")
  const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="sidebar"
      cssClasses={["Sidebar"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | BOTTOM | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          const win = app.get_window("sidebar")
          if (win) win.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["sidebar-inner"]} css="background-color: #1a1a2e; border-radius: 18px; margin: 8px; padding: 12px; min-width: 380px;" orientation={Gtk.Orientation.VERTICAL}>
        <box cssClasses={["sidebar-header"]}>
          <label cssClasses={["sidebar-title"]} label="Notifications" hexpand halign={Gtk.Align.START} />
          <button cssClasses={["clear-all"]} onClicked={() => {
            for (const n of notifd.get_notifications()) {
              n.dismiss()
            }
          }}>
            <label label="Clear all" />
          </button>
        </box>

        <Gtk.ScrolledWindow vexpand>
          <box orientation={Gtk.Orientation.VERTICAL}>
            <For each={notifs} id={(n: Notifd.Notification) => n.id}>
              {(n: Notifd.Notification) => <Notification notification={n} />}
            </For>
          </box>
        </Gtk.ScrolledWindow>
      </box>
    </window>
  )
}
