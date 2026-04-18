import { createBinding } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function ActiveWindow() {
  const hypr = Hyprland.get_default()
  const client = createBinding(hypr, "focusedClient")

  return (
    <box cssClasses={["active-window"]}>
      <label
        label={client.as(c => c?.title ?? "")}
        maxWidthChars={40}
        ellipsize={3}
      />
    </box>
  )
}
