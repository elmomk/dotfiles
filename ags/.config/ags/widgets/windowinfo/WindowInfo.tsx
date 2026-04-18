import { createBinding, With } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Hyprland from "gi://AstalHyprland"
import { onKeyPress } from "../../lib/utils"

export default function WindowInfo(gdkmonitor: Gdk.Monitor) {
  const hypr = Hyprland.get_default()
  const client = createBinding(hypr, "focusedClient")

  return (
    <window
      visible={false}
      name="windowinfo"
      cssClasses={["WindowInfo"]}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          const win = app.get_window("windowinfo")
          if (win) win.visible = false
          return true
        }
        return false
      })}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={4} css="padding: 12px;">
        <With value={client}>
          {(c: Hyprland.Client | null) => {
            if (!c) return <label cssClasses={["dim"]} label="No focused window" />
            return (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label label={`Title: ${c.title}`} halign={Gtk.Align.START} />
                <label label={`Class: ${c.class}`} halign={Gtk.Align.START} cssClasses={["dim"]} />
              </box>
            )
          }}
        </With>
      </box>
    </window>
  )
}
