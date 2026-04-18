import app from "ags/gtk4/app"
import style from "./style/main.scss"
import Bar from "./widgets/bar/Bar"
import OSD, { setupOSD } from "./widgets/osd/OSD"
import NotificationPopup, { setupNotifications } from "./widgets/notifications/Popup"
import Launcher from "./widgets/launcher/Launcher"
import Dashboard from "./widgets/dashboard/Dashboard"
import Session from "./widgets/session/Session"
import Sidebar from "./widgets/sidebar/Sidebar"
import Utilities from "./widgets/utilities/Utilities"
import Toasts from "./widgets/utilities/Toasts"
import ControlCenter from "./widgets/controlcenter/ControlCenter"
import Background from "./widgets/background/Background"
import Lock from "./widgets/lock/Lock"
import WindowInfo from "./widgets/windowinfo/WindowInfo"
import AudioPopout from "./widgets/bar/popouts/Audio"
import BatteryPopout from "./widgets/bar/popouts/Battery"
import NetworkPopout from "./widgets/bar/popouts/Network"
import config from "./config/config"

app.start({
  instanceName: "caelestia",
  css: style,
  requestHandler(request, respond) {
    // Handle CLI requests: ags request <command>
    const [cmd, ...args] = request.split(" ")
    switch (cmd) {
      case "toggle": {
        const name = args[0]
        const win = app.get_window(name)
        if (win) win.visible = !win.visible
        respond(`toggled ${name}`)
        break
      }
      case "show": {
        const name = args[0]
        const win = app.get_window(name)
        if (win) win.visible = true
        respond(`shown ${name}`)
        break
      }
      case "hide": {
        const name = args[0]
        const win = app.get_window(name)
        if (win) win.visible = false
        respond(`hidden ${name}`)
        break
      }
      default:
        respond(`unknown command: ${cmd}`)
    }
  },
  main() {
    const cfg = config.config
    const monitors = app.get_monitors()

    // Setup services
    setupOSD()
    setupNotifications()

    // Create per-monitor windows
    for (const monitor of monitors) {
      // Always create bar
      Bar(monitor)

      // Overlays (only on primary for now)
      OSD(monitor)
      NotificationPopup(monitor)
      Toasts(monitor)
    }

    // Single-instance windows (on primary monitor)
    const primary = monitors[0]
    if (primary) {
      if (cfg.launcher.enabled) Launcher(primary)
      if (cfg.dashboard.enabled) Dashboard(primary)
      if (cfg.session.enabled) Session(primary)
      if (cfg.sidebar.enabled) Sidebar(primary)
      if (cfg.utilities.enabled) Utilities(primary)
      if (cfg.background.enabled) Background(primary)
      ControlCenter(primary)
      Lock(primary)
      WindowInfo(primary)
      AudioPopout(primary)
      BatteryPopout(primary)
      NetworkPopout(primary)
    }
  },
})
