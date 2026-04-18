import { createState } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Wp from "gi://AstalWp"
import config from "../../config/config"
import { brightness } from "../../services/brightness"

const [visible, setVisible] = createState(false)
const [osdIcon, setOsdIcon] = createState("volume_up")
const [osdValue, setOsdValue] = createState(0)
let hideTimeout: number | null = null

function show(icon: string, value: number) {
  setOsdIcon(icon)
  setOsdValue(value)
  setVisible(true)

  if (hideTimeout !== null) GLib.source_remove(hideTimeout)
  hideTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, config.config.osd.hideDelay, () => {
    setVisible(false)
    hideTimeout = null
    return GLib.SOURCE_REMOVE
  })
}

export function setupOSD() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!
  const mic = wp.audio.defaultMicrophone

  let lastVolume = speaker.volume
  let lastMute = speaker.mute

  speaker.connect("notify::volume", () => {
    if (Math.abs(speaker.volume - lastVolume) > 0.001) {
      const icon = speaker.mute ? "volume_off" : speaker.volume > 0.66 ? "volume_up" : speaker.volume > 0.33 ? "volume_down" : "volume_mute"
      show(icon, speaker.volume)
      lastVolume = speaker.volume
    }
  })

  speaker.connect("notify::mute", () => {
    if (speaker.mute !== lastMute) {
      show(speaker.mute ? "volume_off" : "volume_up", speaker.volume)
      lastMute = speaker.mute
    }
  })

  if (mic && config.config.osd.enableMicrophone) {
    mic.connect("notify::volume", () => {
      show(mic.mute ? "mic_off" : "mic", mic.volume)
    })
  }

  // Brightness OSD
  if (config.config.osd.enableBrightness) {
    let lastBrightness = brightness.peek()
    brightness.subscribe(() => {
      const val = brightness.peek()
      if (Math.abs(val - lastBrightness) > 0.001) {
        const icon = val > 0.66 ? "brightness_high" : val > 0.33 ? "brightness_medium" : "brightness_low"
        show(icon, val)
        lastBrightness = val
      }
    })
  }
}

function OsdBar() {
  // Visual bar using a box with dynamic width
  return (
    <box cssClasses={["osd-bar-track"]} valign={Gtk.Align.CENTER}>
      <box
        cssClasses={["osd-bar-fill"]}
        css={osdValue.as(v => `min-height: ${Math.round(v * 140)}px;`)}
      />
    </box>
  )
}

export default function OSD(gdkmonitor: Gdk.Monitor) {
  const { RIGHT, TOP, BOTTOM } = Astal.WindowAnchor

  return (
    <window
      visible={visible}
      name={`osd-${gdkmonitor.get_connector()}`}
      cssClasses={["OSD"]}
      gdkmonitor={gdkmonitor}
      anchor={RIGHT | TOP | BOTTOM}
      layer={Astal.Layer.OVERLAY}
      application={app}
    >
      <box cssClasses={["osd-inner"]}  orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <label cssClasses={["osd-icon"]} label={osdIcon} />
        <OsdBar />
        <label cssClasses={["osd-value"]} label={osdValue.as(v =>
          `${Math.round(v * 100)}%`
        )} />
      </box>
    </window>
  )
}
