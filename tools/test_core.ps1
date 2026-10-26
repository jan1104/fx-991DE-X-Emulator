param([string]$DartPath = 'dart')
$ErrorActionPreference = 'Stop'
$DartPath = (Get-Command $DartPath -CommandType Application -ErrorAction Stop).Source
$toolchain = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$reportDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\build\reports'))
New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
$testLog = Join-Path $reportDirectory 'core-tests.log'
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
    & $DartPath test --reporter expanded 2>&1 | Tee-Object -FilePath $testLog
    if ($LASTEXITCODE -ne 0) { throw 'Core tests failed.' }
    Write-Output "Core test log: $testLog"
} finally {
    Pop-Location
}
