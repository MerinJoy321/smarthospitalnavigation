# Android SDK Setup Helper Script
Write-Host "=== Android SDK Setup Helper ===" -ForegroundColor Cyan
Write-Host ""

# Check common SDK locations
$sdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:USERPROFILE\AppData\Local\Android\Sdk",
    "C:\Android\Sdk",
    "$env:ANDROID_HOME"
)

Write-Host "Checking for Android SDK..." -ForegroundColor Yellow
$foundSdk = $null

foreach ($path in $sdkPaths) {
    if ($path -and (Test-Path $path)) {
        if (Test-Path "$path\platform-tools\adb.exe") {
            Write-Host "✓ Found Android SDK at: $path" -ForegroundColor Green
            $foundSdk = $path
            break
        }
    }
}

if (-not $foundSdk) {
    Write-Host "✗ Android SDK not found in common locations." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Open Android Studio"
    Write-Host "2. Go to: File → Settings → Appearance & Behavior → System Settings → Android SDK"
    Write-Host "3. Note the 'Android SDK Location' path"
    Write-Host "4. Install SDK components (Platforms, Build-Tools, Platform-Tools, Emulator)"
    Write-Host "5. Then run: flutter config --android-sdk <your-sdk-path>"
    Write-Host ""
    Write-Host "Or download Android Studio from: https://developer.android.com/studio"
} else {
    Write-Host ""
    Write-Host "Configuring Flutter to use SDK at: $foundSdk" -ForegroundColor Yellow
    flutter config --android-sdk $foundSdk
    Write-Host ""
    Write-Host "Checking Flutter Android setup..." -ForegroundColor Yellow
    flutter doctor -v | Select-String -Pattern "Android" -Context 0,3
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Create an AVD in Android Studio: Tools → Device Manager → Create Device"
Write-Host "2. Start the emulator from Android Studio"
Write-Host "3. Run: flutter devices (to see the emulator)"
Write-Host "4. Run: flutter run (to launch your app)"
