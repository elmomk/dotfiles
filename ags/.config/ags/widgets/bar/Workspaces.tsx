import { Gtk } from "ags/gtk4"
import { createBinding, createComputed, For } from "ags"
import Hyprland from "gi://AstalHyprland"
import config from "../../config/config"

export default function Workspaces() {
  const hypr = Hyprland.get_default()
  const cfg = config.config.bar.workspaces
  const workspaces = createBinding(hypr, "workspaces")
  const focusedWs = createBinding(hypr, "focusedWorkspace")

  const items = createComputed(() => {
    const wss = workspaces()
    const visible = wss
      .filter((ws: Hyprland.Workspace) => ws.id > 0 && !ws.name.startsWith("special:"))
      .sort((a: Hyprland.Workspace, b: Hyprland.Workspace) => a.id - b.id)

    const maxId = Math.max(cfg.shown, ...visible.map((ws: Hyprland.Workspace) => ws.id))
    const result: Array<{ id: number; occupied: boolean }> = []
    for (let i = 1; i <= maxId; i++) {
      result.push({ id: i, occupied: visible.some((ws: Hyprland.Workspace) => ws.id === i) })
    }
    return result
  })

  return (
    <box cssClasses={["workspaces"]} spacing={2}>
      <For each={items} id={(item) => item.id}>
        {(item) => (
          <button
            cssClasses={createComputed(() => {
              const fw = focusedWs()
              const classes = ["ws-button"]
              if (fw?.id === item.id) classes.push("active")
              else if (item.occupied) classes.push("occupied")
              return classes
            })}
            onClicked={() => hypr.dispatch("workspace", `${item.id}`)}
          >
            <label label={createComputed(() => {
              const fw = focusedWs()
              return fw?.id === item.id ? cfg.activeLabel
                : item.occupied ? cfg.occupiedLabel
                : cfg.label
            })} />
          </button>
        )}
      </For>
    </box>
  )
}
