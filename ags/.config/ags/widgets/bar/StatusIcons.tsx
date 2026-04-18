import { createBinding } from "ags"
import Network from "gi://AstalNetwork"
import Wp from "gi://AstalWp"
import Bluetooth from "gi://AstalBluetooth"
import Battery from "gi://AstalBattery"
import config from "../../config/config"

function AudioIcon() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!
  const muted = createBinding(speaker, "mute")
  const volume = createBinding(speaker, "volume")

  return (
    <label
      cssClasses={muted.as(m => m ? ["icon", "status-icon", "error"] : ["icon", "status-icon"])}
      label={volume.as(v => {
        if (speaker.mute) return "volume_off"
        if (v > 0.66) return "volume_up"
        if (v > 0.33) return "volume_down"
        if (v > 0) return "volume_mute"
        return "volume_off"
      })}
      tooltipText={volume.as(v => `Volume: ${Math.round(v * 100)}%`)}
    />
  )
}

function MicIcon() {
  const wp = Wp.get_default()!
  const mic = wp.audio.defaultMicrophone!
  const muted = createBinding(mic, "mute")
  const volume = createBinding(mic, "volume")

  return (
    <label
      cssClasses={muted.as(m => m ? ["icon", "status-icon", "error"] : ["icon", "status-icon"])}
      label={muted.as(m => m ? "mic_off" : "mic")}
      tooltipText={volume.as(v => `Microphone: ${Math.round(v * 100)}%`)}
    />
  )
}

function NetworkIcon() {
  const net = Network.get_default()
  const primary = createBinding(net, "primary")

  return (
    <label
      cssClasses={["icon", "status-icon"]}
      label={primary.as(p => {
        if (p === Network.Primary.WIFI) {
          const wifi = net.wifi
          if (!wifi) return "wifi_off"
          const strength = wifi.strength
          if (strength > 75) return "signal_wifi_4_bar"
          if (strength > 50) return "network_wifi_3_bar"
          if (strength > 25) return "network_wifi_2_bar"
          return "network_wifi_1_bar"
        }
        if (p === Network.Primary.WIRED) return "lan"
        return "wifi_off"
      })}
      tooltipText={primary.as(p => {
        if (p === Network.Primary.WIFI && net.wifi)
          return `WiFi: ${net.wifi.ssid ?? "Connected"}`
        if (p === Network.Primary.WIRED) return "Ethernet"
        return "Disconnected"
      })}
    />
  )
}

function BluetoothIcon() {
  const bt = Bluetooth.get_default()
  const powered = createBinding(bt, "isPowered")

  return (
    <label
      cssClasses={powered.as(p => p ? ["icon", "status-icon", "active"] : ["icon", "status-icon"])}
      label={powered.as(p => p ? "bluetooth" : "bluetooth_disabled")}
      tooltipText={powered.as(p => p ? "Bluetooth On" : "Bluetooth Off")}
    />
  )
}

function BatteryIcon() {
  const bat = Battery.get_default()
  const pct = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")

  return (
    <label
      cssClasses={pct.as((p: number) =>
        p <= 0.15 ? ["icon", "status-icon", "error"] :
        p <= 0.3 ? ["icon", "status-icon", "warning"] :
        ["icon", "status-icon"]
      )}
      label={pct.as(p => {
        if (bat.charging) return "battery_charging_full"
        if (p > 0.9) return "battery_full"
        if (p > 0.6) return "battery_5_bar"
        if (p > 0.4) return "battery_3_bar"
        if (p > 0.15) return "battery_2_bar"
        return "battery_alert"
      })}
      tooltipText={pct.as(p =>
        `Battery: ${Math.round(p * 100)}%${bat.charging ? " (Charging)" : ""}`
      )}
    />
  )
}

export default function StatusIcons() {
  const cfg = config.config.bar.status

  return (
    <box cssClasses={["status-icons"]} spacing={2}>
      {cfg.showAudio && <AudioIcon />}
      {cfg.showMicrophone && <MicIcon />}
      {cfg.showNetwork && <NetworkIcon />}
      {cfg.showBluetooth && <BluetoothIcon />}
      {cfg.showBattery && <BatteryIcon />}
    </box>
  )
}
