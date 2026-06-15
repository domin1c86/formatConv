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
$ToolCacheDir = Join-Path $RepoRoot "third_party\tools\windows"
$FfmpegCacheDir = Join-Path $ToolCacheDir "ffmpeg"
$ImageMagickCacheDir = Join-Path $ToolCacheDir "imagemagick"

function Assert-FileExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw $Message
  }
}

function Copy-DirectoryContents {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir,
    [Parameter(Mandatory = $true)]
    [string]$DestinationDir
  )

  if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    throw "Directory not found: $SourceDir"
  }

  New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null
  Get-ChildItem -LiteralPath $SourceDir -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $DestinationDir -Recurse -Force
  }
}

function Resolve-ImageMagickSourceDir {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RootDir
  )

  $directMagick = Join-Path $RootDir "magick.exe"
  if (Test-Path -LiteralPath $directMagick -PathType Leaf) {
    return $RootDir
  }

  $nestedMagick = Get-ChildItem -LiteralPath $RootDir -Recurse -Filter "magick.exe" -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if ($null -ne $nestedMagick) {
    return $nestedMagick.DirectoryName
  }

  throw "ImageMagick portable cache is missing magick.exe. Place the portable ImageMagick contents under: $RootDir"
}

function Copy-ExternalTools {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseDir
  )

  $toolsDir = Join-Path $ReleaseDir "tools"
  $ffmpegExe = Join-Path $FfmpegCacheDir "ffmpeg.exe"
  $ffprobeExe = Join-Path $FfmpegCacheDir "ffprobe.exe"

  Assert-FileExists -Path $ffmpegExe -Message "Missing ffmpeg.exe. Expected: $ffmpegExe"
  Assert-FileExists -Path $ffprobeExe -Message "Missing ffprobe.exe. Expected: $ffprobeExe"

  if (-not (Test-Path -LiteralPath $ImageMagickCacheDir -PathType Container)) {
    throw "Missing ImageMagick portable cache. Expected directory: $ImageMagickCacheDir"
  }

  $imageMagickSourceDir = Resolve-ImageMagickSourceDir -RootDir $ImageMagickCacheDir

  if (Test-Path -LiteralPath $toolsDir) {
    Remove-Item -LiteralPath $toolsDir -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null

  Copy-Item -LiteralPath $ffmpegExe -Destination $toolsDir -Force
  Copy-Item -LiteralPath $ffprobeExe -Destination $toolsDir -Force
  Copy-DirectoryContents -SourceDir $imageMagickSourceDir -DestinationDir $toolsDir

  Assert-FileExists -Path (Join-Path $toolsDir "ffmpeg.exe") -Message "Bundled ffmpeg.exe was not found in $toolsDir"
  Assert-FileExists -Path (Join-Path $toolsDir "ffprobe.exe") -Message "Bundled ffprobe.exe was not found in $toolsDir"
  Assert-FileExists -Path (Join-Path $toolsDir "magick.exe") -Message "Bundled magick.exe was not found in $toolsDir"

  Write-Host "External tools bundled into: $toolsDir"
}

Write-Host "Building Go shared library (x64)..."
Push-Location $GoDir
try {
  $env:GOOS = "windows"
  $env:GOARCH = "amd64"
  $env:CGO_ENABLED = "1"
  go build -buildmode=c-shared -o $DllPath .
  if ($LASTEXITCODE -ne 0) {
    throw "Go shared library build failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}

Write-Host "Building Flutter Windows app ($Mode)..."
Push-Location $FlutterDir
try {
  flutter build windows --$Mode
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows build failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}

$ReleaseDir = Join-Path $FlutterDir "build\windows\x64\runner\Release"
if ($Mode -ne "release") {
  $modeName = $Mode.Substring(0, 1).ToUpperInvariant() + $Mode.Substring(1).ToLowerInvariant()
  $ReleaseDir = Join-Path $FlutterDir "build\windows\x64\runner\$modeName"
}

Write-Host "Bundling external tools..."
Copy-ExternalTools -ReleaseDir $ReleaseDir

Write-Host "Windows build complete."
