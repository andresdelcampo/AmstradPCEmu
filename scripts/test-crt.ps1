param([string]$Toolchain='C:\msys64\mingw64', [string]$Platform='offscreen')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$savedPath=$env:PATH
$savedPlatform=$env:QT_QPA_PLATFORM
try {
    $env:PATH="$Toolchain\bin;$savedPath"
    $env:QT_QPA_PLATFORM=$Platform
    $flags=(& "$Toolchain\bin\pkg-config.exe" --cflags --libs Qt5Gui Qt5Core) -split ' '
    $exe=Join-Path $root 'local\test-crt.exe'
    & "$Toolchain\bin\g++.exe" '-std=c++17' '-O2' '-Iupstream/86Box/src/qt' 'tests/test-ibmulator-crt.cpp' '-o' $exe @flags
    if($LASTEXITCODE){throw "CRT test compile failed: $LASTEXITCODE"}
    $guest=Join-Path $root 'local\verification-shader\dir-a-raw.png'
    $arguments=@((Join-Path $root 'assets\shaders\ibmulator-crt.frag'), (Join-Path $root 'local\ibmulator-crt-test.png'))
    if(Test-Path -LiteralPath $guest){$arguments+=$guest}
    & $exe @arguments
    if($LASTEXITCODE){throw "CRT GPU test failed: $LASTEXITCODE"}
} finally {
    $env:PATH=$savedPath
    $env:QT_QPA_PLATFORM=$savedPlatform
}
