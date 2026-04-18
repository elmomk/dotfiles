// Config types matching the quickshell shell.json format

export interface ShellConfig {
  appearance: AppearanceConfig
  general: GeneralConfig
  background: BackgroundConfig
  bar: BarConfig
  border: BorderConfig
  dashboard: DashboardConfig
  controlCenter: Record<string, unknown>
  launcher: LauncherConfig
  notifs: NotifsConfig
  osd: OsdConfig
  session: SessionConfig
  winfo: Record<string, unknown>
  lock: LockConfig
  utilities: UtilitiesConfig
  sidebar: SidebarConfig
  claude: ClaudeConfig
  services: ServiceConfig
  paths: UserPaths
}

export interface AppearanceConfig {
  rounding: { scale: number }
  spacing: { scale: number }
  padding: { scale: number }
  font: {
    family: { sans: string; mono: string; material: string; clock: string }
    size: { scale: number }
  }
  anim: {
    mediaGifSpeedAdjustment: number
    sessionGifSpeed: number
    durations: { scale: number }
  }
  transparency: { enabled: boolean; base: number; layers: number }
}

export interface GeneralConfig {
  logo: string
  excludedScreens: string[]
  apps: {
    terminal: string[]
    audio: string[]
    playback: string[]
    explorer: string[]
  }
  idle: {
    lockBeforeSleep: boolean
    inhibitWhenAudio: boolean
    timeouts: Array<{
      timeout: number
      idleAction: string | string[]
      returnAction?: string
    }>
  }
  battery: {
    warnLevels: Array<{
      level: number
      title: string
      message: string
      icon: string
      critical?: boolean
    }>
    criticalLevel: number
  }
}

export interface BackgroundConfig {
  enabled: boolean
  wallpaperEnabled: boolean
  desktopClock: {
    enabled: boolean
    scale: number
    position: string
    invertColors: boolean
    background: { enabled: boolean; opacity: number; blur: number }
    shadow: { enabled: boolean; opacity: number; blur: number }
  }
  visualiser: {
    enabled: boolean
    autoHide: boolean
    blur: number
    rounding: number
    spacing: number
  }
}

export interface BarConfig {
  persistent: boolean
  showOnHover: boolean
  dragThreshold: number
  scrollActions: { workspaces: boolean; volume: boolean; brightness: boolean }
  popouts: { activeWindow: boolean; tray: boolean; statusIcons: boolean }
  workspaces: {
    shown: number
    activeIndicator: boolean
    occupiedBg: boolean
    showWindows: boolean
    showWindowsOnSpecialWorkspaces: boolean
    maxWindowIcons: number
    activeTrail: boolean
    perMonitorWorkspaces: boolean
    label: string
    occupiedLabel: string
    activeLabel: string
    capitalisation: string
    specialWorkspaceIcons: Array<{ name: string; icon: string }>
    windowIcons: Array<{ regex: string; icon: string }>
  }
  activeWindow: { compact: boolean; inverted: boolean; showOnHover: boolean }
  tray: {
    background: boolean
    recolour: boolean
    compact: boolean
    iconSubs: Array<{ from: string; to: string }>
    hiddenIcons: string[]
  }
  status: {
    showAudio: boolean
    showMicrophone: boolean
    showKbLayout: boolean
    showNetwork: boolean
    showWifi: boolean
    showBluetooth: boolean
    showBattery: boolean
    showLockStatus: boolean
  }
  clock: { background: boolean; showDate: boolean; showIcon: boolean }
  sizes: {
    innerWidth: number
    windowPreviewSize: number
    trayMenuWidth: number
    batteryWidth: number
    networkWidth: number
    kbLayoutWidth: number
    claudeWidth: number
  }
  entries: Array<{ id: string; enabled: boolean }>
  excludedScreens: string[]
}

export interface DashboardConfig {
  enabled: boolean
  showOnHover: boolean
  mediaUpdateInterval: number
  resourceUpdateInterval: number
  dragThreshold: number
  showDashboard: boolean
  showMedia: boolean
  showPerformance: boolean
  showWeather: boolean
  performance: {
    showBattery: boolean
    showGpu: boolean
    showCpu: boolean
    showMemory: boolean
    showStorage: boolean
    showNetwork: boolean
  }
}

export interface LauncherConfig {
  enabled: boolean
  showOnHover: boolean
  maxShown: number
  maxWallpapers: number
  specialPrefix: string
  actionPrefix: string
  enableDangerousActions: boolean
  dragThreshold: number
  vimKeybinds: boolean
  favouriteApps: string[]
  hiddenApps: string[]
  useFuzzy: {
    apps: boolean
    actions: boolean
    schemes: boolean
    variants: boolean
    wallpapers: boolean
  }
  sizes: {
    itemWidth: number
    itemHeight: number
    wallpaperWidth: number
    wallpaperHeight: number
  }
  actions: Array<{
    name: string
    icon: string
    description: string
    command: string[]
    enabled: boolean
    dangerous: boolean
  }>
}

