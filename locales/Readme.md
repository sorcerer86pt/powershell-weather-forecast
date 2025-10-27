# Weather Forecast Locales

This directory contains locale files for weather descriptions in different languages.

## File Format

Each locale file should be a JSON file named with the two-letter ISO language code (e.g., `en.json`, `pt.json`, `fr.json`).

### Structure

```json
{
  "language": "en",
  "language_name": "English",
  "unknown_text": "Unknown",
  "weather_codes": {
    "0": "Clear",
    "1": "M.Clear",
    ...
  }
}
```

### Fields

- **language**: Two-letter ISO 639-1 language code (lowercase)
- **language_name**: Full name of the language in its native form
- **unknown_text**: Text to display when a weather code is not recognized
- **weather_codes**: Object mapping WMO weather codes to descriptions

## WMO Weather Codes

The following weather codes are used by Open-Meteo API:

| Code | Condition |
|------|-----------|
| 0 | Clear sky |
| 1 | Mainly clear |
| 2 | Partly cloudy |
| 3 | Overcast |
| 45, 48 | Fog |
| 51, 53, 55 | Drizzle (light, moderate, dense) |
| 56, 57 | Freezing drizzle |
| 61, 63, 65 | Rain (slight, moderate, heavy) |
| 66, 67 | Freezing rain |
| 71, 73, 75 | Snow fall (slight, moderate, heavy) |
| 77 | Snow grains |
| 80, 81, 82 | Rain showers (slight, moderate, violent) |
| 85, 86 | Snow showers |
| 95 | Thunderstorm |
| 96, 99 | Thunderstorm with hail |

## Adding a New Language

1. Create a new JSON file named `{language_code}.json` (e.g., `zh.json` for Chinese)
2. Copy the structure from an existing locale file
3. Translate all weather descriptions
4. Keep descriptions short (8-12 characters max) for better table formatting
5. Save the file with UTF-8 encoding

## Usage

The script automatically loads the locale based on your system language. To override:

```powershell
.\WeatherForecast.ps1 -LocaleOverride "pt"
```

## Contributing Translations

Feel free to add translations for additional languages. Consider:

- Keeping descriptions concise for table display
- Using common abbreviations when necessary
- Testing the locale file to ensure proper UTF-8 encoding
- Maintaining consistency with weather terminology in your language
