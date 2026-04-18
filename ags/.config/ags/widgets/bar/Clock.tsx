import { clock, date } from "../../lib/variables"
import config from "../../config/config"

export default function Clock() {
  const cfg = config.config.bar.clock

  return (
    <box cssClasses={["clock"]} spacing={4}>
      {cfg.showIcon && <label cssClasses={["icon", "clock-icon"]} label="schedule" />}
      <label cssClasses={["clock-time"]} label={clock} />
      {cfg.showDate && <label cssClasses={["clock-date"]} label={date} />}
    </box>
  )
}
