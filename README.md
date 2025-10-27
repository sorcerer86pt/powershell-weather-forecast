# PowerShell Weather Forecast

[![Release](https://img.shields.io/github/v/release/sorcerer86pt/powershell-weather-forecast?label=Version&logo=github)](https://github.com/sorcerer86pt/powershell-weather-forecast/releases)
[![License](https://img.shields.io/github/license/sorcerer86pt/powershell-weather-forecast)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com/sorcerer86pt/powershell-weather-forecast)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue?logo=powershell)](https://github.com/PowerShell/PowerShell)

A modern, feature-rich **cross-platform** PowerShell script that displays a 7-day weather forecast with automatic location detection and multi-language support.

## Features

- ✅ **Cross-Platform** - Works on Windows, Linux, and macOS
- ✅ **Smart Location Detection** - Automatically detects OS and uses the appropriate location service
  - Windows: Windows Location Service
  - Linux: GeoClue2
  - macOS: CoreLocation (via whereami)
  - All: IP-based geolocation fallback
- ✅ **Multi-Language Support** - Extensible locale system with 7 languages included
- ✅ **Comprehensive Weather Data** - Temperature, precipitation, wind speed, and weather conditions
- ✅ **Multiple Temperature Units** - Celsius or Fahrenheit
- ✅ **Beautiful Console UI** - Clean, formatted output with weather emojis
- ✅ **Free APIs** - Uses Open-Meteo (no API key required) and OpenStreetMap Nominatim
- ✅ **Rate Limiting** - Respects API usage policies automatically
- ✅ **Fallback Support** - Built-in English descriptions if locale files are missing

## Requirements

### All Platforms
- PowerShell 7+ (recommended) or PowerShell 5.1+ (Windows only)
- Internet connection

### Platform-Specific (Optional, for automatic location detection)

**Windows:**
- Windows 10/11 with Location Services enabled

**Linux:**
- GeoClue2 installed and running
- Install: `sudo apt install geoclue-2.0` (Debian/Ubuntu) or `sudo dnf install geoclue2` (Fedora)

**macOS:**
- whereami utility (optional but recommended)
- Install: `brew install whereami`

## Installation

### Windows

1. **Install PowerShell** (if not already installed):
   - Windows 10/11 comes with PowerShell 5.1
   - For PowerShell 7+: Download from [GitHub](https://github.com/PowerShell/PowerShell/releases)

2. **Clone or download the repository:**
```powershell
git clone https://github.com/yourusername/powershell-weather-forecast.git
cd powershell-weather-forecast
```

3. **Enable Location Services (optional):**
   - Go to Settings → Privacy → Location
   - Turn on "Location for this device"

4. **Run the script:**
```powershell
.\WeatherForecast.ps1
```

### Linux

1. **Install PowerShell:**

   **Debian/Ubuntu:**
   ```bash
   # Install prerequisites
   sudo apt-get update
   sudo apt-get install -y wget apt-transport-https software-properties-common
   
   # Download and install PowerShell
   wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt-get update
   sudo apt-get install -y powershell
   ```

   **Fedora:**
   ```bash
   # Add Microsoft repository
   sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
   sudo curl -o /etc/yum.repos.d/microsoft.repo https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/prod.repo
   
   # Install PowerShell
   sudo dnf install -y powershell
   ```

   **Arch Linux:**
   ```bash
   yay -S powershell-bin
   # or
   paru -S powershell-bin
   ```

2. **Install GeoClue2 (optional, for location detection):**

   **Debian/Ubuntu:**
   ```bash
   sudo apt install geoclue-2.0
   ```

   **Fedora:**
   ```bash
   sudo dnf install geoclue2
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -S geoclue
   ```

3. **Clone or download the repository:**
```bash
git clone https://github.com/yourusername/powershell-weather-forecast.git
cd powershell-weather-forecast
```

4. **Make the script executable (optional):**
```bash
chmod +x WeatherForecast.ps1
```

5. **Run the script:**
```bash
pwsh ./WeatherForecast.ps1
```

### macOS

1. **Install Homebrew** (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **Install PowerShell:**
```bash
brew install powershell/tap/powershell
```

3. **Install whereami (optional, for location detection):**
```bash
brew install whereami
```

4. **Clone or download the repository:**
```bash
git clone https://github.com/yourusername/powershell-weather-forecast.git
cd powershell-weather-forecast
```

5. **Run the script:**
```bash
pwsh ./WeatherForecast.ps1
```

### Quick Start (Any Platform)

If you just want to try it without location services:
```bash
# Skip system location and use IP-based detection
pwsh ./WeatherForecast.ps1 -SkipSystemLocation

# Or specify a city directly
pwsh ./WeatherForecast.ps1 -City "London"
```

## Usage

### Basic Usage
```powershell
# Auto-detect location and show forecast
.\WeatherForecast.ps1
```

### Advanced Usage
```powershell
# Specific city
.\WeatherForecast.ps1 -City "Tokyo"

# Use Fahrenheit
.\WeatherForecast.ps1 -Units Fahrenheit

# Force specific language
.\WeatherForecast.ps1 -LocaleOverride "pt"

# Skip system location (go directly to IP lookup)
.\WeatherForecast.ps1 -SkipSystemLocation

# Combine parameters
.\WeatherForecast.ps1 -City "New York" -Units Fahrenheit -LocaleOverride "es"
```

### Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-City` | String | Specify city name directly | None (auto-detect) |
| `-Units` | String | Temperature units: `Celsius` or `Fahrenheit` | `Celsius` |
| `-SkipSystemLocation` | Switch | Skip Windows Location Service, use IP instead | False |
| `-LocaleOverride` | String | Force specific language (e.g., `en`, `pt`, `fr`) | System language |

## Supported Languages

- 🇬🇧 English (`en`)
- 🇵🇹 Portuguese (`pt`)
- 🇫🇷 French (`fr`)
- 🇪🇸 Spanish (`es`)
- 🇩🇪 German (`de`)
- 🇮🇹 Italian (`it`)
- 🇯🇵 Japanese (`ja`)

Want to add more? See [locales/README.md](locales/README.md)

## Location Detection Strategy

The script automatically detects your OS and uses a tiered approach to find your location:

### Windows
1. **Windows Location Service** - Most accurate, requires permission
2. **IP Geolocation** - Fallback using ip-api.com (city-level accuracy)
3. **Manual Entry** - Prompts for city name if automatic methods fail

### Linux
1. **GeoClue2** - Uses the Linux standard geolocation service
2. **IP Geolocation** - Fallback using ip-api.com (city-level accuracy)
3. **Manual Entry** - Prompts for city name if automatic methods fail

### macOS
1. **CoreLocation via whereami** - Uses macOS location services
2. **IP Geolocation** - Fallback using ip-api.com (city-level accuracy)
3. **Manual Entry** - Prompts for city name if automatic methods fail

## APIs Used

- **[Open-Meteo](https://open-meteo.com/)** - Free weather forecast API (no key required)
- **[OpenStreetMap Nominatim](https://nominatim.openstreetmap.org/)** - Reverse geocoding for coordinates to city names
- **[Open-Meteo Geocoding](https://geocoding-api.open-meteo.com/)** - City name to coordinates
- **[IP-API](https://ip-api.com/)** - IP-based geolocation

## Example Output

```
╔═══════════════════════════════════════════════════╗
║     Weather Forecast - 7 Day Outlook              ║
╚═══════════════════════════════════════════════════╝

✓ Location: Porto, Portugal

Fetching 7-day weather forecast for Porto...

╔═══════════════════════════════════════════════════════════════════════════╗
║  7-Day Weather Forecast for Porto, Portugal                              ║
╚═══════════════════════════════════════════════════════════════════════════╝

Date         Icon Weather      High  Low  Rain           Wind   
----         ---- -------      ----  ---  ----           ----   
Mon 27/10    ☀️   Clear        22°C  15°C -              12 km/h
Tue 28/10    🌤️   M.Clear      21°C  14°C -              15 km/h
Wed 29/10    ⛅   P.Cloudy     19°C  13°C 2.5mm (60%)    18 km/h
Thu 30/10    ☔   Rain         17°C  12°C 8.2mm (85%)    22 km/h

────────────────────────────────────────────────────────────────────────────
Weather data: Open-Meteo API | Location: OpenStreetMap Nominatim
Language: English (en)
Last updated: 2025-10-27 14:23:45
```

## Contributing

Contributions are welcome! This project uses **automatic semantic versioning** based on [Conventional Commits](https://www.conventionalcommits.org/).

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Make your changes
4. Commit using conventional commit format (see below)
5. Push to your fork and create a Pull Request

### Commit Message Format

Use conventional commits for automatic versioning:

- `feat:` - New feature (bumps **minor** version: 1.0.0 → 1.1.0)
- `fix:` - Bug fix (bumps **patch** version: 1.0.0 → 1.0.1)
- `docs:` - Documentation changes
- `perf:` - Performance improvements
- `refactor:` - Code refactoring
- `BREAKING CHANGE:` - Breaking changes (bumps **major** version: 1.0.0 → 2.0.0)

**Examples:**
```bash
feat: add support for hourly forecasts
fix: resolve location detection on WSL
docs: update installation instructions
feat!: redesign command line parameters

BREAKING CHANGE: Parameter names have changed
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Ways to Contribute

- 🌍 Adding new language translations (see [locales/README.md](locales/README.md))
- 🐛 Reporting bugs or suggesting features
- 📚 Improving the code or documentation
- ✅ Adding tests and improving cross-platform support

## License

This project is open source and available under the MIT License.

## Credits

- Weather data provided by [Open-Meteo](https://open-meteo.com/)
- Geocoding by [OpenStreetMap Nominatim](https://nominatim.openstreetmap.org/)
- Weather icons using Unicode emoji characters

## Troubleshooting

### Location service not working

**Windows:**
- Ensure Windows Location Services are enabled: Settings → Privacy → Location
- Try using `-SkipSystemLocation` to use IP-based location instead

**Linux:**
- Ensure GeoClue2 is installed: `sudo apt install geoclue-2.0` or `sudo dnf install geoclue2`
- Check if GeoClue2 service is running: `systemctl status geoclue`
- Try using `-SkipSystemLocation` to use IP-based location instead

**macOS:**
- Install whereami: `brew install whereami`
- Grant location permissions when prompted
- Try using `-SkipSystemLocation` to use IP-based location instead

### Locale not loading
- Check that locale files exist in the `locales/` subdirectory
- Verify JSON files are valid and UTF-8 encoded
- Script falls back to built-in English if locale files are missing

### API rate limits
- The script automatically rate-limits Nominatim requests (1/second)
- If you encounter issues, wait a few minutes before trying again

### PowerShell version
- For best cross-platform compatibility, use PowerShell 7+
- Install from: https://github.com/PowerShell/PowerShell#get-powershell

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

This project follows [Semantic Versioning](https://semver.org/):
- **Major** version (X.0.0): Breaking changes
- **Minor** version (0.X.0): New features, backwards compatible
- **Patch** version (0.0.X): Bug fixes and improvements

