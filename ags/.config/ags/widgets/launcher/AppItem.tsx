import { Gtk } from "ags/gtk4"
import Apps from "gi://AstalApps"

interface AppItemProps {
  app: Apps.Application
  selected: boolean
}

export default function AppItem({ app: a, selected }: AppItemProps) {
  return (
    <button cssClasses={selected ? ["app-item", "selected"] : ["app-item"]} onClicked={() => a.launch()}>
      <box spacing={12}>
        <image cssClasses={["app-icon"]} iconName={a.iconName ?? "application-x-executable"} />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
          <label cssClasses={["app-name"]} label={a.name} halign={Gtk.Align.START} ellipsize={3} />
          {a.description && (
            <label cssClasses={["app-description"]} label={a.description} halign={Gtk.Align.START} ellipsize={3} />
          )}
        </box>
      </box>
    </button>
  )
}
