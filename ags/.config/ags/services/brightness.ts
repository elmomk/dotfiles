import { createState, type Accessor, type Setter } from "ags"
import { exec, execAsync } from "ags/process"
import GLib from "gi://GLib"

const [brightness, setBrightness] = createState(getBrightness())

function getBrightness(): number {
  try {
    const out = exec("brightnessctl get")
    const max = exec("brightnessctl max")
    return parseInt(out) / parseInt(max)
  } catch {
    return 1
  }
}

function setBrightnessLevel(value: number) {
  const clamped = Math.max(0, Math.min(1, value))
  const percent = Math.round(clamped * 100)
  execAsync(`brightnessctl set ${percent}%`).then(() => {
    setBrightness(clamped)
  }).catch(e => console.error("brightnessctl failed:", e))
}

export function incrementBrightness(amount = 0.1) {
  setBrightnessLevel(brightness.peek() + amount)
}

export function decrementBrightness(amount = 0.1) {
  setBrightnessLevel(brightness.peek() - amount)
}

export { brightness }
