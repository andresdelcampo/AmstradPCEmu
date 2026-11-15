param(
    [string]$Toolchain = 'C:\msys64\mingw64',
    [string]$FontRom = 'C:\Emulators\86Box\roms\machines\pc1512\40078'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'local\monitor-preview'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$savedPath = $env:PATH
$savedPlatform = $env:QT_QPA_PLATFORM
$savedFonts = $env:QT_QPA_FONTDIR
try {
    $env:PATH = "$Toolchain\bin;$savedPath"
    $env:QT_QPA_PLATFORM = 'offscreen'
    $env:QT_QPA_FONTDIR = Join-Path $env:SystemRoot 'Fonts'
    $flags = & "$Toolchain\bin\pkg-config.exe" --cflags --libs Qt5Widgets Qt5Gui Qt5Core
    if ($LASTEXITCODE) { throw 'Qt development libraries missing.' }
    & "$Toolchain\bin\g++.exe" -std=c++17 "-I$root\upstream\86Box\src\qt" (Join-Path $root 'tests\monitor-preview.cpp') -o "$out\monitor-preview.exe" ($flags -split ' ')
    if ($LASTEXITCODE) { throw 'Monitor preview compilation failed.' }
    & "$out\monitor-preview.exe" $root $FontRom "$out\monitor.png"
    if ($LASTEXITCODE) { throw "Monitor preview failed ($LASTEXITCODE)." }
    Write-Output "$out\monitor.png"
} finally {
    $env:PATH = $savedPath
    $env:QT_QPA_PLATFORM = $savedPlatform
    $env:QT_QPA_FONTDIR = $savedFonts
}
