param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Output,
    [string]$Cabinet
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourceImage = [System.Drawing.Bitmap]::new($Source)
$cabinetImage = if ($Cabinet) { [System.Drawing.Bitmap]::new($Cabinet) } else { $null }
try {
    if ($sourceImage.Width -ne 650 -or $sourceImage.Height -ne 90) { throw 'Unexpected pedestal crop dimensions.' }
    $result = [System.Drawing.Bitmap]$sourceImage.Clone()
    try {
        for ($y = 8; $y -le 82; $y++) {
            $leftOutside = if ($cabinetImage) { $cabinetImage.GetPixel(340, 825 + $y) } else { $sourceImage.GetPixel(40, $y) }
            $rightOutside = if ($cabinetImage) { $cabinetImage.GetPixel(913, 825 + $y) } else { $sourceImage.GetPixel(613, $y) }
            $leftInside = $sourceImage.GetPixel(41, $y)
            $rightInside = $sourceImage.GetPixel(612, $y)
            for ($x = 41; $x -le 612; $x++) {
                $pixel = $sourceImage.GetPixel($x, $y)
                $brightness = ($pixel.R + $pixel.G + $pixel.B) / 3.0
                $toneWeight = [Math]::Max(0.0, [Math]::Min(1.0, ($brightness - 50.0) / 70.0))

                # A modest cabinet-colored shift on the original pixels keeps
                # the cylinder's exact straight sides and its original rim.
                $domeWeight = 0.0
                if ($x -ge 85 -and $x -le 560) {
                    $normalizedX = ($x - 322.5) / 237.5
                    $rimY = 66.0 - 27.0 * $normalizedX * $normalizedX
                    $edgeX = [Math]::Max(0.0, [Math]::Min(1.0, [Math]::Min(($x - 85) / 16.0, (560 - $x) / 16.0)))
                    $edgeY = [Math]::Max(0.0, [Math]::Min(1.0, ($rimY + 3.0 - $y) / 7.0))
                    $domeWeight = $edgeX * $edgeY
                }
                $baseRed = $pixel.R - $toneWeight * (3.0 + $domeWeight)
                $baseGreen = $pixel.G - $toneWeight * 2.0
                $baseBlue = $pixel.B + $toneWeight * (-1.0 + 2.0 * $domeWeight)

                # Match the exposed tray precisely at the pasted rectangle's
                # left and right boundaries, then let the correction end before
                # reaching either side of the cylinder.
                $leftWeight = 0.0
                if ($x -le 84) {
                    $t = ($x - 41) / 43.0
                    $leftWeight = 0.5 + 0.5 * [Math]::Cos([Math]::PI * $t)
                }
                $rightWeight = 0.0
                if ($x -ge 569) {
                    $t = (612 - $x) / 43.0
                    $rightWeight = 0.5 + 0.5 * [Math]::Cos([Math]::PI * $t)
                }
                $leftBrightness = ($leftInside.R + $leftInside.G + $leftInside.B) / 3.0
                $rightBrightness = ($rightInside.R + $rightInside.G + $rightInside.B) / 3.0
                $leftTone = [Math]::Max(0.0, [Math]::Min(1.0, ($leftBrightness - 50.0) / 70.0))
                $rightTone = [Math]::Max(0.0, [Math]::Min(1.0, ($rightBrightness - 50.0) / 70.0))
                $leftDelta = @(
                    ($leftOutside.R - ($leftInside.R - 3.0 * $leftTone)),
                    ($leftOutside.G - ($leftInside.G - 2.0 * $leftTone)),
                    ($leftOutside.B - ($leftInside.B - 1.0 * $leftTone))
                )
                $rightDelta = @(
                    ($rightOutside.R - ($rightInside.R - 3.0 * $rightTone)),
                    ($rightOutside.G - ($rightInside.G - 2.0 * $rightTone)),
                    ($rightOutside.B - ($rightInside.B - 1.0 * $rightTone))
                )
                $red = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($baseRed + $leftWeight * $leftDelta[0] + $rightWeight * $rightDelta[0])))
                $green = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($baseGreen + $leftWeight * $leftDelta[1] + $rightWeight * $rightDelta[1])))
                $blue = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($baseBlue + $leftWeight * $leftDelta[2] + $rightWeight * $rightDelta[2])))
                $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $red, $green, $blue))
            }
        }
        $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $result.Dispose() }
}
finally {
    if ($cabinetImage) { $cabinetImage.Dispose() }
    $sourceImage.Dispose()
}
