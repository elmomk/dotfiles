import { createBinding } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Network from "gi://AstalNetwork"
import { onKeyPress } from "../../../lib/utils"

export default function NetworkPopout(gdkmonitor: Gdk.Monitor) {
  const net = Network.get_default()
  const primary = createBinding(net, "primary")

  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="popout-network"
      cssClasses={["Popout"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          self.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["popout-inner"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}
        css="background-color: #1a1a2e; border-radius: 18px; margin: 8px; padding: 12px; min-width: 300px;"
      >
        <label css="font-weight: 600; font-size: 16px;" label="Network" halign={Gtk.Align.START} />

        <box spacing={8}>
          <label cssClasses={["icon"]} label={primary.as(p => {
            if (p === Network.Primary.WIFI) return "wifi"
            if (p === Network.Primary.WIRED) return "lan"
            return "wifi_off"
          })} />
          <box orientation={Gtk.Orientation.VERTICAL}>
            <label label={primary.as(p => {
              if (p === Network.Primary.WIFI && net.wifi)
                return net.wifi.ssid ?? "Connected"
              if (p === Network.Primary.WIRED) return "Ethernet"
              return "Disconnected"
            })} halign={Gtk.Align.START} />
            <label cssClasses={["dim"]} label={primary.as(p => {
              if (p === Network.Primary.WIFI && net.wifi)
                return `Signal: ${net.wifi.strength}%`
              return ""
            })} halign={Gtk.Align.START} />
          </box>
        </box>
      </box>
    </window>
  )
}
