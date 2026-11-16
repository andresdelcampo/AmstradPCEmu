param([string]$Toolchain = 'C:\msys64\mingw64')
# Saves the cabinet at rest and with its live parts shown to local\hints-test
# and checks the corner mark's hover, linger and fade.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'local\hints-test'
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
    & "$Toolchain\bin\g++.exe" -std=c++17 "-I$root\upstream\86Box\src\qt" (Join-Path $root 'tests\hints-test.cpp') -o "$out\hints-test.exe" ($flags -split ' ')
    if ($LASTEXITCODE) { throw 'Hints test compilation failed.' }
    & "$out\hints-test.exe" "$root\assets\front\pc1512-front.png" $out
    if ($LASTEXITCODE) { throw 'Cabinet hints test failed.' }
} finally {
    $env:PATH = $savedPath
    $env:QT_QPA_PLATFORM = $savedPlatform
    $env:QT_QPA_FONTDIR = $savedFonts
}
