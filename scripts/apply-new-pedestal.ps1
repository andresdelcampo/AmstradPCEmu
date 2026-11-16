param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$RetouchedCrop,
    [Parameter(Mandatory = $true)][string]$Output
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$cabinet = [System.Drawing.Bitmap]::new($Source)
$crop = [System.Drawing.Bitmap]::new($RetouchedCrop)
try {
    if ($cabinet.Width -ne 1254 -or $cabinet.Height -ne 1254) { throw 'Unexpected cabinet dimensions.' }
    if ($crop.Width -ne 650 -or $crop.Height -ne 90) { throw 'Unexpected pedestal crop dimensions.' }
    $result = [System.Drawing.Bitmap]$cabinet.Clone()
    try {
        for ($y = 8; $y -le 82; $y++) {
            for ($x = 41; $x -le 612; $x++) {
                $result.SetPixel(300 + $x, 825 + $y, $crop.GetPixel($x, $y))
            }
        }
        $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $result.Dispose() }
}
finally {
    $crop.Dispose()
    $cabinet.Dispose()
}
