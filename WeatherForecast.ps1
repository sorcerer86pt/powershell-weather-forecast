param(
    [string]$City,
    [ValidateSet('Celsius', 'Fahrenheit')]
    [string]$Units = 'Celsius',
    [switch]$SkipSystemLocation,
    [string]$LocaleOverride
)

$script:LastNominatimCall = [DateTime]::MinValue
$script:WeatherDescriptions = $null

function Get-LocalePath {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if ([string]::IsNullOrEmpty($scriptDir)) {
        $scriptDir = $PSScriptRoot
    }
    if ([string]::IsNullOrEmpty($scriptDir)) {
        $scriptDir = Get-Location
    }
    return Join-Path $scriptDir "locales"
}

function Load-LocaleFile {
    param([string]$LanguageCode)
    
    $localePath = Get-LocalePath
    if (-not (Test-Path $localePath)) {
        return $null
    }
    
    $localeFile = Join-Path $localePath "$LanguageCode.json"
    if (Test-Path $localeFile) {
        try {
            $content = Get-Content $localeFile -Raw -Encoding UTF8
            return ($content | ConvertFrom-Json)
        }
        catch {
            Write-Warning "Failed to load locale file '$localeFile': $($_.Exception.Message)"
            return $null
        }
    }
    return $null
}

function Initialize-Locales {
    $culture = Get-Culture
    $languageCode = if ($script:LocaleOverride) { 
        $script:LocaleOverride 
    } else { 
        $culture.TwoLetterISOLanguageName.ToLower() 
    }
    
    $localeData = Load-LocaleFile -LanguageCode $languageCode
    
    if ($null -eq $localeData) {
        $localeData = Load-LocaleFile -LanguageCode 'en'
    }
    
    if ($null -eq $localeData) {
        Write-Verbose "No locale files found, using built-in English fallback"
        $localeData = @{
            language = 'en'
            language_name = 'English'
            weather_codes = @{
                '0' = 'Clear'; '1' = 'M.Clear'; '2' = 'P.Cloudy'; '3' = 'Overcast'
                '45' = 'Fog'; '48' = 'Fog'; '51' = 'Lt.Drizzle'; '53' = 'Drizzle'; '55' = 'Hvy.Drizzle'
                '56' = 'Frz.Drizzle'; '57' = 'Frz.Drizzle'; '61' = 'Lt.Rain'; '63' = 'Rain'; '65' = 'Hvy.Rain'
                '66' = 'Frz.Rain'; '67' = 'Frz.Rain'; '71' = 'Lt.Snow'; '73' = 'Snow'; '75' = 'Hvy.Snow'
                '77' = 'Snow Grains'; '80' = 'Lt.Showers'; '81' = 'Showers'; '82' = 'Hvy.Showers'
                '85' = 'Snow Showers'; '86' = 'Snow Showers'; '95' = 'T-Storm'; '96' = 'T-Storm+Hail'; '99' = 'T-Storm+Hail'
            }
            unknown_text = 'Unknown'
        } | ConvertTo-Json | ConvertFrom-Json
    }
    
    $script:WeatherDescriptions = $localeData
}

function Invoke-NominatimRequest {
    param([string]$Uri)
    
    $timeSinceLastCall = (Get-Date) - $script:LastNominatimCall
    if ($timeSinceLastCall.TotalSeconds -lt 1) {
        Start-Sleep -Milliseconds ([Math]::Ceiling((1000 - $timeSinceLastCall.TotalMilliseconds)))
    }
    
    $userAgent = "PowerShell-Weather-Script/3.0 (Contact: weather-script@example.com)"
    $response = Invoke-RestMethod -Uri $Uri -Method Get -UserAgent $userAgent -TimeoutSec 10
    $script:LastNominatimCall = Get-Date
    return $response
}

function Get-LocationFromWindows {
    try {
        Write-Host "Attempting to use Windows Location Service..." -ForegroundColor Yellow
        Add-Type -AssemblyName System.Device
        $watcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $watcher.Start()

        $startTime = Get-Date
        while ($watcher.Status -ne 'Ready') {
            Start-Sleep -Milliseconds 200
            if (((Get-Date) - $startTime).TotalSeconds -gt 10) { 
                throw "Location service timed out after 10 seconds." 
            }
            if ($watcher.Permission -eq 'Denied') { 
                throw "Location access was denied. Enable location services in Windows Settings." 
            }
        }

        if ($watcher.Position.Location.IsUnknown) {
            throw "Location service returned unknown location."
        }

        $coords = $watcher.Position.Location
        Write-Host "Coordinates: Latitude $($coords.Latitude), Longitude $($coords.Longitude)" -ForegroundColor Green
        Write-Host "Looking up city name..." -ForegroundColor Green
        
        $reverseGeoUrl = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$($coords.Latitude)&lon=$($coords.Longitude)"
        $reverseGeoResponse = Invoke-NominatimRequest -Uri $reverseGeoUrl

        if ($reverseGeoResponse.address) {
            $addr = $reverseGeoResponse.address
            return @{
                City = $addr.city, $addr.town, $addr.village, $addr.hamlet | Where-Object { $_ } | Select-Object -First 1
                Region = if ($addr.state) { $addr.state } else { "" }
                Country = $addr.country
                Latitude = $coords.Latitude
                Longitude = $coords.Longitude
            }
        }
        throw "Reverse geocoding returned no address data."
    }
    catch {
        Write-Warning "Windows location service failed: $($_.Exception.Message)"
        return $null
    }
    finally {
        if ($watcher) { $watcher.Stop(); $watcher.Dispose() }
    }
}

