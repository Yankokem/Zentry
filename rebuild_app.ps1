# Rebuild Flutter app to fix plugin registration issues
Write-Host "Rebuilding Flutter app to fix plugin issues..." -ForegroundColor Cyan

# Clean build
Write-Host "`nCleaning build cache..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "`nGetting dependencies..." -ForegroundColor Yellow
flutter pub get

# Rebuild for Android
Write-Host "`nRebuilding app..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host "`nRebuild complete! Please reinstall the app on your device." -ForegroundColor Green
Write-Host "Run: flutter run" -ForegroundColor Cyan