export interface NotifsConfig {
  expire: boolean
  fullscreen: string
  defaultExpireTimeout: number
  clearThreshold: number
  expandThreshold: number
  actionOnClick: boolean
  groupPreviewNum: number
  openExpanded: boolean
}

export interface OsdConfig {
  enabled: boolean
  showOnHover: boolean
  hideDelay: number
  enableBrightness: boolean
  enableMicrophone: boolean
}

export interface SessionConfig {
  enabled: boolean
  dragThreshold: number
  vimKeybinds: boolean
  icons: { logout: string; shutdown: string; hibernate: string; reboot: string }
  commands: {
    logout: string[]
    shutdown: string[]
    hibernate: string[]
    reboot: string[]
  }
}

export interface LockConfig {
  recolourLogo: boolean
  enableFprint: boolean
  maxFprintTries: number
  hideNotifs: boolean
}

export interface UtilitiesConfig {
  enabled: boolean
  showOnHover: boolean
  maxToasts: number
  toasts: {
    configLoaded: boolean
    fullscreen: string
    chargingChanged: boolean
    gameModeChanged: boolean
    dndChanged: boolean
    audioOutputChanged: boolean
    audioInputChanged: boolean
    capsLockChanged: boolean
    numLockChanged: boolean
    kbLayoutChanged: boolean
    vpnChanged: boolean
    nowPlaying: boolean
  }
  vpn: {
    enabled: boolean
    provider: Array<{
      displayName: string
      enabled: boolean
      iface: string
      name: string
      connectCmd?: string[]
      disconnectCmd?: string[]
    }>
  }
  quickToggles: Array<{ id: string; enabled: boolean }>
}

export interface SidebarConfig {
  enabled: boolean
  dragThreshold: number
}

export interface ClaudeConfig {
  enabled: boolean
  sizes: { scale: number; width: number }
}

export interface ServiceConfig {
  weatherLocation: string
  useFahrenheit: boolean
  useFahrenheitPerformance: boolean
  useTwelveHourClock: boolean
  gpuType: string
  visualiserBars: number
  audioIncrement: number
  brightnessIncrement: number
  maxVolume: number
  smartScheme: boolean
  defaultPlayer: string
  playerAliases: Array<{ from: string; to: string }>
  showLyrics: boolean
  lyricsBackend: string
}

export interface UserPaths {
  wallpaperDir: string
  lyricsDir: string
  sessionGif: string
  mediaGif: string
}

