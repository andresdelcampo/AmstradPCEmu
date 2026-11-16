param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Reference,
    [Parameter(Mandatory = $true)][string]$Output
)

Add-Type -AssemblyName System.Drawing
$sourceImage = [System.Drawing.Bitmap]::new($Source)
$referenceImage = [System.Drawing.Bitmap]::new($Reference)
try {
    $result = [System.Drawing.Bitmap]$sourceImage.Clone()
    try {
        $offsetX = 288
        $offsetY = 830
        for ($y = 831; $y -le 919; $y++) {
            for ($x = 288; $x -le 965; $x++) {
                $horizontal = [Math]::Min(1.0, [Math]::Min($x - 288, 965 - $x) / 20.0)
                $vertical = [Math]::Min(1.0, [Math]::Min(($y - 830) / 3.0, (919 - $y) / 10.0))
                $weight = [Math]::Max(0.0, [Math]::Min($horizontal, $vertical))
                if ($weight -le 0) { continue }
                $original = $sourceImage.GetPixel($x, $y)
                $donor = $referenceImage.GetPixel($x - $offsetX, $y - $offsetY)
                $r = [int][Math]::Round($original.R * (1 - $weight) + $donor.R * $weight)
                $g = [int][Math]::Round($original.G * (1 - $weight) + $donor.G * $weight)
                $b = [int][Math]::Round($original.B * (1 - $weight) + $donor.B * $weight)
                $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($original.A, $r, $g, $b))
            }
        }
        $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $result.Dispose() }
}
finally {
    $referenceImage.Dispose()
    $sourceImage.Dispose()
}