function Get-LocationFromLinux {
    try {
        Write-Host "Attempting to use Linux GeoClue2 location service..." -ForegroundColor Yellow
        
        if (-not (Get-Command -Name "gdbus" -ErrorAction SilentlyContinue)) {
            throw "gdbus command not found. GeoClue2 requires gdbus (install glib2 package)."
        }
        
        $geoClueOutput = gdbus call --system `
            --dest org.freedesktop.GeoClue2 `
            --object-path /org/freedesktop/GeoClue2/Manager `
            --method org.freedesktop.GeoClue2.Manager.GetClient 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "GeoClue2 not available or not running."
        }
        
        if ($geoClueOutput -match "/org/freedesktop/GeoClue2/Client/\d+") {
            $clientPath = $matches[0]
            
            gdbus call --system `
                --dest org.freedesktop.GeoClue2 `
                --object-path $clientPath `
                --method org.freedesktop.GeoClue2.Client.Start | Out-Null
            
            Start-Sleep -Seconds 2
            
            $locationData = gdbus introspect --system `
                --dest org.freedesktop.GeoClue2 `
                --object-path $clientPath 2>&1
            
            if ($locationData -match "Latitude.*?(\d+\.\d+)" -and $locationData -match "Longitude.*?(\d+\.\d+)") {
                $latitude = [double]$matches[1]
                $longitude = [double]$matches[1]
                
                Write-Host "Coordinates: Latitude $latitude, Longitude $longitude" -ForegroundColor Green
                Write-Host "Looking up city name..." -ForegroundColor Green
                
                $reverseGeoUrl = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude"
                $reverseGeoResponse = Invoke-NominatimRequest -Uri $reverseGeoUrl
                
                if ($reverseGeoResponse.address) {
                    $addr = $reverseGeoResponse.address
                    return @{
                        City = $addr.city, $addr.town, $addr.village, $addr.hamlet | Where-Object { $_ } | Select-Object -First 1
                        Region = if ($addr.state) { $addr.state } else { "" }
                        Country = $addr.country
                        Latitude = $latitude
                        Longitude = $longitude
                    }
                }
            }
        }
        throw "Could not retrieve location from GeoClue2."
    }
    catch {
        Write-Warning "Linux location service failed: $($_.Exception.Message)"
        Write-Host "Tip: Ensure GeoClue2 is installed and running (geoclue2 package)" -ForegroundColor DarkGray
        return $null
    }
}

function Get-LocationFromMacOS {
    try {
        Write-Host "Attempting to use macOS CoreLocation service..." -ForegroundColor Yellow
        
        if (-not (Get-Command -Name "whereami" -ErrorAction SilentlyContinue)) {
            throw "whereami command not found. Install via: brew install whereami"
        }
        
        $locationJson = whereami -f json 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "whereami failed to get location."
        }
        
        $locationData = $locationJson | ConvertFrom-Json
        if ($locationData.latitude -and $locationData.longitude) {
            $latitude = [double]$locationData.latitude
            $longitude = [double]$locationData.longitude
            
            Write-Host "Coordinates: Latitude $latitude, Longitude $longitude" -ForegroundColor Green
            Write-Host "Looking up city name..." -ForegroundColor Green
            
            $reverseGeoUrl = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude"
            $reverseGeoResponse = Invoke-NominatimRequest -Uri $reverseGeoUrl
            
            if ($reverseGeoResponse.address) {
                $addr = $reverseGeoResponse.address
                return @{
                    City = $addr.city, $addr.town, $addr.village, $addr.hamlet | Where-Object { $_ } | Select-Object -First 1
                    Region = if ($addr.state) { $addr.state } else { "" }
                    Country = $addr.country
                    Latitude = $latitude
                    Longitude = $longitude
                }
            }
        }
        throw "Could not parse location data from whereami."
    }
    catch {
        Write-Warning "macOS location service failed: $($_.Exception.Message)"
        return $null
    }
}

