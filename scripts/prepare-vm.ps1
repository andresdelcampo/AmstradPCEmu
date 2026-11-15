param(
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Name = 'amstrad',
    [string]$Installation = 'C:\Emulators\86Box'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Get-SHA256([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    # The installed 86Box may already have the original mounted for writing.
    # Hash with read access while allowing that existing handle to stay open.
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
}
$vm = Join-Path $root "local\$Name"
$roms = Join-Path $Installation 'roms'
foreach ($rom in '40043', '40044', '40078') {
    $romPath = Join-Path $roms "machines\pc1512\$rom"
    if (!(Test-Path $romPath)) {
        throw "Missing PC1512 ROM $rom. Supply your firmware under $roms\machines\pc1512."
    }
    if ((Get-Item $romPath).Length -ne 8192) { throw "Invalid PC1512 ROM size: $romPath. Expected 8192 bytes." }
}
New-Item -ItemType Directory -Force (Join-Path $vm 'media') | Out-Null
$records = foreach ($pair in @(@('PC1512 A1 - MSDOS.img', 'dos.img'), @('PC1512 A2 - GEM1.img', 'gem1.img'))) {
    $original = Join-Path $Installation "Disks\$($pair[0])"
    $copy = Join-Path $vm "media\$($pair[1])"
    if (!(Test-Path $original)) { throw "Missing media: $original. Supply a 360 KiB PC1512 disk image." }
    if ((Get-Item $original).Length -ne 368640) { throw "Expected a 360 KiB disk: $original" }
    if (!(Test-Path $copy)) { Copy-Item -LiteralPath $original -Destination $copy }
    [PSCustomObject]@{ Original = $original; OriginalSHA256 = Get-SHA256 $original; Copy = $copy; CopySHA256 = Get-SHA256 $copy }
}
$records | ConvertTo-Json | Set-Content (Join-Path $vm 'media-manifest.json') -Encoding UTF8
$config = Join-Path $vm '86box.cfg'
if (!(Test-Path $config)) {
@'
[General]
vid_renderer = qt_software
vid_resize = 1
force_43 = 1
confirm_exit = 0
confirm_reset = 0
window_remember = 1
hide_tool_bar = 1

[Monitor #1]
window_coordinates = 100, 50, 900, 950

[Machine]
machine = pc1512
cpu_family = 8086
cpu_speed = 8000000
cpu_multi = 1
mem_size = 512
cpu_use_dynarec = 0
time_sync = disabled

[Video]
gfxcard = internal

[Input devices]
mouse_type = internal

[Sound]
sndcard = none

[Floppy and CD-ROM drives]
fdd_01_type = 525_2dd
fdd_02_type = 525_2dd
fdd_01_fn = media/dos.img
fdd_02_fn = media/gem1.img
fdd_01_writeprot = 1
fdd_02_writeprot = 1
fdd_01_audio = panasonic_ju4755_40t
fdd_02_audio = panasonic_ju4755_40t
'@ | Set-Content -LiteralPath $config -Encoding ASCII
}
$global = Join-Path $vm 'global.cfg'
if (!(Test-Path $global)) {
@'
[Emulator]
confirm_exit = 0
confirm_reset = 0
confirm_save = 0
'@ | Set-Content -LiteralPath $global -Encoding ASCII
}
Write-Output "VM ready: $vm (existing config/media preserved). ROMs remain external: $roms"
