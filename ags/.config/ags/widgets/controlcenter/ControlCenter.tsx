import { createState, createBinding, With } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Wp from "gi://AstalWp"
import { onKeyPress } from "../../lib/utils"

type Pane = "appearance" | "audio" | "network" | "bluetooth"

const [activePane, setActivePane] = createState<Pane>("appearance")

const navItems: { id: Pane; icon: string; label: string }[] = [
  { id: "appearance", icon: "palette", label: "Appearance" },
  { id: "audio", icon: "volume_up", label: "Audio" },
  { id: "network", icon: "wifi", label: "Network" },
  { id: "bluetooth", icon: "bluetooth", label: "Bluetooth" },
]

function NavRail() {
  return (
    <box cssClasses={["nav-rail"]} orientation={Gtk.Orientation.VERTICAL} spacing={4} valign={Gtk.Align.START}>
      {navItems.map(item => (
        <button
          cssClasses={activePane.as(p =>
            p === item.id ? ["nav-item", "active"] : ["nav-item"]
          )}
          tooltipText={item.label}
          onClicked={() => setActivePane(item.id)}
        >
          <label label={item.icon} />
        </button>
      ))}
    </box>
  )
}

function AudioPane() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!
  const volume = createBinding(speaker, "volume")

  return (
    <box cssClasses={["pane"]} orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["pane-title"]} label="Audio" halign={Gtk.Align.START} />
      <box cssClasses={["setting-row"]} spacing={12}>
        <label label="volume_up" cssClasses={["icon-lg"]} />
        <box orientation={Gtk.Orientation.VERTICAL} hexpand>
          <label cssClasses={["setting-label"]} label="Volume" halign={Gtk.Align.START} />
          <label cssClasses={["setting-description"]} label={volume.as(v => `${Math.round(v * 100)}%`)} halign={Gtk.Align.START} />
        </box>
      </box>
    </box>
  )
}

function PlaceholderPane({ title }: { title: string }) {
  return (
    <box cssClasses={["pane"]} orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["pane-title"]} label={title} halign={Gtk.Align.START} />
      <label cssClasses={["dim"]} label="Coming soon..." halign={Gtk.Align.START} />
    </box>
  )
}

function PaneContent() {
  return (
    <box hexpand vexpand>
      <With value={activePane}>
        {(pane: Pane) => {
          switch (pane) {
            case "audio": return <AudioPane />
            case "appearance": return <PlaceholderPane title="Appearance" />
            case "network": return <PlaceholderPane title="Network" />
            case "bluetooth": return <PlaceholderPane title="Bluetooth" />
          }
        }}
      </With>
    </box>
  )
}

export default function ControlCenter(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      visible={false}
      name="controlcenter"
      cssClasses={["ControlCenter"]}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          const win = app.get_window("controlcenter")
          if (win) win.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["cc-inner"]} css="background-color: #1a1a2e; border-radius: 18px; margin: 8px; min-width: 700px; min-height: 500px;" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <NavRail />
        <PaneContent />
      </box>
    </window>
  )
}
