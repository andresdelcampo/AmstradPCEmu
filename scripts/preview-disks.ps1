param([string]$Toolchain = 'C:\msys64\mingw64')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'local\disk-preview'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$savedPath = $env:PATH
$savedPlatform = $env:QT_QPA_PLATFORM
$savedFonts = $env:QT_QPA_FONTDIR
try {
    $env:PATH = "$Toolchain\bin;$savedPath"
    # The offscreen platform's small screen would wrap the menu into columns.
    $env:QT_QPA_PLATFORM = 'windows'
    $env:QT_QPA_FONTDIR = Join-Path $env:SystemRoot 'Fonts'
    $flags = & "$Toolchain\bin\pkg-config.exe" --cflags --libs Qt5Widgets Qt5Gui Qt5Core
    if ($LASTEXITCODE) { throw 'Qt development libraries missing.' }
    & "$Toolchain\bin\g++.exe" -std=c++17 "-I$root\upstream\86Box\src\qt" (Join-Path $root 'tests\disk-preview.cpp') -o "$out\disk-preview.exe" ($flags -split ' ')
    if ($LASTEXITCODE) { throw 'Disk preview compilation failed.' }
    & "$out\disk-preview.exe" $root "$out\vm" "$out\disks.png"
    if ($LASTEXITCODE) { throw "Disk preview failed ($LASTEXITCODE)." }
} finally {
    $env:PATH = $savedPath
    $env:QT_QPA_PLATFORM = $savedPlatform
    $env:QT_QPA_FONTDIR = $savedFonts
}
