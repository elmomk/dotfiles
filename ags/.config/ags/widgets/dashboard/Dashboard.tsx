import { createBinding, createComputed, With } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Mpris from "gi://AstalMpris"
import { clock, date, uptime } from "../../lib/variables"
import { onKeyPress } from "../../lib/utils"
import { weather } from "../../services/weather"
import { usage } from "../../services/systemUsage"
import config from "../../config/config"

const V = Gtk.Orientation.VERTICAL
// Styles via .panel-section class

function DateTime() {
  return (
    <box orientation={V} cssClasses={["panel-section"]}>
      <label label="DATE & TIME" halign={Gtk.Align.START} cssClasses={["section-title"]} />
      <label label={clock} halign={Gtk.Align.START} css="font-size: 64px; font-weight: 300;" />
      <label label={date} halign={Gtk.Align.START} css="font-size: 30px; color: #8a8578;" />
      <label label={uptime.as(u => `Uptime: ${u}`)} halign={Gtk.Align.START} css="color: #5a5650; font-size: 22px;" />
    </box>
  )
}

function Calendar() {
  return (
    <box orientation={V} cssClasses={["panel-section"]}>
      <Gtk.Calendar />
    </box>
  )
}

function Weather() {
  return (
    <box orientation={V} cssClasses={["panel-section"]}>
      <label label="WEATHER" halign={Gtk.Align.START} cssClasses={["section-title"]} />
      <With value={weather}>
        {(w) => {
          if (!w) return <label css="color: #5a5650; font-size: 22px;" label="Loading weather..." halign={Gtk.Align.START} />
          return (
            <box spacing={12}>
              <label cssClasses={["icon"]} label={w.icon} css="font-size: 72px; color: #e2a44d;" />
              <box orientation={V}>
                <label label={`${w.temp}°`} halign={Gtk.Align.START} css="font-size: 56px; font-weight: 300;" />
                <label label={w.description} halign={Gtk.Align.START} css="color: #8a8578; font-size: 26px;" />
                <label label={`Feels like ${w.feelsLike}° · ${w.humidity}% humidity`} halign={Gtk.Align.START} css="font-size: 22px; color: #5a5650;" />
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}

function ResourceBar({ label, pct, detail }: { label: string; pct: number; detail: string }) {
  const color = pct > 90 ? "#d4564e" : pct > 70 ? "#d4884e" : "#e2a44d"
  const width = Math.max(2, Math.round(pct * 2))
  return (
    <box orientation={V} spacing={2} css="margin: 4px 0;">
      <box>
        <label label={label} halign={Gtk.Align.START} css="font-size: 22px; color: #8a8578;" />
        <label label={`${Math.round(pct)}% ${detail}`} hexpand halign={Gtk.Align.END} css="font-size: 22px; font-weight: 500;" />
      </box>
      <box css="background-color: #262626; border-radius: 999px; min-height: 12px;">
        <box css={`background-color: ${color}; border-radius: 999px; min-height: 12px; min-width: ${width}px;`} />
      </box>
    </box>
  )
}

function Resources() {
  const perf = config.config.dashboard.performance

  return (
    <box orientation={V} cssClasses={["panel-section"]}>
      <label label="SYSTEM" halign={Gtk.Align.START} cssClasses={["section-title"]} />
      <With value={usage}>
        {(u) => (
          <box orientation={V}>
            {perf.showCpu && <ResourceBar label="CPU" pct={u.cpuPercent} detail={u.cpuTempC ? `· ${u.cpuTempC}°C` : ""} />}
            {perf.showMemory && <ResourceBar label="RAM" pct={u.memPercent} detail={`${u.memUsedGb.toFixed(1)}/${u.memTotalGb.toFixed(0)} GB`} />}
            {perf.showStorage && <ResourceBar label="Storage" pct={u.storagePercent} detail={`${u.storageUsedGb.toFixed(0)}/${u.storageTotalGb.toFixed(0)} GB`} />}
            {perf.showGpu && u.gpuPercent > 0 && <ResourceBar label="GPU" pct={u.gpuPercent} detail={u.gpuTempC ? `· ${u.gpuTempC}°C` : ""} />}
          </box>
        )}
      </With>
    </box>
  )
}

function MediaPlayer({ player }: { player: Mpris.Player }) {
  const title = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const status = createBinding(player, "playbackStatus")

  return (
    <box spacing={12}>
      <box orientation={V} hexpand valign={Gtk.Align.CENTER}>
        <label label={title.as(t => t ?? "Unknown")} halign={Gtk.Align.START} ellipsize={3} css="font-weight: 500; font-size: 30px;" />
        <label label={artist.as(a => a ?? "Unknown")} halign={Gtk.Align.START} ellipsize={3} css="color: #8a8578; font-size: 26px;" />
        <box spacing={8} halign={Gtk.Align.START} css="margin-top: 8px;">
          <button css="min-width: 80px; min-height: 80px; border-radius: 999px;" onClicked={() => player.previous()}>
            <label cssClasses={["icon"]} label="skip_previous" />
          </button>
          <button css="min-width: 96px; min-height: 96px; border-radius: 999px; background-color: #e2a44d;" onClicked={() => player.play_pause()}>
            <label cssClasses={["icon"]} label={status.as(s =>
              s === Mpris.PlaybackStatus.PLAYING ? "pause" : "play_arrow"
            )} css="font-size: 28px; color: white;" />
          </button>
          <button css="min-width: 80px; min-height: 80px; border-radius: 999px;" onClicked={() => player.next()}>
            <label cssClasses={["icon"]} label="skip_next" />
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
    <box orientation={V} cssClasses={["panel-section"]}>
      <label label="NOW PLAYING" halign={Gtk.Align.START} cssClasses={["section-title"]} />
      <With value={firstPlayer}>
        {(player: Mpris.Player | null) =>
          player
            ? <MediaPlayer player={player} />
            : <label css="color: #5a5650; font-size: 22px;" label="Nothing playing" halign={Gtk.Align.START} />
        }
      </With>
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
      keymode={Astal.Keymode.ON_DEMAND}
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
      <box cssClasses={["panel"]} halign={Gtk.Align.CENTER} valign={Gtk.Align.START} spacing={8}>
        <box orientation={V} spacing={8}>
          <DateTime />
          <Calendar />
          <Weather />
        </box>
        <box orientation={V} spacing={8}>
          <Media />
          <Resources />
        </box>
      </box>
    </window>
  )
}
