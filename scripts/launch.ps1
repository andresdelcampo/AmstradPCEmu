param(
    [switch]$Baseline,
    [switch]$TestPattern,
    [switch]$NoCRT,
    [switch]$Wait,
    [string]$Installation = 'C:\Emulators\86Box'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$name = if ($Baseline) { 'baseline' } else { 'amstrad' }
& (Join-Path $PSScriptRoot 'prepare-vm.ps1') -Name $name -Installation $Installation
$vm = Join-Path $root "local\$name"
$exe = if ($Baseline) { Join-Path $Installation '86Box.exe' } else { Join-Path $root 'local\dist\86Box.exe' }
if (!(Test-Path $exe)) { throw "Build missing: $exe. Run scripts\build.ps1 first." }
if (!(Test-Path (Join-Path $root 'assets\front\pc1512-front.png'))) { throw 'Cabinet image missing: restore assets\front\pc1512-front.png.' }
$oldArt = $env:AMSTRAD_CABINET
$oldPattern = $env:AMSTRAD_TEST_PATTERN
$oldCRT = $env:AMSTRAD_CRT
$oldCRTLog = $env:AMSTRAD_CRT_LOG
try {
    $env:AMSTRAD_CABINET = if ($Baseline) { $null } else { Join-Path $root 'assets\front\pc1512-front.png' }
    $env:AMSTRAD_TEST_PATTERN = if ($TestPattern -and !$Baseline) { '1' } else { $null }
    $env:AMSTRAD_CRT = if ($NoCRT) { '0' } else { '1' }
    $env:AMSTRAD_CRT_LOG = Join-Path $vm 'crt.log'
    # A distinct global config prevents user/manager preferences leaking into this VM.
    $arguments = '-P "{0}" -R "{1}" -O "{0}\global.cfg" -L "{0}\86box.log"' -f $vm, (Join-Path $Installation 'roms')
    $process = Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe) -PassThru
    Write-Output "Started $exe (PID $($process.Id)), VM: $vm"
    if ($Wait) { $process.WaitForExit(); if ($process.ExitCode) { throw "86Box exited with code $($process.ExitCode). See $vm\86box.log." } }
} finally {
    $env:AMSTRAD_CABINET = $oldArt
    $env:AMSTRAD_TEST_PATTERN = $oldPattern
    $env:AMSTRAD_CRT = $oldCRT
    $env:AMSTRAD_CRT_LOG = $oldCRTLog
}
