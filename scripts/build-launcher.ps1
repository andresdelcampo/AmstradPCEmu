[CmdletBinding()]
param([string]$Toolchain = 'C:\msys64\mingw64')
# Builds "Amstrad PC1512.exe" in the project root: a console-free launcher that
# starts local\dist\86Box.exe on the local\amstrad VM (see launcher\amstrad-launcher.c).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $Toolchain 'bin'
$savedPath = $env:PATH
try {
    $env:PATH = "$bin;$savedPath"
    $src = Join-Path $root 'launcher'
    $obj = Join-Path $root 'local\build\amstrad-launcher.res.o'
    New-Item -ItemType Directory -Force -Path (Split-Path $obj) | Out-Null
    Push-Location $src
    try {
        & (Join-Path $bin 'windres.exe') amstrad-launcher.rc -O coff -o $obj
        if ($LASTEXITCODE) { throw "windres failed ($LASTEXITCODE)." }
    } finally { Pop-Location }
    $out = Join-Path $root 'Amstrad PC1512.exe'
    # Static runtime: the launcher needs no DLLs beside it.
    & (Join-Path $bin 'gcc.exe') -O2 -municode -mwindows -static -s -o $out (Join-Path $src 'amstrad-launcher.c') $obj -lshell32
    if ($LASTEXITCODE) { throw "Launcher build failed ($LASTEXITCODE)." }
    Write-Host "Built $out"
} finally {
    $env:PATH = $savedPath
}
