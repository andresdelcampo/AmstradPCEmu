param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$LightingReference,
    [Parameter(Mandatory = $true)][string]$Output
)

Add-Type -AssemblyName System.Drawing

$sourceImage = [System.Drawing.Bitmap]::new($Source)
$referenceImage = [System.Drawing.Bitmap]::new($LightingReference)
try {
    if ($sourceImage.Width -ne $referenceImage.Width -or $sourceImage.Height -ne $referenceImage.Height) {
        throw 'Source and lighting reference must have the same dimensions.'
    }

    # The hand-collaged light patch in the monitor pedestal. All pixels outside
    # this area are copied directly from the source image.
    $left = 344
    $top = 832
    $right = 905
    $bottom = 907
    $width = $right - $left + 1
    $height = $bottom - $top + 1
    $stride = $width + 1
    $count = $stride * ($height + 1)
    $red = [double[]]::new($count)
    $green = [double[]]::new($count)
    $blue = [double[]]::new($count)

    # Build integral images of the reference's color change. Averaging these
    # changes transfers the broad lighting while retaining the source edges.
    for ($y = 1; $y -le $height; $y++) {
        $rowRed = 0.0
        $rowGreen = 0.0
        $rowBlue = 0.0
        for ($x = 1; $x -le $width; $x++) {
            $original = $sourceImage.GetPixel($left + $x - 1, $top + $y - 1)
            $reference = $referenceImage.GetPixel($left + $x - 1, $top + $y - 1)
            $rowRed += $reference.R - $original.R
            $rowGreen += $reference.G - $original.G
            $rowBlue += $reference.B - $original.B
            $i = $y * $stride + $x
            $above = ($y - 1) * $stride + $x
            $red[$i] = $red[$above] + $rowRed
            $green[$i] = $green[$above] + $rowGreen
            $blue[$i] = $blue[$above] + $rowBlue
        }
    }

    $result = [System.Drawing.Bitmap]$sourceImage.Clone()
    try {
        $radius = 12
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $x0 = [Math]::Max(0, $x - $radius)
                $y0 = [Math]::Max(0, $y - $radius)
                $x1 = [Math]::Min($width, $x + $radius + 1)
                $y1 = [Math]::Min($height, $y + $radius + 1)
                $area = ($x1 - $x0) * ($y1 - $y0)
                $a = $y1 * $stride + $x1
                $b = $y0 * $stride + $x1
                $c = $y1 * $stride + $x0
                $d = $y0 * $stride + $x0
                $original = $sourceImage.GetPixel($left + $x, $top + $y)
                $r = [Math]::Clamp([int][Math]::Round($original.R + ($red[$a] - $red[$b] - $red[$c] + $red[$d]) / $area), 0, 255)
                $g = [Math]::Clamp([int][Math]::Round($original.G + ($green[$a] - $green[$b] - $green[$c] + $green[$d]) / $area), 0, 255)
                $bValue = [Math]::Clamp([int][Math]::Round($original.B + ($blue[$a] - $blue[$b] - $blue[$c] + $blue[$d]) / $area), 0, 255)
                $result.SetPixel($left + $x, $top + $y, [System.Drawing.Color]::FromArgb($original.A, $r, $g, $bValue))
            }
        }

        # Bring each vertical edge of the former rectangle into the adjacent
        # source lighting, tapering the correction before it reaches the stand.
        $edgeWidth = 55
        for ($y = $top; $y -le $bottom; $y++) {
            $leftOutside = $sourceImage.GetPixel($left - 1, $y)
            $rightOutside = $sourceImage.GetPixel($right + 1, $y)
            $leftInside = $result.GetPixel($left, $y)
            $rightInside = $result.GetPixel($right, $y)
            for ($offset = 0; $offset -lt $edgeWidth; $offset++) {
                $weight = [Math]::Pow(1.0 - $offset / $edgeWidth, 2)
                foreach ($side in @('left', 'right')) {
                    if ($side -eq 'left') {
                        $px = $left + $offset
                        $deltaR = $leftOutside.R - $leftInside.R
                        $deltaG = $leftOutside.G - $leftInside.G
                        $deltaB = $leftOutside.B - $leftInside.B
                    }
                    else {
                        $px = $right - $offset
                        $deltaR = $rightOutside.R - $rightInside.R
                        $deltaG = $rightOutside.G - $rightInside.G
                        $deltaB = $rightOutside.B - $rightInside.B
                    }
                    $current = $result.GetPixel($px, $y)
                    $r = [Math]::Clamp([int][Math]::Round($current.R + $deltaR * $weight), 0, 255)
                    $g = [Math]::Clamp([int][Math]::Round($current.G + $deltaG * $weight), 0, 255)
                    $bValue = [Math]::Clamp([int][Math]::Round($current.B + $deltaB * $weight), 0, 255)
                    $result.SetPixel($px, $y, [System.Drawing.Color]::FromArgb($current.A, $r, $g, $bValue))
                }
            }
        }

        $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $result.Dispose()
    }
}
finally {
    $referenceImage.Dispose()
    $sourceImage.Dispose()
}
