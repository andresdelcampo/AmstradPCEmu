param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Retouch,
    [Parameter(Mandatory = $true)][string]$Output
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Smoothstep([double]$value) {
    $t = [Math]::Clamp($value, 0.0, 1.0)
    return $t * $t * (3.0 - 2.0 * $t)
}

$sourceImage = [System.Drawing.Bitmap]::new($Source)
$retouchImage = [System.Drawing.Bitmap]::new($Retouch)
try {
    if ($sourceImage.Width -ne 1254 -or $sourceImage.Height -ne 1254 -or
        $retouchImage.Width -ne 1254 -or $retouchImage.Height -ne 1254) {
        throw 'Both cabinet images must be 1254 x 1254.'
    }

    $result = [System.Drawing.Bitmap]$sourceImage.Clone()
    try {
        # Feather into the original tray at the sides and at the cabinet/tray
        # boundaries. The middle contains the full corrected shadow and stand.
        for ($y = 827; $y -le 913; $y++) {
            $vertical = (Smoothstep (($y - 827) / 10.0)) *
                        (Smoothstep ((913 - $y) / 12.0))
            for ($x = 255; $x -le 990; $x++) {
                $weight = $vertical *
                          (Smoothstep (($x - 255) / 55.0)) *
                          (Smoothstep ((990 - $x) / 55.0))
                if ($weight -le 0) { continue }
                $original = $sourceImage.GetPixel($x, $y)
                $edited = $retouchImage.GetPixel($x, $y)
                $red = [int][Math]::Round($original.R * (1 - $weight) + $edited.R * $weight)
                $green = [int][Math]::Round($original.G * (1 - $weight) + $edited.G * $weight)
                $blue = [int][Math]::Round($original.B * (1 - $weight) + $edited.B * $weight)
                $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($original.A, $red, $green, $blue))
            }
        }

        $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $result.Dispose() }
}
finally {
    $retouchImage.Dispose()
    $sourceImage.Dispose()
}
