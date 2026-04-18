import { Gtk } from "ags/gtk4"
import Notifd from "gi://AstalNotifd"

interface NotifProps {
  notification: Notifd.Notification
  onDismiss?: () => void
}

function formatTime(timestamp: number): string {
  const d = new Date(timestamp * 1000)
  const h = d.getHours().toString().padStart(2, "0")
  const m = d.getMinutes().toString().padStart(2, "0")
  return `${h}:${m}`
}

export default function Notification({ notification: n, onDismiss }: NotifProps) {
  return (
    <box cssClasses={n.urgency === Notifd.Urgency.CRITICAL ? ["notification", "critical"] : ["notification"]} orientation={Gtk.Orientation.VERTICAL}>
      {/* Header */}
      <box cssClasses={["notif-header"]}>
        <label cssClasses={["notif-app-name"]} label={n.appName || "Unknown"} hexpand halign={Gtk.Align.START} />
        <label cssClasses={["notif-time"]} label={formatTime(n.time)} />
        <button cssClasses={["notif-close"]} onClicked={() => {
          n.dismiss()
          onDismiss?.()
        }}>
          <label label="close" />
        </button>
      </box>

      {/* Body */}
      <box cssClasses={["notif-body"]} spacing={8}>
        {n.image && (
          <box cssClasses={["notif-image"]}>
            <image file={n.image} />
          </box>
        )}
        <box orientation={Gtk.Orientation.VERTICAL} hexpand>
          <label cssClasses={["notif-summary"]} label={n.summary} halign={Gtk.Align.START} maxWidthChars={40} ellipsize={3} />
          {n.body && (
            <label cssClasses={["notif-text"]} label={n.body} halign={Gtk.Align.START} wrap maxWidthChars={40} />
          )}
        </box>
      </box>

      {/* Actions */}
      {n.get_actions().length > 0 && (
        <box cssClasses={["notif-actions"]} spacing={4}>
          {n.get_actions().map((action: Notifd.Action) => (
            <button
              cssClasses={["notif-action"]}
              onClicked={() => n.invoke(action.id)}
            >
              <label label={action.label} />
            </button>
          ))}
        </box>
      )}
    </box>
  )
}