export const DEFAULT_CONFIG: ShellConfig = {
  appearance: {
    rounding: { scale: 1 },
    spacing: { scale: 1 },
    padding: { scale: 1 },
    font: {
      family: { sans: "Rubik", mono: "CaskaydiaCove NF", material: "Material Symbols Rounded", clock: "Rubik" },
      size: { scale: 1 },
    },
    anim: { mediaGifSpeedAdjustment: 300, sessionGifSpeed: 0.7, durations: { scale: 1 } },
    transparency: { enabled: false, base: 0.85, layers: 0.4 },
  },
  general: {
    logo: "",
    excludedScreens: [],
    apps: { terminal: ["foot"], audio: ["pavucontrol"], playback: ["mpv"], explorer: ["thunar"] },
    idle: {
      lockBeforeSleep: true,
      inhibitWhenAudio: false,
      timeouts: [
        { timeout: 180, idleAction: "lock" },
        { timeout: 300, idleAction: "dpms off", returnAction: "dpms on" },
        { timeout: 600, idleAction: ["systemctl", "suspend-then-hibernate"] },
      ],
    },
    battery: {
      warnLevels: [
        { level: 20, title: "Low battery", message: "You might want to plug in a charger", icon: "battery_android_frame_2" },
        { level: 10, title: "Did you see the previous message?", message: "You should probably plug in a charger now", icon: "battery_android_frame_1" },
        { level: 5, title: "Critical battery level", message: "PLUG THE CHARGER RIGHT NOW!!", icon: "battery_android_alert", critical: true },
      ],
      criticalLevel: 3,
    },
  },
  background: {
    enabled: true,
    wallpaperEnabled: true,
    desktopClock: {
      enabled: false, scale: 1, position: "center", invertColors: false,
      background: { enabled: false, opacity: 0.5, blur: 10 },
      shadow: { enabled: true, opacity: 0.5, blur: 10 },
    },
    visualiser: { enabled: false, autoHide: true, blur: 0, rounding: 0, spacing: 2 },
  },
  bar: {
    persistent: true,
    showOnHover: false,
    dragThreshold: 20,
    scrollActions: { workspaces: true, volume: true, brightness: true },
    popouts: { activeWindow: true, tray: true, statusIcons: true },
    workspaces: {
      shown: 5, activeIndicator: true, occupiedBg: false,
      showWindows: true, showWindowsOnSpecialWorkspaces: true,
      maxWindowIcons: 0, activeTrail: false, perMonitorWorkspaces: true,
      label: "  ", occupiedLabel: "\u{f0baf}", activeLabel: "\u{f0baf}",
      capitalisation: "preserve", specialWorkspaceIcons: [], windowIcons: [],
    },
    activeWindow: { compact: false, inverted: false, showOnHover: false },
    tray: { background: false, recolour: false, compact: false, iconSubs: [], hiddenIcons: [] },
    status: {
      showAudio: false, showMicrophone: false, showKbLayout: false,
      showNetwork: true, showWifi: true, showBluetooth: true,
      showBattery: true, showLockStatus: true,
    },
    clock: { background: false, showDate: false, showIcon: true },
    sizes: {
      innerWidth: 40, windowPreviewSize: 400,
      trayMenuWidth: 300, batteryWidth: 250, networkWidth: 320,
      kbLayoutWidth: 320, claudeWidth: 300,
    },
    entries: [
      { id: "logo", enabled: true },
      { id: "workspaces", enabled: true },
      { id: "spacer", enabled: true },
      { id: "activeWindow", enabled: true },
      { id: "spacer", enabled: true },
      { id: "tray", enabled: true },
      { id: "clock", enabled: true },
      { id: "statusIcons", enabled: true },
      { id: "power", enabled: true },
    ],
    excludedScreens: [],
  },
  border: { thickness: 2, rounding: 12 },
  dashboard: {
    enabled: true, showOnHover: false,
    mediaUpdateInterval: 500, resourceUpdateInterval: 1000,
    dragThreshold: 50, showDashboard: true, showMedia: true,
    showPerformance: true, showWeather: true,
    performance: {
      showBattery: true, showGpu: true, showCpu: true,
      showMemory: true, showStorage: true, showNetwork: true,
    },
  },
  controlCenter: {},
  launcher: {
    enabled: true, showOnHover: false, maxShown: 7, maxWallpapers: 9,
    specialPrefix: "@", actionPrefix: ">",
    enableDangerousActions: false, dragThreshold: 50, vimKeybinds: false,
    favouriteApps: [], hiddenApps: [],
    useFuzzy: { apps: false, actions: false, schemes: false, variants: false, wallpapers: false },
    sizes: { itemWidth: 600, itemHeight: 57, wallpaperWidth: 280, wallpaperHeight: 200 },
    actions: [
      { name: "Calculator", icon: "calculate", description: "Do simple math equations", command: ["autocomplete", "calc"], enabled: true, dangerous: false },
      { name: "Shutdown", icon: "power_settings_new", description: "Shutdown the system", command: ["systemctl", "poweroff"], enabled: true, dangerous: true },
      { name: "Reboot", icon: "cached", description: "Reboot the system", command: ["systemctl", "reboot"], enabled: true, dangerous: true },
      { name: "Lock", icon: "lock", description: "Lock the current session", command: ["loginctl", "lock-session"], enabled: true, dangerous: false },
      { name: "Sleep", icon: "bedtime", description: "Suspend then hibernate", command: ["systemctl", "suspend-then-hibernate"], enabled: true, dangerous: false },
    ],
  },
  notifs: {
    expire: true, fullscreen: "on", defaultExpireTimeout: 5000,
    clearThreshold: 0.3, expandThreshold: 20,
    actionOnClick: false, groupPreviewNum: 3, openExpanded: false,
  },
  osd: { enabled: true, showOnHover: false, hideDelay: 2000, enableBrightness: true, enableMicrophone: false },
  session: {
    enabled: true, dragThreshold: 30, vimKeybinds: false,
    icons: { logout: "logout", shutdown: "power_settings_new", hibernate: "downloading", reboot: "cached" },
    commands: {
      logout: ["loginctl", "terminate-user", ""],
      shutdown: ["systemctl", "poweroff"],
      hibernate: ["systemctl", "hibernate"],
      reboot: ["systemctl", "reboot"],
    },
  },
  winfo: {},
  lock: { recolourLogo: false, enableFprint: false, maxFprintTries: 3, hideNotifs: false },
  utilities: {
    enabled: true, showOnHover: false, maxToasts: 4,
    toasts: {
      configLoaded: true, fullscreen: "off", chargingChanged: true,
      gameModeChanged: true, dndChanged: true,
      audioOutputChanged: true, audioInputChanged: true,
      capsLockChanged: true, numLockChanged: true,
      kbLayoutChanged: true, vpnChanged: true, nowPlaying: false,
    },
    vpn: { enabled: false, provider: [] },
    quickToggles: [
      { id: "wifi", enabled: true },
      { id: "bluetooth", enabled: true },
      { id: "mic", enabled: true },
      { id: "settings", enabled: true },
      { id: "gameMode", enabled: true },
      { id: "dnd", enabled: true },
    ],
  },
  sidebar: { enabled: true, dragThreshold: 20 },
  claude: { enabled: false, sizes: { scale: 1, width: 400 } },
  services: {
    weatherLocation: "", useFahrenheit: false, useFahrenheitPerformance: false,
    useTwelveHourClock: false, gpuType: "", visualiserBars: 45,
    audioIncrement: 0.1, brightnessIncrement: 0.1, maxVolume: 1.0,
    smartScheme: true, defaultPlayer: "Spotify",
    playerAliases: [], showLyrics: false, lyricsBackend: "Auto",
  },
  paths: { wallpaperDir: "", lyricsDir: "", sessionGif: "", mediaGif: "" },
}
