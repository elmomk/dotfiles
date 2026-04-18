import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Network from "gi://AstalNetwork"
import Bluetooth from "gi://AstalBluetooth"
import Wp from "gi://AstalWp"
import { onKeyPress } from "../../lib/utils"
import config from "../../config/config"

interface ToggleDef {
  id: string
  icon: string
  label: string
  onToggle: () => void
}

function getToggles(): ToggleDef[] {
  const net = Network.get_default()
  const bt = Bluetooth.get_default()
  const wp = Wp.get_default()!
  const mic = wp.audio.defaultMicrophone

  return [
    { id: "wifi", icon: "wifi", label: "WiFi", onToggle: () => { if (net.wifi) net.wifi.enabled = !net.wifi.enabled } },
    { id: "bluetooth", icon: "bluetooth", label: "Bluetooth", onToggle: () => { bt.isPowered = !bt.isPowered } },
    { id: "mic", icon: "mic", label: "Microphone", onToggle: () => { if (mic) mic.mute = !mic.mute } },
    { id: "dnd", icon: "do_not_disturb_on", label: "DND", onToggle: () => {} },
  ]
}

export default function Utilities(gdkmonitor: Gdk.Monitor) {
  const cfg = config.config.utilities
  const { BOTTOM, RIGHT } = Astal.WindowAnchor
  const enabledIds = new Set(cfg.quickToggles.filter(t => t.enabled).map(t => t.id))

  return (
    <window
      visible={false}
      name="utilities"
      cssClasses={["Utilities"]}
      gdkmonitor={gdkmonitor}
      anchor={BOTTOM | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          const win = app.get_window("utilities")
          if (win) win.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["utilities-inner"]} css="background-color: #1a1a2e; border-radius: 18px; margin: 8px; padding: 12px; min-width: 380px;" orientation={Gtk.Orientation.VERTICAL}>
        <box cssClasses={["toggle-grid"]} homogeneous>
          {getToggles()
            .filter(t => enabledIds.has(t.id))
            .map(t => (
              <button cssClasses={["toggle"]} onClicked={t.onToggle}>
                <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                  <label cssClasses={["toggle-icon"]} label={t.icon} />
                  <label cssClasses={["toggle-label"]} label={t.label} />
                </box>
              </button>
            ))}
        </box>
      </box>
    </window>
  )
}
