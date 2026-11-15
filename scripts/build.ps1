[CmdletBinding()]
param(
    [string]$Toolchain = 'C:\msys64\mingw64',
    [int]$Jobs = 8,
    [switch]$ConfigureOnly,
    [switch]$SkipDeploy,
    [string]$FloppySoundSource = 'C:\Emulators\86Box\assets\sounds\fdd',
    [string]$HardDiskSoundSource = 'C:\Emulators\86Box\assets\sounds\hdd'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root 'local\build'
$bin = Join-Path $Toolchain 'bin'
$savedPath = $env:PATH
try {
    $env:PATH = "$bin;$savedPath"
    $cmake = Join-Path $bin 'cmake.exe'
    if (!(Test-Path -LiteralPath $cmake)) { throw "CMake not found: $cmake" }
    $options = @(
        '-S', (Join-Path $root 'upstream\86Box'), '-B', $build, '-G', 'Ninja',
        '-DCMAKE_BUILD_TYPE=Release', "-DCMAKE_C_COMPILER=$bin/gcc.exe",
        "-DCMAKE_CXX_COMPILER=$bin/g++.exe", "-DCMAKE_PREFIX_PATH=$Toolchain",
        '-DSTATIC_BUILD=OFF', '-DUSE_QT6=OFF', '-DSDL2=ON', '-DOPENAL=ON',
        '-DRTMIDI=OFF', '-DFLUIDSYNTH=OFF', '-DMUNT=OFF', '-DSOUNDCANVAS=OFF',
        '-DDISASM=OFF', '-DDISCORD=OFF', '-DDYNAREC=OFF', '-DBUILD_TRANSLATIONS=OFF',
        '-DAUTOMATION=ON'
    )
    & $cmake @options
    if ($LASTEXITCODE) { throw "CMake configure failed ($LASTEXITCODE)." }
    if ($ConfigureOnly) { return }
    & $cmake --build $build --parallel $Jobs
    if ($LASTEXITCODE) { throw "Build failed ($LASTEXITCODE)." }
    if (!$SkipDeploy) { & (Join-Path $PSScriptRoot 'deploy.ps1') -Toolchain $Toolchain -FloppySoundSource $FloppySoundSource -HardDiskSoundSource $HardDiskSoundSource }
    & (Join-Path $PSScriptRoot 'build-launcher.ps1') -Toolchain $Toolchain
} finally {
    $env:PATH = $savedPath
}
