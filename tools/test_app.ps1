param([string]$FlutterPath = 'flutter')
$ErrorActionPreference = 'Stop'
$FlutterPath = (Get-Command $FlutterPath -CommandType Application -ErrorAction Stop).Source
$toolchain = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
$sdkInfoText = & $FlutterPath --version --machine
if ($LASTEXITCODE -ne 0) { throw 'Flutter SDK could not be started.' }
$sdkInfo = $sdkInfoText | ConvertFrom-Json
if ($sdkInfo.frameworkVersion -ne $toolchain.flutter_version -or
    $sdkInfo.frameworkRevision -ne $toolchain.flutter_framework_revision -or
    $sdkInfo.dartSdkVersion -ne $toolchain.flutter_dart_version) {
    throw 'Flutter framework/Dart version differs from tools/toolchain.json.'
}
$DartPath = Join-Path (Split-Path $FlutterPath -Parent) 'cache\dart-sdk\bin\dart.exe'
$reportDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\build\reports'))
New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
$testLog = Join-Path $reportDirectory 'flutter-tests.log'
Push-Location (Join-Path $PSScriptRoot '..\apps\calculator')
try {
    & $FlutterPath pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency lock verification failed.' }
    & $DartPath format --output=none --set-exit-if-changed lib test tool
    if ($LASTEXITCODE -ne 0) { throw 'Flutter source formatting check failed.' }
    & $FlutterPath analyze
    if ($LASTEXITCODE -ne 0) { throw 'Flutter static analysis failed.' }
    & $FlutterPath test --no-pub --reporter expanded 2>&1 | Tee-Object -FilePath $testLog
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
    Write-Output "Flutter test log: $testLog"
} finally {
    Pop-Location
}
