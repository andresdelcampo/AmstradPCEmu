param(
    [Parameter(Mandatory = $true)][string]$Generated,
    [Parameter(Mandatory = $true)][string]$Collage,
    [Parameter(Mandatory = $true)][string]$Output,
    [int]$BoundaryLeft = 15,
    [int]$BoundaryRight = 579,
    [int]$BoundaryTop = 2,
    [int]$BoundaryBottom = 68
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$generatedImage = [System.Drawing.Bitmap]::new($Generated)
$collageImage = [System.Drawing.Bitmap]::new($Collage)
try {
    if ($BoundaryLeft -lt 0 -or $BoundaryRight -ge $collageImage.Width -or $BoundaryTop -lt 0 -or $BoundaryBottom -ge $collageImage.Height) {
        throw 'Retouch boundary falls outside the collage.'
    }

    # The generated panorama has letterboxing. Detect the photographed strip
    # from the center column so the export is restored to the source aspect.
    $centerX = [int]($generatedImage.Width / 2)
    $first = 0
    while ($first -lt $generatedImage.Height -and $generatedImage.GetPixel($centerX, $first).GetBrightness() -lt 0.04) { $first++ }
    $last = $generatedImage.Height - 1
    while ($last -gt $first -and $generatedImage.GetPixel($centerX, $last).GetBrightness() -lt 0.04) { $last-- }
    Write-Output "Photo strip rows: $first..$last"

    $generatedStrip = [System.Drawing.Bitmap]::new($collageImage.Width, $collageImage.Height)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($generatedStrip)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($generatedImage, [System.Drawing.Rectangle]::new(0, 0, $generatedStrip.Width, $generatedStrip.Height), [System.Drawing.Rectangle]::new(0, $first, $generatedImage.Width, $last - $first + 1), [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally { $graphics.Dispose() }
        # Use the collage's untouched perimeter as a fixed boundary. A smooth
        # narrow color correction carries its lighting into the generated center and
        # removes the rectangular paste without changing the side pixels.
        $left = $BoundaryLeft
        $right = $BoundaryRight
        $top = $BoundaryTop
        $bottom = $BoundaryBottom
        $result = [System.Drawing.Bitmap]$collageImage.Clone()
        try {
            $topLeftOriginal = $collageImage.GetPixel($left, $top)
            $topLeftGenerated = $generatedStrip.GetPixel($left, $top)
            $topRightOriginal = $collageImage.GetPixel($right, $top)
            $topRightGenerated = $generatedStrip.GetPixel($right, $top)
            $bottomLeftOriginal = $collageImage.GetPixel($left, $bottom)
            $bottomLeftGenerated = $generatedStrip.GetPixel($left, $bottom)
            $bottomRightOriginal = $collageImage.GetPixel($right, $bottom)
            $bottomRightGenerated = $generatedStrip.GetPixel($right, $bottom)
            $topLeftDelta = @(($topLeftOriginal.R - $topLeftGenerated.R), ($topLeftOriginal.G - $topLeftGenerated.G), ($topLeftOriginal.B - $topLeftGenerated.B))
            $topRightDelta = @(($topRightOriginal.R - $topRightGenerated.R), ($topRightOriginal.G - $topRightGenerated.G), ($topRightOriginal.B - $topRightGenerated.B))
            $bottomLeftDelta = @(($bottomLeftOriginal.R - $bottomLeftGenerated.R), ($bottomLeftOriginal.G - $bottomLeftGenerated.G), ($bottomLeftOriginal.B - $bottomLeftGenerated.B))
            $bottomRightDelta = @(($bottomRightOriginal.R - $bottomRightGenerated.R), ($bottomRightOriginal.G - $bottomRightGenerated.G), ($bottomRightOriginal.B - $bottomRightGenerated.B))
            for ($y = $top + 1; $y -lt $bottom; $y++) {
                $leftOriginal = $collageImage.GetPixel($left, $y)
                $leftGenerated = $generatedStrip.GetPixel($left, $y)
                $rightOriginal = $collageImage.GetPixel($right, $y)
                $rightGenerated = $generatedStrip.GetPixel($right, $y)
                $sideLeft = @(($leftOriginal.R - $leftGenerated.R), ($leftOriginal.G - $leftGenerated.G), ($leftOriginal.B - $leftGenerated.B))
                $sideRight = @(($rightOriginal.R - $rightGenerated.R), ($rightOriginal.G - $rightGenerated.G), ($rightOriginal.B - $rightGenerated.B))
                for ($x = $left + 1; $x -lt $right; $x++) {
                    $leftWeight = [Math]::Exp(-($x - $left) / 42.0)
                    $rightWeight = [Math]::Exp(-($right - $x) / 42.0)
                    $topWeight = [Math]::Exp(-($y - $top) / 5.0)
                    $bottomWeight = [Math]::Exp(-($bottom - $y) / 8.0)
                    $topOriginal = $collageImage.GetPixel($x, $top)
                    $topGenerated = $generatedStrip.GetPixel($x, $top)
                    $bottomOriginal = $collageImage.GetPixel($x, $bottom)
                    $bottomGenerated = $generatedStrip.GetPixel($x, $bottom)
                    $topDelta = @(($topOriginal.R - $topGenerated.R), ($topOriginal.G - $topGenerated.G), ($topOriginal.B - $topGenerated.B))
                    $bottomDelta = @(($bottomOriginal.R - $bottomGenerated.R), ($bottomOriginal.G - $bottomGenerated.G), ($bottomOriginal.B - $bottomGenerated.B))
                    $generatedPixel = $generatedStrip.GetPixel($x, $y)
                    $channels = @($generatedPixel.R, $generatedPixel.G, $generatedPixel.B)
                    for ($channel = 0; $channel -lt 3; $channel++) {
                        $sideCorrection = $leftWeight * $sideLeft[$channel] + $rightWeight * $sideRight[$channel]
                        $topResidual = $topDelta[$channel] - $leftWeight * $topLeftDelta[$channel] - $rightWeight * $topRightDelta[$channel]
                        $bottomResidual = $bottomDelta[$channel] - $leftWeight * $bottomLeftDelta[$channel] - $rightWeight * $bottomRightDelta[$channel]
                        $channels[$channel] = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($channels[$channel] + $sideCorrection + $topWeight * $topResidual + $bottomWeight * $bottomResidual)))
                    }
                    $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($channels[0], $channels[1], $channels[2]))
                }
            }
            $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $result.Dispose() }
    }
    finally { $generatedStrip.Dispose() }
}
finally {
    $collageImage.Dispose()
    $generatedImage.Dispose()
}
