param([string]$Toolchain = 'C:\msys64\mingw64')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'local\power-peek-test'
New-Item -ItemType Directory -Force $out | Out-Null
$savedPath = $env:PATH
$savedPlatform = $env:QT_QPA_PLATFORM
$savedFonts = $env:QT_QPA_FONTDIR
try {
    $env:PATH = "$Toolchain\bin;$savedPath"
    $env:QT_QPA_PLATFORM = 'offscreen'
    $env:QT_QPA_FONTDIR = Join-Path $env:SystemRoot 'Fonts'
    $flags = & "$Toolchain\bin\pkg-config.exe" --cflags --libs Qt5Widgets Qt5Gui Qt5Core
    if ($LASTEXITCODE) { throw 'Qt development libraries missing.' }
    & "$Toolchain\bin\g++.exe" -std=c++17 "-I$root\upstream\86Box\src\qt" (Join-Path $root 'tests\power-peek-test.cpp') -o "$out\power-peek-test.exe" ($flags -split ' ')
    if ($LASTEXITCODE) { throw 'Power inset test compilation failed.' }
    & "$out\power-peek-test.exe" "$root\assets\front\power\rear-button-atlas.png"
    if ($LASTEXITCODE) { throw 'Power inset rendering regression failed.' }
} finally {
    $env:PATH = $savedPath
    $env:QT_QPA_PLATFORM = $savedPlatform
    $env:QT_QPA_FONTDIR = $savedFonts
}
