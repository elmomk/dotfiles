import { createBinding, createComputed, With } from "ags"
import { createPoll } from "ags/time"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Mpris from "gi://AstalMpris"
import { clock, date, uptime } from "../../lib/variables"
import { onKeyPress } from "../../lib/utils"

function DateTime() {
  return (
    <box cssClasses={["dash-section"]} css="background-color: #16213e; border-radius: 12px; padding: 12px; margin: 6px;" orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["section-title"]} label="Date & Time" halign={Gtk.Align.START} />
      <label label={clock} halign={Gtk.Align.START} css="font-size: 32px; font-weight: 300;" />
      <label label={date} halign={Gtk.Align.START} css="font-size: 16px;" cssClasses={["dim"]} />
      <label label={uptime.as(u => `Uptime: ${u}`)} halign={Gtk.Align.START} cssClasses={["muted"]} />
    </box>
  )
}

function Calendar() {
  return (
    <box cssClasses={["dash-section", "calendar"]} css="background-color: #16213e; border-radius: 12px; padding: 12px; margin: 6px;" orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["section-title"]} label="Calendar" halign={Gtk.Align.START} />
      <Gtk.Calendar />
    </box>
  )
}

function MediaPlayer({ player }: { player: Mpris.Player }) {
  const title = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const status = createBinding(player, "playbackStatus")

  return (
    <box spacing={12}>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
        <label cssClasses={["media-title"]} label={title.as(t => t ?? "Unknown")} halign={Gtk.Align.START} ellipsize={3} />
        <label cssClasses={["media-artist"]} label={artist.as(a => a ?? "Unknown")} halign={Gtk.Align.START} ellipsize={3} />
        <box cssClasses={["media-controls"]} spacing={8} halign={Gtk.Align.START}>
          <button cssClasses={["media-btn"]} onClicked={() => player.previous()}>
            <label label="skip_previous" />
          </button>
          <button cssClasses={["media-btn", "play"]} onClicked={() => player.play_pause()}>
            <label label={status.as(s =>
              s === Mpris.PlaybackStatus.PLAYING ? "pause" : "play_arrow"
            )} />
          </button>
          <button cssClasses={["media-btn"]} onClicked={() => player.next()}>
            <label label="skip_next" />
          </button>
        </box>
      </box>
    </box>
  )
}

function Media() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")
  const firstPlayer = createComputed(() => {
    const list = players()
    return list.length > 0 ? list[0] : null
  })

  return (
    <box cssClasses={["dash-section", "media"]} css="background-color: #16213e; border-radius: 12px; padding: 12px; margin: 6px;" orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["section-title"]} label="Now Playing" halign={Gtk.Align.START} />
      <With value={firstPlayer}>
        {(player: Mpris.Player | null) =>
          player
            ? <MediaPlayer player={player} />
            : <label cssClasses={["dim"]} label="Nothing playing" halign={Gtk.Align.START} />
        }
      </With>
    </box>
  )
}

function Resources() {
  const cpuUsage = createPoll("0%", 2000, ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2)}'"], (out: string) => `${out.trim()}%`)
  const memUsage = createPoll("0%", 2000, ["bash", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'"], (out: string) => `${out.trim()}%`)

  return (
    <box cssClasses={["dash-section", "resources"]} css="background-color: #16213e; border-radius: 12px; padding: 12px; margin: 6px;" orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={["section-title"]} label="System" halign={Gtk.Align.START} />
      <box spacing={4}>
        <label cssClasses={["resource-label"]} label="CPU" />
        <label cssClasses={["resource-value"]} label={cpuUsage} hexpand halign={Gtk.Align.END} />
      </box>
      <box spacing={4}>
        <label cssClasses={["resource-label"]} label="RAM" />
        <label cssClasses={["resource-value"]} label={memUsage} hexpand halign={Gtk.Align.END} />
      </box>
    </box>
  )
}

export default function Dashboard(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="dashboard"
      cssClasses={["Dashboard"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) {
          const win = app.get_window("dashboard")
          if (win) win.visible = false
          return true
        }
        return false
      })}
    >
      <box cssClasses={["dash-inner"]} css="background-color: #1a1a2e; border-radius: 18px; margin: 8px; padding: 12px;" halign={Gtk.Align.CENTER} valign={Gtk.Align.START} spacing={8}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <DateTime />
          <Calendar />
        </box>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <Media />
          <Resources />
        </box>
      </box>
    </window>
  )
}
