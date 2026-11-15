$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $root 'assets/front'
$sourcePath = Join-Path $root 'local/artwork/pc1640/badge-generated-native.png'
if (!(Test-Path -LiteralPath $sourcePath)) { throw "Missing generated badge source: $sourcePath. See docs/PC1640.md." }
$front = [Drawing.Bitmap]::FromFile((Join-Path $assets 'pc1512-front.png'))
$sample = [Drawing.Bitmap]::FromFile($sourcePath)
function Brightness($c) { return ($c.R + $c.G + $c.B) / 3.0 }
# Use only the generated light numeral coverage, retaining the native plate,
# red PC, suffix and housing. This follows the existing suffix badge workflow.
$peak = 1.0
for ($y = 24; $y -le 51; $y++) {
    $bg = Brightness ($sample.GetPixel(118, $y))
    for ($x = 50; $x -le 118; $x++) {
        $peak = [Math]::Max($peak, (Brightness ($sample.GetPixel($x, $y))) - $bg)
    }
}
foreach ($model in @('1512', '1640')) {
    $patch = [Drawing.Bitmap]::new(216, 76, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 24; $y -le 51; $y++) {
        $bg = $front.GetPixel(990, (1164 + $y))
        $sampleBg = Brightness ($sample.GetPixel(118, $y))
        for ($x = 50; $x -le 118; $x++) {
            $old = $front.GetPixel((870 + $x), (1164 + $y))
            $new = $old
            if ($model -eq '1640') {
                if ((Brightness $old) - (Brightness $bg) -gt 2) { $new = $bg }
                $ink = [Math]::Max(0.0, [Math]::Min(1.0, ((Brightness ($sample.GetPixel($x, $y))) - $sampleBg - 2) / ($peak - 2)))
                $new = [Drawing.Color]::FromArgb(
                    [int][Math]::Round($new.R * (1 - $ink) + 173 * $ink),
                    [int][Math]::Round($new.G * (1 - $ink) + 173 * $ink),
                    [int][Math]::Round($new.B * (1 - $ink) + 181 * $ink))
            }
            $patch.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $new.R, $new.G, $new.B))
        }
    }
    $patch.Save((Join-Path $assets "badges/system-$model.png"), [Drawing.Imaging.ImageFormat]::Png)
    if ($model -eq '1640') {
        $preview = $front.Clone()
        $g = [Drawing.Graphics]::FromImage($preview)
        $g.DrawImageUnscaled($patch, 870, 1164)
        $g.Dispose()
        $crop = $preview.Clone([Drawing.Rectangle]::new(870, 1164, 216, 76), [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $crop.Save((Join-Path $assets 'badges/pc1640-dd-preview.png'), [Drawing.Imaging.ImageFormat]::Png)
        $crop.Dispose(); $preview.Dispose()
    }
    $patch.Dispose()
}
$sample.Dispose(); $front.Dispose()
Write-Output 'Saved independent PC1512/PC1640 number overlays and PC1640 DD badge preview.'
