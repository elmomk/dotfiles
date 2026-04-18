import { createState } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { clock, date } from "../../lib/variables"
import { onKeyPress } from "../../lib/utils"

const [password, setPassword] = createState("")
const [message, setMessage] = createState("")
const [messageErr, setMessageErr] = createState(false)

function tryUnlock() {
  const pw = password.peek()
  if (!pw) return

  setMessage("Checking...")
  setMessageErr(false)
  setPassword("")

  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
    setMessage("PAM auth not yet implemented")
    setMessageErr(true)
    return GLib.SOURCE_REMOVE
  })
}

export default function Lock(gdkmonitor: Gdk.Monitor) {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="lock"
      cssClasses={["Lock"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={app}
      $={(self: Astal.Window) => onKeyPress(self, (keyval) => {
        if (keyval === Gdk.KEY_Return) { tryUnlock(); return true }
        return false
      })}
    >
      <box cssClasses={["lock-inner"]} orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} spacing={8}>
        <label cssClasses={["lock-clock"]} label={clock} />
        <label cssClasses={["lock-date"]} label={date} />
        <box cssClasses={["lock-input"]}>
          <label cssClasses={["lock-icon"]} label="lock" />
          <entry
            hexpand
            placeholderText="Password"
            visibility={false}
            text={password}
            onChanged={(self: Gtk.Entry) => setPassword(self.text)}
          />
        </box>
        <label cssClasses={messageErr.as(e => e ? ["lock-message", "error"] : ["lock-message"])} label={message} />
      </box>
    </window>
  )
}
