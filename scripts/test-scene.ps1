param([string]$Toolchain = 'C:\msys64\mingw64')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'local\scene-test'
New-Item -ItemType Directory -Force $out | Out-Null
$oldPath = $env:PATH
try {
    $env:PATH = "$Toolchain\bin;$oldPath"
    $flags = & "$Toolchain\bin\pkg-config.exe" --cflags --libs Qt5Gui Qt5Core
    if ($LASTEXITCODE) { throw 'Qt5 development libraries missing.' }
    & "$Toolchain\bin\g++.exe" -std=c++17 "-I$root\upstream\86Box\src\qt" (Join-Path $root 'tests\scene-test.cpp') -o "$out\scene-test.exe" ($flags -split ' ')
    if ($LASTEXITCODE) { throw 'Scene test compilation failed.' }
    & "$out\scene-test.exe" "$root\assets\front\pc1512-front.png" "$out"
    if ($LASTEXITCODE) { throw "Scene test failed: $LASTEXITCODE" }
} finally { $env:PATH = $oldPath }
