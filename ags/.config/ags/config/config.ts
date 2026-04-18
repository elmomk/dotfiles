import GLib from "gi://GLib"
import Gio from "gi://Gio"
import { ShellConfig, DEFAULT_CONFIG } from "./types"

const CONFIG_DIR = GLib.get_user_config_dir()
const CONFIG_PATH = `${CONFIG_DIR}/ags/shell.json`

function deepMerge<T>(defaults: T, overrides: Partial<T>): T {
  const result = { ...defaults } as Record<string, unknown>
  for (const key of Object.keys(overrides as Record<string, unknown>)) {
    const val = (overrides as Record<string, unknown>)[key]
    const def = (defaults as Record<string, unknown>)[key]
    if (val && typeof val === "object" && !Array.isArray(val) && def && typeof def === "object" && !Array.isArray(def)) {
      result[key] = deepMerge(def, val as Record<string, unknown>)
    } else if (val !== undefined) {
      result[key] = val
    }
  }
  return result as T
}

function readConfig(): ShellConfig {
  try {
    const file = Gio.File.new_for_path(CONFIG_PATH)
    const [ok, contents] = file.load_contents(null)
    if (ok) {
      const text = new TextDecoder().decode(contents)
      const parsed = JSON.parse(text)
      return deepMerge(DEFAULT_CONFIG, parsed)
    }
  } catch {
    // Config file doesn't exist or is invalid — use defaults
  }
  return { ...DEFAULT_CONFIG }
}

function writeConfig(config: ShellConfig): void {
  try {
    const file = Gio.File.new_for_path(CONFIG_PATH)
    const parent = file.get_parent()
    if (parent && !parent.query_exists(null)) {
      parent.make_directory_with_parents(null)
    }
    file.replace_contents(
      new TextEncoder().encode(JSON.stringify(config, null, 2)),
      null, false,
      Gio.FileCreateFlags.REPLACE_DESTINATION,
      null,
    )
  } catch (e) {
    console.error("Failed to write config:", e)
  }
}

class ConfigManager {
  private _config: ShellConfig
  private _saveTimeoutId: number | null = null
  private _monitor: Gio.FileMonitor | null = null
  private _recentlySaved = false

  constructor() {
    this._config = readConfig()
    this._watchFile()
  }

  get config(): ShellConfig {
    return this._config
  }

  get<K extends keyof ShellConfig>(section: K): ShellConfig[K] {
    return this._config[section]
  }

  update<K extends keyof ShellConfig>(section: K, value: Partial<ShellConfig[K]>): void {
    this._config[section] = deepMerge(this._config[section], value) as ShellConfig[K]
    this._scheduleSave()
  }

  save(): void {
    this._scheduleSave()
  }

  private _scheduleSave(): void {
    if (this._saveTimeoutId !== null) {
      GLib.source_remove(this._saveTimeoutId)
    }
    this._saveTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
      this._recentlySaved = true
      writeConfig(this._config)
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
        this._recentlySaved = false
        return GLib.SOURCE_REMOVE
      })
      this._saveTimeoutId = null
      return GLib.SOURCE_REMOVE
    })
  }

  private _watchFile(): void {
    try {
      const file = Gio.File.new_for_path(CONFIG_PATH)
      this._monitor = file.monitor_file(Gio.FileMonitorFlags.NONE, null)
      this._monitor.connect("changed", (_monitor: Gio.FileMonitor, _file: Gio.File, _otherFile: Gio.File | null, eventType: Gio.FileMonitorEvent) => {
        if (eventType === Gio.FileMonitorEvent.CHANGES_DONE_HINT && !this._recentlySaved) {
          this._config = readConfig()
          console.log("Config reloaded from disk")
        }
      })
    } catch (e) {
      console.error("Failed to watch config file:", e)
    }
  }
}

const config = new ConfigManager()
export default config
export const cfg = config.config
