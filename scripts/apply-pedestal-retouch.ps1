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
    if ($crop.Width -ne 595 -or $crop.Height -ne 76) { throw 'Unexpected pedestal crop dimensions.' }
    $result = [System.Drawing.Bitmap]$cabinet.Clone()
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($result)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.DrawImageUnscaled($crop, 328, 831)
        }
        finally { $graphics.Dispose() }
        $result.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $result.Dispose() }
}
finally {
    $crop.Dispose()
    $cabinet.Dispose()
}
