param(
  [ValidateSet("debug", "profile", "release")]
  [string]$Mode = "release"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterDir = Resolve-Path (Join-Path $ScriptDir "..")
$RepoRoot = Resolve-Path (Join-Path $FlutterDir "..")
$GoDir = Join-Path $RepoRoot "native"
$DllPath = Join-Path $FlutterDir "format_conv.dll"

Write-Host "Building Go shared library..."
Push-Location $GoDir
try {
  $env:GOOS = "windows"
  $env:GOARCH = "amd64"
  $env:CGO_ENABLED = "1"
  go build -buildmode=c-shared -o $DllPath .
} finally {
  Pop-Location
}

Write-Host "Building Flutter Windows app ($Mode)..."
Push-Location $FlutterDir
try {
  flutter build windows --$Mode
} finally {
  Pop-Location
}

Write-Host "Windows build complete."
