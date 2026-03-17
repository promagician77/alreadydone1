$keystore = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (-not (Test-Path $keystore)) {
    Write-Host "Debug keystore not found at: $keystore"
    Write-Host "Run from project root first: flutter build apk --debug"
    exit 1
}
Write-Host "Using keystore: $keystore"
Write-Host ""
& keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android 2>$null
if ($LASTEXITCODE -ne 0) {
    & keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android
}
