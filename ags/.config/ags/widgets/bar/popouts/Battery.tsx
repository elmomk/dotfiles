import { createBinding } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Battery from "gi://AstalBattery"
import { onKeyPress } from "../../../lib/utils"

export default function BatteryPopout(gdkmonitor: Gdk.Monitor) {
  const bat = Battery.get_default()
  const pct = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")
  const timeToEmpty = createBinding(bat, "timeToEmpty")
  const timeToFull = createBinding(bat, "timeToFull")

  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="popout-battery"
      cssClasses={["Popout"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          self.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["panel", "popout-inner"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}
        css="min-width: 250px;"
      >
        <box spacing={8}>
          <label cssClasses={["icon"]} label={pct.as(p => {
            if (bat.charging) return "battery_charging_full"
            if (p > 0.9) return "battery_full"
            if (p > 0.6) return "battery_5_bar"
            return "battery_3_bar"
          })} css="font-size: 56px;" />
          <box orientation={Gtk.Orientation.VERTICAL}>
            <label label={pct.as(p => `${Math.round(p * 100)}%`)} halign={Gtk.Align.START} css="font-size: 44px; font-weight: 300;" />
            <label cssClasses={["dim"]} label={charging.as(c => c ? "Charging" : "On Battery")} halign={Gtk.Align.START} />
          </box>
        </box>

        <label cssClasses={["dim"]} halign={Gtk.Align.START}
          label={charging.as(c => {
            if (c) {
              const secs = bat.timeToFull
              if (secs <= 0) return ""
              const h = Math.floor(secs / 3600)
              const m = Math.floor((secs % 3600) / 60)
              return `Full in ${h}h ${m}m`
            } else {
              const secs = bat.timeToEmpty
              if (secs <= 0) return ""
              const h = Math.floor(secs / 3600)
              const m = Math.floor((secs % 3600) / 60)
              return `${h}h ${m}m remaining`
            }
          })}
        />
      </box>
    </window>
  )
}
