import { createState, createComputed, For } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Apps from "gi://AstalApps"
import AppItem from "./AppItem"
import config from "../../config/config"
import { onKeyPress } from "../../lib/utils"

const [query, setQuery] = createState("")
const [selectedIndex, setSelectedIndex] = createState(0)

export default function Launcher(gdkmonitor: Gdk.Monitor) {
  const apps = new Apps.Apps()
  const cfg = config.config.launcher
  const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  function getResults(q: string): Apps.Application[] {
    if (!q) {
      return apps.get_list()
        .filter((a: Apps.Application) => !cfg.hiddenApps.includes(a.entry ?? ""))
        .slice(0, cfg.maxShown)
    }
    return apps.fuzzy_query(q)
      .filter((a: Apps.Application) => !cfg.hiddenApps.includes(a.entry ?? ""))
      .slice(0, cfg.maxShown)
  }

  function launch(q: string) {
    const results = getResults(q)
    const idx = selectedIndex.peek()
    if (results[idx]) {
      results[idx].launch()
      hide()
    }
  }

  function hide() {
    const win = app.get_window("launcher")
    if (win) win.visible = false
    setQuery("")
    setSelectedIndex(0)
  }

  const results = createComputed(() => getResults(query()))

  return (
    <window
      visible={false}
      name="launcher"
      cssClasses={["Launcher"]}
      gdkmonitor={gdkmonitor}
      anchor={BOTTOM | LEFT | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Escape) { hide(); return true }
        if (keyval === Gdk.KEY_Return) { launch(query.peek()); return true }
        if (keyval === Gdk.KEY_Down) {
          const r = getResults(query.peek())
          setSelectedIndex(Math.min(selectedIndex.peek() + 1, r.length - 1))
          return true
        }
        if (keyval === Gdk.KEY_Up) {
          setSelectedIndex(Math.max(selectedIndex.peek() - 1, 0))
          return true
        }
        return false
      })}
    >
      <box cssClasses={["launcher-inner"]} css="background-color: #141414; border-radius: 32px; margin: 8px; min-width: 580px;" orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} valign={Gtk.Align.END}>
        <box cssClasses={["search-box"]}>
          <label cssClasses={["search-icon"]} label="search" />
          <entry
            hexpand
            placeholderText="Search apps..."
            text={query}
            onChanged={(self: Gtk.Entry) => {
              setQuery(self.text)
              setSelectedIndex(0)
            }}
          />
        </box>

        <box cssClasses={["results"]} orientation={Gtk.Orientation.VERTICAL}>
          <For each={results} id={(a: Apps.Application) => a.entry ?? a.name}>
            {(a: Apps.Application, index) => (
              <AppItem app={a} selected={false} />
            )}
          </For>
        </box>
      </box>
    </window>
  )
}
