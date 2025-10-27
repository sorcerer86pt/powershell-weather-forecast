## [1.0.1](https://github.com/sorcerer86pt/powershell-weather-forecast/compare/v1.0.0...v1.0.1) (2025-10-27)


### 🐛 Bug Fixes

* add missed supported language ukrainian ([1a3d241](https://github.com/sorcerer86pt/powershell-weather-forecast/commit/1a3d2410ff61ffa473982ccb2098ad0299885206))

## 1.0.0 (2025-10-27)


### ✨ Features

* Added Ukrainian language ([8aa4d6e](https://github.com/sorcerer86pt/powershell-weather-forecast/commit/8aa4d6e4040a9ba2b9632a06b3265983d50bd237))

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Automatic semantic versioning with GitHub Actions
- Contributing guidelines with conventional commit format
- Pull request template
- .gitattributes for consistent line endings across platforms

### Fixed
- Line endings converted to LF for Linux/macOS compatibility

## [1.0.0] - 2025-10-27

### Added
- 7-day weather forecast display
- Cross-platform support (Windows, Linux, macOS)
- Automatic location detection with OS-specific services
  - Windows Location Service
  - Linux GeoClue2
  - macOS CoreLocation (via whereami)
- IP-based geolocation fallback
- Manual city name input
- Multi-language support with 7 languages (en, pt, fr, es, de, it, ja)
- Temperature unit selection (Celsius/Fahrenheit)
- Beautiful console UI with weather emojis and formatted tables
- Rate limiting for Nominatim API (respects 1 request/second)
- Comprehensive error handling and fallback mechanisms
- Locale system with extensible JSON files

### APIs Used
- Open-Meteo for weather data
- OpenStreetMap Nominatim for geocoding
- IP-API for IP-based location