function Get-LocationFromSystem {
    $os = $null
    if ($IsWindows -or $env:OS -match "Windows") {
        $os = "Windows"
    }
    elseif ($IsLinux) {
        $os = "Linux"
    }
    elseif ($IsMacOS) {
        $os = "macOS"
    }
    else {
        $os = [System.Environment]::OSVersion.Platform.ToString()
        if ($os -match "Win") {
            $os = "Windows"
        }
        elseif ($os -match "Unix") {
            if (Test-Path "/System/Library/CoreServices/SystemVersion.plist") {
                $os = "macOS"
            } else {
                $os = "Linux"
            }
        }
    }
    
    Write-Verbose "Detected OS: $os"
    
    switch ($os) {
        "Windows" { return Get-LocationFromWindows }
        "Linux"   { return Get-LocationFromLinux }
        "macOS"   { return Get-LocationFromMacOS }
        default   { 
            Write-Warning "Unsupported OS: $os. Skipping system location detection."
            return $null
        }
    }
}

function Get-LocationFromIP {
    try {
        Write-Host "Falling back to IP-based location..." -ForegroundColor Yellow
        $locationResponse = Invoke-RestMethod -Uri "https://ip-api.com/json/" -Method Get -TimeoutSec 5
        
        if ($locationResponse.status -eq "success") {
            return @{
                City = $locationResponse.city
                Region = $locationResponse.regionName
                Country = $locationResponse.country
                Latitude = $locationResponse.lat
                Longitude = $locationResponse.lon
            }
        }
        throw "IP location API returned status: $($locationResponse.status)"
    }
    catch {
        Write-Warning "IP-based location failed: $($_.Exception.Message)"
        return $null
    }
}

function Get-LocationFromCityName {
    param([string]$CityName)
    
    if ([string]::IsNullOrWhiteSpace($CityName)) {
        Write-Error "City name cannot be empty."
        return $null
    }
    
    try {
        Add-Type -AssemblyName System.Web
        $encodedCity = [System.Web.HttpUtility]::UrlEncode($CityName)
        $geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=$encodedCity&count=5&language=en&format=json"
        $geoResponse = Invoke-RestMethod -Uri $geoUrl -Method Get -TimeoutSec 10

        if ($geoResponse.results -and $geoResponse.results.Count -gt 0) {
            if ($geoResponse.results.Count -eq 1) {
                $result = $geoResponse.results[0]
            }
            else {
                Write-Host "`nMultiple locations found for '$CityName':" -ForegroundColor Cyan
                for ($i = 0; $i -lt [Math]::Min(5, $geoResponse.results.Count); $i++) {
                    $loc = $geoResponse.results[$i]
                    $region = if ($loc.admin1) { ", $($loc.admin1)" } else { "" }
                    Write-Host "  [$($i+1)] $($loc.name)$region, $($loc.country)" -ForegroundColor White
                }
                
                $selection = Read-Host "`nSelect location (1-$([Math]::Min(5, $geoResponse.results.Count)))"
                $index = [int]$selection - 1
                
                if ($index -ge 0 -and $index -lt $geoResponse.results.Count) {
                    $result = $geoResponse.results[$index]
                } else {
                    Write-Error "Invalid selection."
                    return $null
                }
            }
            
            return @{
                City = $result.name
                Region = if ($result.admin1) { $result.admin1 } else { "" }
                Country = $result.country
                Latitude = $result.latitude
                Longitude = $result.longitude
            }
        }
        Write-Error "No location found matching '$CityName'."
        return $null
    }
    catch {
        Write-Error "City search error: $($_.Exception.Message)"
        return $null
    }
}

function Get-LocationManually {
    Write-Host "`nPlease provide your location manually." -ForegroundColor Cyan
    $manualCity = Read-Host "Enter City name (e.g., Porto or Porto, Portugal)"
    return Get-LocationFromCityName -CityName $manualCity
}

function Get-WeatherForecast {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Location,
        [string]$TemperatureUnit = 'celsius'
    )
    
    try {
        Write-Host "Fetching 7-day weather forecast for $($Location.City)..." -ForegroundColor Yellow
        
        $weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
            "latitude=$($Location.Latitude)&longitude=$($Location.Longitude)" +
            "&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_sum,precipitation_probability_max,windspeed_10m_max" +
            "&temperature_unit=$TemperatureUnit&windspeed_unit=kmh&precipitation_unit=mm" +
            "&timezone=auto&forecast_days=7"
        
        $weatherResponse = Invoke-RestMethod -Uri $weatherUrl -Method Get -TimeoutSec 10
        return $weatherResponse
    }
    catch {
        Write-Error "Weather forecast error: $($_.Exception.Message)"
        return $null
    }
}

