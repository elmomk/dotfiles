import { createState } from "ags"
import { exec } from "ags/process"
import GLib from "gi://GLib"
import config from "../config/config"

export interface SystemUsage {
  cpuPercent: number
  memPercent: number
  memUsedGb: number
  memTotalGb: number
  storagePercent: number
  storageUsedGb: number
  storageTotalGb: number
  gpuPercent: number
  gpuTempC: number
  cpuTempC: number
}

const [usage, setUsage] = createState<SystemUsage>({
  cpuPercent: 0, memPercent: 0, memUsedGb: 0, memTotalGb: 0,
  storagePercent: 0, storageUsedGb: 0, storageTotalGb: 0,
  gpuPercent: 0, gpuTempC: 0, cpuTempC: 0,
})

function readCpu(): number {
  try {
    const out = exec(["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"])
    return parseFloat(out) || 0
  } catch { return 0 }
}

function readMem(): { percent: number; usedGb: number; totalGb: number } {
  try {
    const out = exec(["bash", "-c", "free -b | awk '/Mem:/ {printf \"%f %f %f\", $3/$2*100, $3/1073741824, $2/1073741824}'"])
    const [pct, used, total] = out.split(" ").map(parseFloat)
    return { percent: pct || 0, usedGb: used || 0, totalGb: total || 0 }
  } catch { return { percent: 0, usedGb: 0, totalGb: 0 } }
}

function readStorage(): { percent: number; usedGb: number; totalGb: number } {
  try {
    const out = exec(["bash", "-c", "df / | awk 'NR==2 {printf \"%d %f %f\", $5, $3/1048576, $2/1048576}'"])
    const [pct, used, total] = out.split(" ").map(parseFloat)
    return { percent: pct || 0, usedGb: used || 0, totalGb: total || 0 }
  } catch { return { percent: 0, usedGb: 0, totalGb: 0 } }
}

function readGpu(): { percent: number; tempC: number } {
  const gpuType = config.config.services.gpuType
  if (gpuType === "nvidia" || !gpuType) {
    try {
      const out = exec(["bash", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null"])
      if (out) {
        const [pct, temp] = out.split(",").map(s => parseFloat(s.trim()))
        return { percent: pct || 0, tempC: temp || 0 }
      }
    } catch { /* not nvidia */ }
  }
  return { percent: 0, tempC: 0 }
}

function readCpuTemp(): number {
  try {
    const out = exec(["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null"])
    return Math.round(parseInt(out) / 1000) || 0
  } catch { return 0 }
}

function poll() {
  const cpu = readCpu()
  const mem = readMem()
  const storage = readStorage()
  const gpu = readGpu()
  const cpuTemp = readCpuTemp()

  setUsage({
    cpuPercent: cpu,
    memPercent: mem.percent,
    memUsedGb: mem.usedGb,
    memTotalGb: mem.totalGb,
    storagePercent: storage.percent,
    storageUsedGb: storage.usedGb,
    storageTotalGb: storage.totalGb,
    gpuPercent: gpu.percent,
    gpuTempC: gpu.tempC,
    cpuTempC: cpuTemp,
  })
}

const interval = config.config.dashboard.resourceUpdateInterval || 2000
poll()
GLib.timeout_add(GLib.PRIORITY_DEFAULT, interval, () => {
  poll()
  return GLib.SOURCE_CONTINUE
})

export { usage }
