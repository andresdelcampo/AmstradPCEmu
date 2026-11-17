param([switch]$SuffixOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $root 'assets/front'
$badgeDir = Join-Path $assets 'badges'
$front = [Drawing.Bitmap]::FromFile((Join-Path $assets 'pc1512-front.png'))
$originX = 870
$originY = 1164

function Clamp([double]$n) { [Math]::Max(0.0, [Math]::Min(1.0, $n)) }
function Blend($background, $ink, [double]$amount) {
    $a = Clamp $amount
    [Drawing.Color]::FromArgb(
        [int][Math]::Round($background.R * (1 - $a) + $ink.R * $a),
        [int][Math]::Round($background.G * (1 - $a) + $ink.G * $a),
        [int][Math]::Round($background.B * (1 - $a) + $ink.B * $a))
}
function PlateRow([int]$x, [int]$y, [int]$left, [int]$right) {
    $a = $front.GetPixel($originX + $left, $originY + $y)
    $b = $front.GetPixel($originX + $right, $originY + $y)
    Blend $a $b (($x - $left) / [double]($right - $left))
}
function NewPatch { [Drawing.Bitmap]::new(216, 76, [Drawing.Imaging.PixelFormat]::Format32bppArgb) }
function SavePatch($bitmap, [string]$name) {
    $bitmap.Save((Join-Path $badgeDir $name), [Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}
# The current front is the geometry master. Draw the alternate number at four
# times its 59 x 21 pixel size for the same crisp edges as the native 1512.
$scale = 4
if (!$SuffixOnly) {
$hi = [Drawing.Bitmap]::new(216 * $scale, 76 * $scale, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($hi)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$path = [Drawing.Drawing2D.GraphicsPath]::new()
$family = [Drawing.FontFamily]::new('Arial')
$path.AddString('1640', $family, [int][Drawing.FontStyle]::Bold, 100, [Drawing.Point]::new(0, 0), [Drawing.StringFormat]::GenericTypographic)
$bounds = $path.GetBounds()
$transform = [Drawing.Drawing2D.Matrix]::new()
$transform.Translate(-$bounds.X, -$bounds.Y)
$transform.Scale((59 * $scale) / $bounds.Width, (21 * $scale) / $bounds.Height, [Drawing.Drawing2D.MatrixOrder]::Append)
$transform.Translate(56 * $scale, 25 * $scale, [Drawing.Drawing2D.MatrixOrder]::Append)
$path.Transform($transform)
$graphics.FillPath([Drawing.Brushes]::White, $path)
$transform.Dispose(); $path.Dispose(); $family.Dispose(); $graphics.Dispose()
$numberMask = NewPatch
$graphics = [Drawing.Graphics]::FromImage($numberMask)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($hi, [Drawing.Rectangle]::new(0, 0, 216, 76))
$graphics.Dispose(); $hi.Dispose()
$numberInk = [Drawing.Color]::FromArgb(195, 194, 198)
foreach ($model in @('1512', '1640')) {
    $patch = NewPatch
    for ($y = 23; $y -le 48; $y++) {
        for ($x = 53; $x -le 118; $x++) {
            $native = $front.GetPixel($originX + $x, $originY + $y)
            $color = $native
            if ($model -eq '1640') {
                $color = PlateRow $x $y 52 121
                if ($x -ge 56 -and $x -le 114 -and $y -ge 25 -and $y -le 45) {
                    $coverage = $numberMask.GetPixel($x, $y).A / 255.0
                    $color = Blend $color $numberInk $coverage
                }
            }
            $patch.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $color.R, $color.G, $color.B))
        }
    }
    SavePatch $patch "system-$model.png"
}
$numberMask.Dispose()
}

# Match the native DD rather than redrawing it: its D shape, red texture and
# softened top/bottom edges are the reference for the alternate suffixes.
function SuffixPlate([int]$x, [int]$y) {
    if ($x -gt 170) { return $front.GetPixel($originX + $x, $originY + $y) }
    PlateRow $x $y 124 171
}
function SuffixInk([int]$y) {
    $r = 0; $g = 0; $b = 0; $count = 0
    for ($x = 128; $x -le 147; $x++) {
        $c = $front.GetPixel($originX + $x, $originY + $y)
        if ($c.R - [Math]::Max($c.G, $c.B) -gt 100) {
            $r += $c.R; $g += $c.G; $b += $c.B; $count++
        }
    }
    if ($count -eq 0) { return [Drawing.Color]::FromArgb(148, 31, 38) }
    [Drawing.Color]::FromArgb([int]($r / $count), [int]($g / $count), [int]($b / $count))
}
function SuffixMask([string]$letter, [int]$left, [int]$right) {
    $large = [Drawing.Bitmap]::new(216 * $scale, 76 * $scale, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($large)
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $family = [Drawing.FontFamily]::new('Arial')
    $path.AddString($letter, $family, [int][Drawing.FontStyle]::Bold, 100, [Drawing.Point]::new(0, 0), [Drawing.StringFormat]::GenericTypographic)
    $bounds = $path.GetBounds()
    $matrix = [Drawing.Drawing2D.Matrix]::new()
    $matrix.Translate(-$bounds.X, -$bounds.Y)
    $matrix.Scale((($right - $left + 1) * $scale) / $bounds.Width, (21 * $scale) / $bounds.Height, [Drawing.Drawing2D.MatrixOrder]::Append)
    $matrix.Translate($left * $scale, 23.75 * $scale, [Drawing.Drawing2D.MatrixOrder]::Append)
    $path.Transform($matrix)
    $g.FillPath([Drawing.Brushes]::White, $path)
    $matrix.Dispose(); $path.Dispose(); $family.Dispose(); $g.Dispose()
    $raw = NewPatch
    $g = [Drawing.Graphics]::FromImage($raw)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($large, [Drawing.Rectangle]::new(0, 0, 216, 76))
    $g.Dispose(); $large.Dispose()
    return $raw
}

$dd = NewPatch
for ($y = 23; $y -le 48; $y++) {
    for ($x = 125; $x -le 196; $x++) {
        $dd.SetPixel($x, $y, $front.GetPixel($originX + $x, $originY + $y))
    }
}
SavePatch $dd 'model-dd.png'

foreach ($model in @('sd', 'hd20')) {
    $glyphs = if ($model -eq 'sd') {
        @(@{ letter = 'S'; left = 128; right = 147 })
    } else {
        @(@{ letter = 'H'; left = 128; right = 144 }, @{ letter = '2'; left = 168; right = 180 }, @{ letter = '0'; left = 182; right = 192 })
    }
    $patch = NewPatch
    for ($y = 23; $y -le 48; $y++) {
        for ($x = 125; $x -le 196; $x++) {
            $color = if ($model -eq 'sd' -and $x -ge 150 -and $x -le 170) {
                $front.GetPixel($originX + $x, $originY + $y)
            } else { SuffixPlate $x $y }
            if ($model -eq 'hd20' -and $x -ge 148 -and $x -le 166) {
                # Move the native second D three pixels left, keeping its edge texture.
                $source = $front.GetPixel($originX + $x + 3, $originY + $y)
                $sourcePlate = PlateRow ($x + 3) $y 149 171
                $color = [Drawing.Color]::FromArgb(
                    [int][Math]::Max(0, [Math]::Min(255, $color.R + $source.R - $sourcePlate.R)),
                    [int][Math]::Max(0, [Math]::Min(255, $color.G + $source.G - $sourcePlate.G)),
                    [int][Math]::Max(0, [Math]::Min(255, $color.B + $source.B - $sourcePlate.B)))
            }
            $patch.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $color.R, $color.G, $color.B))
        }
    }
    foreach ($glyph in $glyphs) {
        $mask = SuffixMask $glyph.letter $glyph.left $glyph.right
        for ($y = 23; $y -le 48; $y++) {
            $ink = SuffixInk $y
            if ($glyph.letter -eq '2' -or $glyph.letter -eq '0') {
                # Slightly deepen the numerals to balance HD20 in the UI.
                $ink = [Drawing.Color]::FromArgb(
                    [int][Math]::Round($ink.R * 0.96),
                    [int][Math]::Round($ink.G * 0.96),
                    [int][Math]::Round($ink.B * 0.96))
            }
            for ($x = $glyph.left - 1; $x -le $glyph.right + 1; $x++) {
                $sum = 0
                for ($dy = -1; $dy -le 1; $dy++) {
                    for ($dx = -1; $dx -le 1; $dx++) {
                        $weight = (2 - [Math]::Abs($dx)) * (2 - [Math]::Abs($dy))
                        $sum += $mask.GetPixel($x + $dx, $y + $dy).A * $weight
                    }
                }
                # Match the sharpened native D, including its pale outer halo.
                # Signed coverage preserves that halo instead of blurring it away.
                $coverage = [Math]::Min(1.0, (2.4 * $mask.GetPixel($x, $y).A - 1.4 * $sum / 16.0) / 255.0)
                $plate = $patch.GetPixel($x, $y)
                if ($coverage -lt 0) {
                    # Sharpen luminance only outside the ink; complementary RGB
                    # overshoot would leave a cyan fringe around red lettering.
                    $halo = -$coverage * 70
                    $color = [Drawing.Color]::FromArgb(
                        [int][Math]::Min(255, $plate.R + $halo),
                        [int][Math]::Min(255, $plate.G + $halo),
                        [int][Math]::Min(255, $plate.B + $halo))
                } else {
                    $color = [Drawing.Color]::FromArgb(
                    [int][Math]::Max(0, [Math]::Min(255, $plate.R + ($ink.R - $plate.R) * $coverage)),
                    [int][Math]::Max(0, [Math]::Min(255, $plate.G + ($ink.G - $plate.G) * $coverage)),
                    [int][Math]::Max(0, [Math]::Min(255, $plate.B + ($ink.B - $plate.B) * $coverage)))
                }
                $patch.SetPixel($x, $y, $color)
            }
        }
        $mask.Dispose()
    }
    SavePatch $patch "model-$model.png"
}

if (!$SuffixOnly) {
$preview = $front.Clone()
$g = [Drawing.Graphics]::FromImage($preview)
$number = [Drawing.Bitmap]::FromFile((Join-Path $badgeDir 'system-1640.png'))
$g.DrawImageUnscaled($number, $originX, $originY)
$number.Dispose(); $g.Dispose()
$crop = $preview.Clone([Drawing.Rectangle]::new($originX, $originY, 216, 76), [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$crop.Save((Join-Path $badgeDir 'pc1640-dd-preview.png'), [Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose(); $preview.Dispose()
}

$comparison = [Drawing.Bitmap]::new(216 * 6, 76 * 6 * 3, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$comparisonGraphics = [Drawing.Graphics]::FromImage($comparison)
$comparisonGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$index = 0
foreach ($model in @('dd', 'sd', 'hd20')) {
    $badge = $front.Clone([Drawing.Rectangle]::new($originX, $originY, 216, 76), [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    if ($model -ne 'dd') {
        $overlay = [Drawing.Bitmap]::FromFile((Join-Path $badgeDir "model-$model.png"))
        $g = [Drawing.Graphics]::FromImage($badge)
        $g.DrawImageUnscaled($overlay, 0, 0)
        $g.Dispose(); $overlay.Dispose()
    }
    $comparisonGraphics.DrawImage($badge, [Drawing.Rectangle]::new(0, $index * 76 * 6, 216 * 6, 76 * 6), [Drawing.Rectangle]::new(0, 0, 216, 76), [Drawing.GraphicsUnit]::Pixel)
    $badge.Dispose()
    $index++
}
$comparisonGraphics.Dispose()
$comparison.Save((Join-Path $badgeDir 'model-options-preview.png'), [Drawing.Imaging.ImageFormat]::Png)
$comparison.Dispose(); $front.Dispose()
Write-Output 'Refreshed system and suffix badges for the current sharper, narrower front.'
