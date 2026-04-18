import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Workspaces from "./Workspaces"
import Clock from "./Clock"
import StatusIcons from "./StatusIcons"
import SysTray from "./SysTray"
import ActiveWindow from "./ActiveWindow"
import config from "../../config/config"

function BarEntry({ id }: { id: string }) {
  switch (id) {
    case "logo":
      return <label cssClasses={["logo", "icon"]} label="deployed_code" />
    case "workspaces":
      return <Workspaces />
    case "spacer":
      return <box hexpand />
    case "activeWindow":
      return <ActiveWindow />
    case "tray":
      return <SysTray />
    case "clock":
      return <Clock />
    case "statusIcons":
      return <StatusIcons />
    case "power":
      return (
        <button
          cssClasses={["power-button"]}
          onClicked={() => {
            const win = app.get_window("session")
            if (win) win.visible = !win.visible
          }}
        >
          <label cssClasses={["icon"]} label="power_settings_new" />
        </button>
      )
    default:
      return <box />
  }
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const cfg = config.config.bar
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name={`bar-${gdkmonitor.get_connector()}`}
      cssClasses={["Bar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <box cssClasses={["bar-inner"]} spacing={8}>
        {cfg.entries
          .filter(e => e.enabled)
          .map(e => <BarEntry id={e.id} />)}
      </box>
    </window>
  )
}
