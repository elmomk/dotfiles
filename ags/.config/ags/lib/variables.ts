import { createPoll } from "ags/time"
import { formatTime, formatDate } from "./utils"
import config from "../config/config"

export const clock = createPoll("", 1000, () => {
  const now = new Date()
  return formatTime(now, config.config.services.useTwelveHourClock)
})

export const date = createPoll("", 60_000, () => formatDate(new Date()))

export const uptime = createPoll("", 60_000, "cat /proc/uptime", (out: string) => {
  const seconds = Math.floor(parseFloat(out.split(" ")[0]))
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
})
