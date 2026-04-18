import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { onKeyPress } from "../../lib/utils"
import config from "../../config/config"

function SessionButton({ icon, label, cssClass, command }: {
  icon: string; label: string; cssClass: string; command: string[]
}) {
  return (
    <button
      cssClasses={["session-button", cssClass]}
      onClicked={() => {
        const win = app.get_window("session")
        if (win) win.visible = false
        GLib.spawn_command_line_async(command.join(" "))
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
        <label cssClasses={["session-icon"]} label={icon} />
        <label cssClasses={["session-label"]} label={label} />
      </box>
    </button>
  )
}

export default function Session(gdkmonitor: Gdk.Monitor) {
  const cfg = config.config.session

  const buttons = [
    { icon: cfg.icons.logout, label: "Logout", cssClass: "logout", command: cfg.commands.logout },
    { icon: cfg.icons.shutdown, label: "Shutdown", cssClass: "shutdown", command: cfg.commands.shutdown },
    { icon: cfg.icons.reboot, label: "Reboot", cssClass: "reboot", command: cfg.commands.reboot },
    { icon: cfg.icons.hibernate, label: "Hibernate", cssClass: "hibernate", command: cfg.commands.hibernate },
  ]

  return (
    <window
      visible={false}
      name="session"
      cssClasses={["Session"]}
      gdkmonitor={gdkmonitor}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          const win = app.get_window("session")
          if (win) win.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["session-inner"]} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} spacing={0}>
        {buttons.map(b => <SessionButton {...b} />)}
      </box>
    </window>
  )
}
