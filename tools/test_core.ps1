param([string]$DartPath = 'dart')
$ErrorActionPreference = 'Stop'
$toolchain = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$sdkInfo = & $DartPath --version
if ($LASTEXITCODE -ne 0) { throw 'Dart SDK could not be started.' }
$requiredVersion = [regex]::Escape($toolchain.dart_version)
if ($sdkInfo -notmatch "Dart SDK version: $requiredVersion\s") {
    throw "Expected Dart $($toolchain.dart_version); got $sdkInfo"
}
Write-Output $sdkInfo
Push-Location (Join-Path $PSScriptRoot '..\packages\calculator_core')
try {
    & $DartPath pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Dependency lock verification failed.' }
    & $DartPath format --output=none --set-exit-if-changed lib bin test
    if ($LASTEXITCODE -ne 0) { throw 'Formatting check failed.' }
    & $DartPath analyze
    if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
    & $DartPath test --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw 'Core tests failed.' }
} finally {
    Pop-Location
}