function Get-WeatherIcon { 
    param([int]$WeatherCode) 
    switch ($WeatherCode) { 
        0 { "☀️" }
        1 { "🌤️" }
        2 { "⛅" }
        3 { "☁️" }
        {$_ -in 45,48} { "🌫️" }
        {$_ -in 51,53,55,56,57} { "🌦️" }
        {$_ -in 61,63,65,66,67} { "☔" }
        {$_ -in 71,73,75,77,85,86} { "❄️" }
        {$_ -in 80,81,82} { "🌧️" }
        {$_ -in 95,96,99} { "⛈️" }
        default { "❓" }
    } 
}

function Get-WeatherDescription { 
    param([int]$WeatherCode)
    
    if ($null -eq $script:WeatherDescriptions) {
        Initialize-Locales
    }
    
    $codeStr = $WeatherCode.ToString()
    if ($script:WeatherDescriptions.weather_codes.PSObject.Properties[$codeStr]) {
        return $script:WeatherDescriptions.weather_codes.$codeStr
    }
    
    return $script:WeatherDescriptions.unknown_text
}

function Show-WeatherAsList {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Location,
        [Parameter(Mandatory=$true)]
        $WeatherData,
        [string]$TempUnit
    )

    $unitSymbol = if ($TempUnit -eq 'fahrenheit') { '°F' } else { '°C' }
    $precipUnit = 'mm'
    $windUnit = 'km/h'
    
    $headerText = "7-Day Weather Forecast for $($Location.City), $($Location.Country)"
    $boxWidth = 75
    $paddedText = "  $headerText".PadRight($boxWidth)
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║$paddedText║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $forecastObjects = for ($i = 0; $i -lt 7; $i++) {
        $date = [DateTime]::Parse($WeatherData.daily.time[$i])
        $weatherIcon = Get-WeatherIcon -WeatherCode $WeatherData.daily.weathercode[$i]
        $weatherDesc = Get-WeatherDescription -WeatherCode $WeatherData.daily.weathercode[$i]
        $highTemp = [math]::Round($WeatherData.daily.temperature_2m_max[$i], 0)
        $lowTemp = [math]::Round($WeatherData.daily.temperature_2m_min[$i], 0)
        $precip = [math]::Round($WeatherData.daily.precipitation_sum[$i], 1)
        $precipProb = $WeatherData.daily.precipitation_probability_max[$i]
        $windSpeed = [math]::Round($WeatherData.daily.windspeed_10m_max[$i], 0)
        
        [PSCustomObject]@{
            Date        = $date.ToString("ddd dd/MM", (Get-Culture))
            Icon        = $weatherIcon
            Weather     = $weatherDesc
            High        = "$highTemp$unitSymbol"
            Low         = "$lowTemp$unitSymbol"
            Rain        = if ($precip -gt 0 -or $precipProb -gt 0) { "$precip$precipUnit ($precipProb%)" } else { "-" }
            Wind        = "$windSpeed $windUnit"
        }
    }
    
    $forecastObjects | Format-Table -AutoSize -Property Date, Icon, Weather, High, Low, Rain, Wind
    
    Write-Host "`n────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "Weather data: Open-Meteo API | Location: OpenStreetMap Nominatim" -ForegroundColor DarkGray
    if ($script:WeatherDescriptions) {
        Write-Host "Language: $($script:WeatherDescriptions.language_name) ($($script:WeatherDescriptions.language))" -ForegroundColor DarkGray
    }
    Write-Host "Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
}

function Main {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    
    Initialize-Locales
    
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║     Weather Forecast - 7 Day Outlook              ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    $location = $null
    
    if ($City) {
        Write-Host "Using provided city: $City" -ForegroundColor Cyan
        $location = Get-LocationFromCityName -CityName $City
    }
    else {
        if (-not $SkipSystemLocation) {
            $location = Get-LocationFromSystem
        }
        if ($null -eq $location) {
            $location = Get-LocationFromIP
        }
        if ($null -eq $location) {
            $location = Get-LocationManually
        }
    }
    
    if ($null -eq $location) {
        Write-Host "`n❌ Unable to determine location. Exiting.`n" -ForegroundColor Red
        Start-Sleep -Seconds 3
        return
    }
    
    $region = if ($location.Region) { ", $($location.Region)" } else { "" }
    Write-Host "✓ Location: $($location.City)$region, $($location.Country)" -ForegroundColor Green
    
    $tempUnit = $Units.ToLower()
    $weather = Get-WeatherForecast -Location $location -TemperatureUnit $tempUnit
    
    if ($null -eq $weather) {
        Write-Host "`n❌ Unable to get weather forecast. Exiting.`n" -ForegroundColor Red
        Start-Sleep -Seconds 3
        return
    }
    
    Show-WeatherAsList -Location $location -WeatherData $weather -TempUnit $tempUnit
    
    Write-Host "`nPress any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Main

