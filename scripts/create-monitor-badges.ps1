$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$frontPath = Join-Path $root 'assets/front/pc1512-front.png'
$badgeDir = Join-Path $root 'assets/front/badges'
$front = [Drawing.Bitmap]::FromFile($frontPath)
$scale = 4

foreach ($entry in @(
    @{ suffix = 'MD'; file = 'monitor-md.png'; left = 75; width = 43 },
    @{ suffix = 'CD'; file = 'monitor-cd.png'; left = 75; width = 43 },
    @{ suffix = 'ECD'; file = 'monitor-ecd.png'; left = 73; width = 48 }
)) {
    # Draw the lettering at four times native resolution, then reduce it to
    # match the soft photographed type on the existing PC-CM badge.
    $hi = [Drawing.Bitmap]::new(140 * $scale, 60 * $scale, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($hi)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $family = [Drawing.FontFamily]::new('Arial')
    $format = [Drawing.StringFormat]::GenericTypographic
    $path.AddString($entry.suffix, $family, [int][Drawing.FontStyle]::Bold, 100, [Drawing.Point]::new(0, 0), $format)
    $bounds = $path.GetBounds()
    $transform = [Drawing.Drawing2D.Matrix]::new()
    $transform.Translate(-$bounds.X, -$bounds.Y)
    $transform.Scale(($entry.width * $scale) / $bounds.Width, (20 * $scale) / $bounds.Height, [Drawing.Drawing2D.MatrixOrder]::Append)
    $transform.Translate($entry.left * $scale, 18 * $scale, [Drawing.Drawing2D.MatrixOrder]::Append)
    $path.Transform($transform)
    $graphics.FillPath([Drawing.Brushes]::White, $path)
    $transform.Dispose(); $path.Dispose(); $family.Dispose(); $graphics.Dispose()

    $mask = [Drawing.Bitmap]::new(140, 60, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($mask)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($hi, [Drawing.Rectangle]::new(0, 0, 140, 60))
    $graphics.Dispose(); $hi.Dispose()

    $patch = [Drawing.Bitmap]::new(140, 60, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 15; $y -le 41; $y++) {
        $left = $front.GetPixel(923 + 73, 743 + $y)
        $right = $front.GetPixel(923 + 121, 743 + $y)
        for ($x = 74; $x -le 120; $x++) {
            $fraction = ($x - 73) / 48.0
            $coverage = 0
            for ($dy = -1; $dy -le 1; $dy++) {
                for ($dx = -1; $dx -le 1; $dx++) {
                    $weight = (2 - [Math]::Abs($dx)) * (2 - [Math]::Abs($dy))
                    $coverage += $weight * $mask.GetPixel($x + $dx, $y + $dy).A
                }
            }
            $ink = $coverage / (16.0 * 255.0)
            $r = [int][Math]::Round(($left.R * (1 - $fraction) + $right.R * $fraction) * (1 - $ink) + 175 * $ink)
            $g = [int][Math]::Round(($left.G * (1 - $fraction) + $right.G * $fraction) * (1 - $ink) + 175 * $ink)
            $b = [int][Math]::Round(($left.B * (1 - $fraction) + $right.B * $fraction) * (1 - $ink) + 184 * $ink)
            $patch.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $r, $g, $b))
        }
    }
    $patch.Save((Join-Path $badgeDir $entry.file), [Drawing.Imaging.ImageFormat]::Png)
    $patch.Dispose(); $mask.Dispose()
}
$front.Dispose()

$front = [Drawing.Bitmap]::FromFile($frontPath)
$sheet = [Drawing.Bitmap]::new(1050, 630)
$g = [Drawing.Graphics]::FromImage($sheet)
$g.Clear([Drawing.Color]::FromArgb(28, 29, 32))
$font = [Drawing.Font]::new('Segoe UI', 13)
$labels = @('CM', 'MM', 'MD', 'CD', 'ECD')
for ($i = 0; $i -lt $labels.Count; $i++) {
    $label = $labels[$i]
    $badge = [Drawing.Bitmap]::new(140, 60)
    $bg = [Drawing.Graphics]::FromImage($badge)
    $bg.DrawImage($front, [Drawing.Rectangle]::new(0, 0, 140, 60), [Drawing.Rectangle]::new(923, 743, 140, 60), [Drawing.GraphicsUnit]::Pixel)
    if ($label -ne 'CM') {
        $overlay = [Drawing.Bitmap]::FromFile((Join-Path $badgeDir ('monitor-' + $label.ToLowerInvariant() + '.png')))
        $bg.DrawImageUnscaled($overlay, 0, 0)
        $overlay.Dispose()
    }
    $bg.Dispose()
    $x = ($i % 2) * 525
    $y = [int][Math]::Floor($i / 2) * 210
    $g.DrawString($label, $font, [Drawing.Brushes]::White, ($x + 8), ($y + 3))
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($badge, [Drawing.Rectangle]::new(($x + 8), ($y + 28), 420, 180))
    $badge.Dispose()
}
$g.Dispose(); $font.Dispose(); $front.Dispose()
$sheet.Save((Join-Path $badgeDir 'monitor-options-preview.png'), [Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
