import { createBinding, For } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Wp from "gi://AstalWp"
import { onKeyPress } from "../../../lib/utils"

export default function AudioPopout(gdkmonitor: Gdk.Monitor) {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!
  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")
  const speakers = createBinding(wp.audio, "speakers")

  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="popout-audio"
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
      <box cssClasses={["panel", "popout-inner"]} orientation={Gtk.Orientation.VERTICAL}
        css="min-width: 300px;"
      >
        {/* Volume control */}
        <box spacing={8}>
          <button cssClasses={["icon"]} onClicked={() => { speaker.mute = !speaker.mute }}>
            <label label={muted.as(m => m ? "volume_off" : "volume_up")} />
          </button>
          <label label={volume.as(v => `${Math.round(v * 100)}%`)} hexpand halign={Gtk.Align.END} />
        </box>

        {/* Separator */}
        <box css="background-color: rgba(255,255,255,0.12); min-height: 1px; margin: 8px 0;" />

        {/* Output devices */}
        <label cssClasses={["dim"]} label="Output Devices" halign={Gtk.Align.START} css="font-size: 11px; margin-bottom: 4px;" />
        <For each={speakers}>
          {(s: Wp.Endpoint) => (
            <button css="padding: 6px 8px; border-radius: 8px;" onClicked={() => { s.isDefault = true }}>
              <box spacing={8}>
                <label cssClasses={["icon"]} label={createBinding(s, "isDefault").as(d => d ? "check_circle" : "circle")} />
                <label label={createBinding(s, "description").as(d => d ?? "Unknown")} ellipsize={3} />
              </box>
            </button>
          )}
        </For>
      </box>
    </window>
  )
}
