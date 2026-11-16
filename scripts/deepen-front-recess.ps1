param([string]$Path, [string]$Out)
# Sets the drive bays lower in the grey recess and gives the recess its grey
# inner walls, as on the real cabinet seen from slightly above: a lit bottom
# wall and faint side walls, mitred at the corners.
#
# Works in place on whatever pc1512-front.png currently is and may be re-run
# after any other change to it: the drive position is detected, so the bays
# are moved only as far as they still need to go, and the walls are rebuilt
# from panel pixels this script never alters.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
if (!$Path) { $Path = Join-Path $root 'assets/front/pc1512-front.png' }
if (!$Out) { $Out = $Path }

# Master-pixel geometry (1254 x 1254 canvas).
$driveTop  = 1022   # wanted row of the drive housings' black top border
$probeX    = 300    # a column through the left housing, clear of lever and LED
$rowL      = 140    # whole rows are moved between these columns; the recess
$rowR      = 1112   # sides are vertical here, so the cream rim is unaffected
$blockTop  = 1010   # first row that moves (below the POWER lettering)
$panelL    = 150    # grey fascia, inclusive
$panelR    = 1100
$wallTop   = 1165   # back edge of the bottom wall
$wallEnd   = 1174   # its front edge, against the cream lip
$sideWidth = 6      # visible width of the side walls
$sideTop   = 960

$bytes = [IO.File]::ReadAllBytes($Path)
$stream = [IO.MemoryStream]::new($bytes)
$bmp = [Drawing.Bitmap]::FromStream($stream)   # the stream stays open until saved
if ($bmp.Width -ne 1254 -or $bmp.Height -ne 1254) { throw 'Expected the 1254 x 1254 front.' }
# Edited in place through LockBits: redrawing would premultiply, and so
# disturb, the cabinet's semi-transparent outline.
if ($bmp.PixelFormat -ne [Drawing.Imaging.PixelFormat]::Format32bppArgb) { throw "Unexpected pixel format: $($bmp.PixelFormat)" }
$rect = [Drawing.Rectangle]::new(0, 0, 1254, 1254)
$data = $bmp.LockBits($rect, [Drawing.Imaging.ImageLockMode]::ReadWrite, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$px = [byte[]]::new($stride * 1254)
[Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $px.Length)

function Dark([int]$x, [int]$y) {
    $i = $y * $stride + $x * 4
    return [Math]::Max($px[$i], [Math]::Max($px[$i + 1], $px[$i + 2])) -lt 40
}
function Grey([int]$i) {   # fascia grey, as opposed to cream plastic or its blends
    return [Math]::Abs($px[$i + 2] - $px[$i]) -le 10 -and $px[$i + 2] -lt 190
}

# 1. Move the bays. The recess top shadow has faded out well above 990.
$found = 0
for ($y = 990; $y -le 1060; $y++) { if (Dark $probeX $y) { $found = $y; break } }
if (!$found) { throw 'Drive housing not found.' }
# A softened border starts with a half-dark row: take the darkest of three.
function Level([int]$y) { $i = $y * $stride + $probeX * 4; return $px[$i] + $px[$i + 1] + $px[$i + 2] }
$best = $found
foreach ($y in ($found + 1), ($found + 2)) { if ((Level $y) -lt (Level $best)) { $best = $y } }
$found = $best
$shift = $driveTop - $found
if ($shift -lt 0 -or $shift -gt 24) { throw "Unexpected drive position: top border at row $found." }
if ($shift) {
    $n = ($rowR - $rowL + 1) * 4
    for ($y = $wallTop - 1 - $shift; $y -ge $blockTop; $y--) {
        [Buffer]::BlockCopy($px, $y * $stride + $rowL * 4, $px, ($y + $shift) * $stride + $rowL * 4, $n)
    }
    # The vacated rows repeat the plain fascia just above them.
    for ($y = $blockTop; $y -lt $blockTop + $shift; $y++) {
        [Buffer]::BlockCopy($px, ($y - $shift) * $stride + $rowL * 4, $px, $y * $stride + $rowL * 4, $n)
    }
}

# 2. Inner walls, rebuilt from untouched fascia: rows just above the bottom
# wall, and columns just inside the side walls, so the grain carries over.
function Lit([int]$x, [int]$y, [int]$fromX, [int]$fromY, [double]$gain) {
    $i = $y * $stride + $x * 4
    if (!(Grey $i)) { return }
    $s = $fromY * $stride + $fromX * 4
    if (!(Grey $s)) { return }
    foreach ($c in 0..2) { $px[$i + $c] = [byte][Math]::Min(255, [Math]::Round($px[$s + $c] * $gain)) }
}
$depth = $wallEnd - $wallTop
for ($y = $sideTop; $y -le $wallEnd; $y++) {
    # Mitre: the bottom wall narrows towards its back edge.
    $t = [Math]::Max(0.0, [Math]::Min(1.0, ($y - $wallTop) / [double]$depth))
    $inset = if ($y -ge $wallTop) { [int][Math]::Round($sideWidth * (1 - $t)) } else { $sideWidth }
    # Beside the bottom wall, sample the unlit rows above it instead.
    $from = if ($y -ge $wallTop) { $wallTop - 5 + ($y % 4) } else { $y }
    for ($k = 0; $k -lt $inset; $k++) {
        # A slightly darker crease where each side wall meets the fascia.
        $gain = if ($k -eq $inset - 1) { 0.95 } else { 1.07 + 0.04 * (1 - $k / [double]$sideWidth) }
        Lit ($panelL + $k) $y ($panelL + $k + $sideWidth + 2) $from $gain
        Lit ($panelR - $k) $y ($panelR - $k - $sideWidth - 2) $from $gain
    }
    if ($y -lt $wallTop) { continue }
    $gain = if ($y -eq $wallTop) { 0.93 } else { 1.16 + 0.12 * $t }
    for ($x = $panelL + $inset; $x -le $panelR - $inset; $x++) { Lit $x $y $x $from $gain }
}

[Runtime.InteropServices.Marshal]::Copy($px, 0, $data.Scan0, $px.Length)
$bmp.UnlockBits($data)
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $stream.Dispose()
Write-Output "Drive housings moved $shift rows (top border now row $driveTop); recess walls rebuilt: $Out"
