import { createBinding, For } from "ags"
import Tray from "gi://AstalTray"

export default function SysTray() {
  const tray = Tray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box cssClasses={["tray"]} spacing={4}>
      <For each={items}>
        {(item: Tray.TrayItem) => (
          <menubutton
            cssClasses={["tray-item"]}
            tooltipMarkup={createBinding(item, "tooltipMarkup")}
            menuModel={createBinding(item, "menuModel")}
            $={(self: any) => {
              const ag = createBinding(item, "actionGroup")
              ag.subscribe(() => {
                const group = ag.peek()
                if (group) self.insert_action_group("dbusmenu", group)
              })
              const group = ag.peek()
              if (group) self.insert_action_group("dbusmenu", group)
            }}
          >
            <image gicon={createBinding(item, "gicon")} />
          </menubutton>
        )}
      </For>
    </box>
  )
}
