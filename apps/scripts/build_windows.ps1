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
$LicenseSourceDir = Join-Path $RepoRoot "licenses"
$ThirdPartyNoticesPath = Join-Path $RepoRoot "THIRD_PARTY_NOTICES.md"

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

function Copy-IfExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Destination
  )

  if (Test-Path -LiteralPath $Source -PathType Leaf) {
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    return $true
  }

  return $false
}

function Copy-LicenseFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseDir
  )

  $releaseLicenseDir = Join-Path $ReleaseDir "licenses"
  if (Test-Path -LiteralPath $releaseLicenseDir) {
    Remove-Item -LiteralPath $releaseLicenseDir -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $releaseLicenseDir | Out-Null

  Assert-FileExists `
    -Path (Join-Path $LicenseSourceDir "FormatConv-MIT.txt") `
    -Message "Missing FormatConv MIT license template."
  Assert-FileExists `
    -Path (Join-Path $LicenseSourceDir "FFmpeg-GPLv3.txt") `
    -Message "Missing FFmpeg GPLv3 notice."
  Assert-FileExists `
    -Path (Join-Path $LicenseSourceDir "FFmpeg-SOURCE.txt") `
    -Message "Missing FFmpeg source tracking notice."
  Assert-FileExists `
    -Path $ThirdPartyNoticesPath `
    -Message "Missing THIRD_PARTY_NOTICES.md."

  Copy-Item -LiteralPath (Join-Path $LicenseSourceDir "FormatConv-MIT.txt") -Destination (Join-Path $releaseLicenseDir "FormatConv-MIT.txt") -Force
  Copy-Item -LiteralPath (Join-Path $LicenseSourceDir "FFmpeg-GPLv3.txt") -Destination (Join-Path $releaseLicenseDir "FFmpeg-GPLv3.txt") -Force
  Copy-Item -LiteralPath (Join-Path $LicenseSourceDir "FFmpeg-SOURCE.txt") -Destination (Join-Path $releaseLicenseDir "FFmpeg-SOURCE.txt") -Force
  Copy-Item -LiteralPath (Join-Path $LicenseSourceDir "MiSans-NOTICE.txt") -Destination (Join-Path $releaseLicenseDir "MiSans-NOTICE.txt") -Force
  Copy-Item -LiteralPath $ThirdPartyNoticesPath -Destination (Join-Path $releaseLicenseDir "THIRD_PARTY_NOTICES.txt") -Force

  Copy-IfExists `
    -Source (Join-Path $LicenseSourceDir "MiSans-License-Agreement.pdf") `
    -Destination (Join-Path $releaseLicenseDir "MiSans-License-Agreement.pdf") | Out-Null

  $imageMagickLicenseCopied = Copy-IfExists `
    -Source (Join-Path $ImageMagickCacheDir "LICENSE.txt") `
    -Destination (Join-Path $releaseLicenseDir "ImageMagick-LICENSE.txt")
  if (-not $imageMagickLicenseCopied) {
    Copy-Item -LiteralPath (Join-Path $LicenseSourceDir "ImageMagick-LICENSE.txt") -Destination (Join-Path $releaseLicenseDir "ImageMagick-LICENSE.txt") -Force
  }

  Copy-IfExists `
    -Source (Join-Path $ImageMagickCacheDir "NOTICE.txt") `
    -Destination (Join-Path $releaseLicenseDir "ImageMagick-NOTICE.txt") | Out-Null

  $ffmpegVersionCopied = Copy-IfExists `
    -Source (Join-Path $FfmpegCacheDir "ffmpeg-git-essentials.7z.ver") `
    -Destination (Join-Path $releaseLicenseDir "ffmpeg-git-essentials.7z.ver")
  $ffmpegHashCopied = Copy-IfExists `
    -Source (Join-Path $FfmpegCacheDir "ffmpeg-git-essentials.7z.sha256") `
    -Destination (Join-Path $releaseLicenseDir "ffmpeg-git-essentials.7z.sha256")

  if (-not $ffmpegVersionCopied) {
    Write-Warning "Missing ffmpeg-git-essentials.7z.ver. Keep it for public releases to identify the exact FFmpeg git build."
  }
  if (-not $ffmpegHashCopied) {
    Write-Warning "Missing ffmpeg-git-essentials.7z.sha256. Keep it for public releases to verify the exact FFmpeg archive."
  }

  Assert-FileExists -Path (Join-Path $releaseLicenseDir "FormatConv-MIT.txt") -Message "Bundled FormatConv MIT license was not found."
  Assert-FileExists -Path (Join-Path $releaseLicenseDir "FFmpeg-GPLv3.txt") -Message "Bundled FFmpeg GPLv3 notice was not found."
  Assert-FileExists -Path (Join-Path $releaseLicenseDir "ImageMagick-LICENSE.txt") -Message "Bundled ImageMagick license was not found."
  Assert-FileExists -Path (Join-Path $releaseLicenseDir "THIRD_PARTY_NOTICES.txt") -Message "Bundled third-party notices were not found."

  Write-Host "License notices bundled into: $releaseLicenseDir"
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

Write-Host "Bundling license notices..."
Copy-LicenseFiles -ReleaseDir $ReleaseDir

Write-Host "Windows build complete."
