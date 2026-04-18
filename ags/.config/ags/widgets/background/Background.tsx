import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { clock, date } from "../../lib/variables"
import config from "../../config/config"

export default function Background(gdkmonitor: Gdk.Monitor) {
  const cfg = config.config.background
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  if (!cfg.enabled) return null

  return (
    <window
      visible
      name={`background-${gdkmonitor.get_connector()}`}
      cssClasses={["Background"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      layer={Astal.Layer.BACKGROUND}
      exclusivity={Astal.Exclusivity.IGNORE}
      application={app}
    >
      <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        {cfg.desktopClock.enabled && (
          <box cssClasses={["desktop-clock"]} orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER}>
            <label cssClasses={["clock-time"]} label={clock} />
            <label cssClasses={["clock-date"]} label={date} />
          </box>
        )}
      </box>
    </window>
  )
}
