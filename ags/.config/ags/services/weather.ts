import { createState } from "ags"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import config from "../config/config"

export interface WeatherData {
  temp: number
  feelsLike: number
  description: string
  icon: string
  humidity: number
  windSpeed: number
  location: string
}

const [weather, setWeather] = createState<WeatherData | null>(null)

function weatherCodeToIcon(code: number): string {
  if (code === 0) return "clear_day"
  if (code <= 3) return "partly_cloudy_day"
  if (code <= 48) return "foggy"
  if (code <= 57) return "rainy"
  if (code <= 67) return "rainy"
  if (code <= 77) return "weather_snowy"
  if (code <= 82) return "rainy"
  if (code <= 86) return "weather_snowy"
  if (code <= 99) return "thunderstorm"
  return "cloud"
}

function weatherCodeToDesc(code: number): string {
  if (code === 0) return "Clear sky"
  if (code <= 3) return "Partly cloudy"
  if (code <= 48) return "Foggy"
  if (code <= 57) return "Drizzle"
  if (code <= 67) return "Rain"
  if (code <= 77) return "Snow"
  if (code <= 82) return "Rain showers"
  if (code <= 86) return "Snow showers"
  if (code <= 99) return "Thunderstorm"
  return "Unknown"
}

async function fetchWeather() {
  try {
    const cfg = config.config.services
    let url = "https://api.open-meteo.com/v1/forecast?current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=auto"

    if (cfg.weatherLocation) {
      const [lat, lon] = cfg.weatherLocation.split(",")
      url += `&latitude=${lat.trim()}&longitude=${lon.trim()}`
    } else {
      // Auto-detect via IP geolocation
      const geoProc = Gio.Subprocess.new(
        ["curl", "-sf", "https://ipapi.co/json/"],
        Gio.SubprocessFlags.STDOUT_PIPE,
      )
      const [, geoOut] = geoProc.communicate_utf8(null, null)
      if (geoOut) {
        const geo = JSON.parse(geoOut)
        url += `&latitude=${geo.latitude}&longitude=${geo.longitude}`
      }
    }

    const proc = Gio.Subprocess.new(
      ["curl", "-sf", url],
      Gio.SubprocessFlags.STDOUT_PIPE,
    )
    const [, stdout] = proc.communicate_utf8(null, null)
    if (!stdout) return

    const data = JSON.parse(stdout)
    const current = data.current

    let temp = current.temperature_2m
    let feelsLike = current.apparent_temperature
    if (cfg.useFahrenheit) {
      temp = temp * 9 / 5 + 32
      feelsLike = feelsLike * 9 / 5 + 32
    }

    setWeather({
      temp: Math.round(temp),
      feelsLike: Math.round(feelsLike),
      description: weatherCodeToDesc(current.weather_code),
      icon: weatherCodeToIcon(current.weather_code),
      humidity: current.relative_humidity_2m,
      windSpeed: Math.round(current.wind_speed_10m),
      location: data.timezone?.split("/").pop()?.replace("_", " ") ?? "",
    })
  } catch (e) {
    console.error("Weather fetch failed:", e)
  }
}

// Fetch on start and every 15 minutes
fetchWeather()
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 15 * 60 * 1000, () => {
  fetchWeather()
  return GLib.SOURCE_CONTINUE
})

export { weather }
