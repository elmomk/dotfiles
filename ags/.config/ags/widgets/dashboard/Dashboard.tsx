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
const sectionCss = "background-color: #16213e; border-radius: 12px; padding: 12px; margin: 6px;"

function DateTime() {
  return (
    <box orientation={V} css={sectionCss}>
      <label label="DATE & TIME" halign={Gtk.Align.START} css="font-size: 11px; font-weight: 600; color: #a0a0a0; margin-bottom: 10px;" />
      <label label={clock} halign={Gtk.Align.START} css="font-size: 32px; font-weight: 300;" />
      <label label={date} halign={Gtk.Align.START} css="font-size: 16px; color: #a0a0a0;" />
      <label label={uptime.as(u => `Uptime: ${u}`)} halign={Gtk.Align.START} css="color: #6e6e6e;" />
    </box>
  )
}

function Calendar() {
  return (
    <box orientation={V} css={sectionCss}>
      <Gtk.Calendar />
    </box>
  )
}

function Weather() {
  return (
    <box orientation={V} css={sectionCss}>
      <label label="WEATHER" halign={Gtk.Align.START} css="font-size: 11px; font-weight: 600; color: #a0a0a0; margin-bottom: 10px;" />
      <With value={weather}>
        {(w) => {
          if (!w) return <label css="color: #6e6e6e;" label="Loading weather..." halign={Gtk.Align.START} />
          return (
            <box spacing={12}>
              <label cssClasses={["icon"]} label={w.icon} css="font-size: 36px; color: #7c83ff;" />
              <box orientation={V}>
                <label label={`${w.temp}°`} halign={Gtk.Align.START} css="font-size: 28px; font-weight: 300;" />
                <label label={w.description} halign={Gtk.Align.START} css="color: #a0a0a0;" />
                <label label={`Feels like ${w.feelsLike}° · ${w.humidity}% humidity`} halign={Gtk.Align.START} css="font-size: 11px; color: #6e6e6e;" />
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}

function ResourceBar({ label, pct, detail }: { label: string; pct: number; detail: string }) {
  const color = pct > 90 ? "#f44336" : pct > 70 ? "#ff9800" : "#7c83ff"
  const width = Math.max(2, Math.round(pct * 2))
  return (
    <box orientation={V} spacing={2} css="margin: 4px 0;">
      <box>
        <label label={label} halign={Gtk.Align.START} css="font-size: 11px; color: #a0a0a0;" />
        <label label={`${Math.round(pct)}% ${detail}`} hexpand halign={Gtk.Align.END} css="font-size: 11px; font-weight: 500;" />
      </box>
      <box css="background-color: #1e2a4a; border-radius: 999px; min-height: 6px;">
        <box css={`background-color: ${color}; border-radius: 999px; min-height: 6px; min-width: ${width}px;`} />
      </box>
    </box>
  )
}

function Resources() {
  const perf = config.config.dashboard.performance

  return (
    <box orientation={V} css={sectionCss}>
      <label label="SYSTEM" halign={Gtk.Align.START} css="font-size: 11px; font-weight: 600; color: #a0a0a0; margin-bottom: 10px;" />
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
        <label label={title.as(t => t ?? "Unknown")} halign={Gtk.Align.START} ellipsize={3} css="font-weight: 500; font-size: 16px;" />
        <label label={artist.as(a => a ?? "Unknown")} halign={Gtk.Align.START} ellipsize={3} css="color: #a0a0a0;" />
        <box spacing={8} halign={Gtk.Align.START} css="margin-top: 8px;">
          <button css="min-width: 40px; min-height: 40px; border-radius: 999px;" onClicked={() => player.previous()}>
            <label cssClasses={["icon"]} label="skip_previous" />
          </button>
          <button css="min-width: 48px; min-height: 48px; border-radius: 999px; background-color: #7c83ff;" onClicked={() => player.play_pause()}>
            <label cssClasses={["icon"]} label={status.as(s =>
              s === Mpris.PlaybackStatus.PLAYING ? "pause" : "play_arrow"
            )} css="font-size: 28px; color: white;" />
          </button>
          <button css="min-width: 40px; min-height: 40px; border-radius: 999px;" onClicked={() => player.next()}>
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
    <box orientation={V} css={sectionCss}>
      <label label="NOW PLAYING" halign={Gtk.Align.START} css="font-size: 11px; font-weight: 600; color: #a0a0a0; margin-bottom: 10px;" />
      <With value={firstPlayer}>
        {(player: Mpris.Player | null) =>
          player
            ? <MediaPlayer player={player} />
            : <label css="color: #6e6e6e;" label="Nothing playing" halign={Gtk.Align.START} />
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
      <box css="background-color: #1a1a2e; border-radius: 18px; margin: 8px; padding: 12px;" halign={Gtk.Align.CENTER} valign={Gtk.Align.START} spacing={8}>
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
