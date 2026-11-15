param([string]$Toolchain = 'C:\msys64\mingw64', [switch]$Windows)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$folder = if ($Windows) { 'local\popup-theme-windows-test' } else { 'local\popup-theme-test' }
$out = Join-Path $root $folder
New-Item -ItemType Directory -Force -Path $out | Out-Null
$savedPath = $env:PATH
$savedPlatform = $env:QT_QPA_PLATFORM
$savedFonts = $env:QT_QPA_FONTDIR
try {
    $env:PATH = "$Toolchain\bin;$savedPath"
    $env:QT_QPA_PLATFORM = if ($Windows) { 'windows' } else { 'offscreen' }
    $env:QT_QPA_FONTDIR = Join-Path $env:SystemRoot 'Fonts'
    $flags = & "$Toolchain\bin\pkg-config.exe" --cflags --libs Qt5Widgets Qt5Gui Qt5Core
    if ($LASTEXITCODE) { throw 'Qt development libraries missing.' }
    & "$Toolchain\bin\g++.exe" -std=c++17 "-I$root\upstream\86Box\src\qt" (Join-Path $root 'tests\popup-theme-test.cpp') -o "$out\popup-theme-test.exe" ($flags -split ' ')
    if ($LASTEXITCODE) { throw 'Popup theme test compilation failed.' }
    if ($Windows) { & "$out\popup-theme-test.exe" $out 'native-headless' }
    else { & "$out\popup-theme-test.exe" $out }
    if ($LASTEXITCODE) { throw 'Popup theme regression failed.' }
} finally {
    $env:PATH = $savedPath
    $env:QT_QPA_PLATFORM = $savedPlatform
    $env:QT_QPA_FONTDIR = $savedFonts
}
