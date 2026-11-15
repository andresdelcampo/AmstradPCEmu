param([int]$Version=10,[int]$InputVersion=9,[switch]$UpperOnly)
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$original = [System.Drawing.Bitmap]::FromFile((Join-Path $root "assets/front/pc1512-front-v$InputVersion.png"))
$generated = [System.Drawing.Bitmap]::FromFile((Join-Path $root "local/artwork/v$Version/generated-closeup.png"))
$scaled = [System.Drawing.Bitmap]::new(768,256)
$graphics = [System.Drawing.Graphics]::FromImage($scaled)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($generated,[System.Drawing.Rectangle]::new(0,0,768,256))
$graphics.Dispose()
$result = $original.Clone()
# Blend only the stand and nearby top-panel shadow. Preserve the entire monitor,
# all labels, display aperture, drives and exterior exactly as in v9.
for ($y=94; $y -lt 174; $y++) {
    for ($x=85; $x -lt 681; $x++) {
        $alpha = [Math]::Min(1.0,[Math]::Min(($x-85)/45.0,(680-$x)/45.0))
        $alpha = [Math]::Min($alpha,[Math]::Min(($y-93)/3.0,(173-$y)/14.0))
        $alpha = [Math]::Max(0.0,$alpha)
        if ($UpperOnly) {
            # Overlay the cylinder and its immediate contact shadow; retain the
            # approved v10 lower dome and rim everywhere outside this mask.
            $t=($x-381.5)/175.5
            $edge=110+15*[Math]::Sqrt([Math]::Max(0.0,1.0-$t*$t))
            $side=[Math]::Min(1.0,[Math]::Min(($x-200)/6.0,(563-$x)/6.0))
            $lower=[Math]::Min(1.0,($edge+9-$y)/7.0)
            $alpha=[Math]::Max(0.0,[Math]::Min($alpha,[Math]::Min($side,$lower)))
        }
        $old = $original.GetPixel($x+243,$y+737)
        $new = $scaled.GetPixel($x,$y)
        $red = [int][Math]::Round($old.R*(1-$alpha)+$new.R*$alpha)
        $green = [int][Math]::Round($old.G*(1-$alpha)+$new.G*$alpha)
        $blue = [int][Math]::Round($old.B*(1-$alpha)+$new.B*$alpha)
        $result.SetPixel($x+243,$y+737,[System.Drawing.Color]::FromArgb(255,$red,$green,$blue))
    }
}
$result.Save((Join-Path $root "assets/front/pc1512-front-v$Version.png"),[System.Drawing.Imaging.ImageFormat]::Png)
$preview=$result.Clone([System.Drawing.Rectangle]::new(243,737,768,256),$result.PixelFormat)
$preview.Save((Join-Path $root "assets/front/pc1512-pedestal-v$Version-detail.png"),[System.Drawing.Imaging.ImageFormat]::Png)
$changed=0
for ($y=0; $y -lt 1254; $y++) {
    for ($x=0; $x -lt 1254; $x++) {
        if ($result.GetPixel($x,$y).ToArgb() -ne $original.GetPixel($x,$y).ToArgb()) {
            if ($x -lt 328 -or $x -gt 923 -or $y -lt 831 -or $y -gt 910) { throw "Unexpected change outside pedestal: $x,$y" }
            $changed++
        }
    }
}
Write-Output "Saved v$Version, 1254x1254. $changed changed pixels; every pixel outside pedestal region is identical to v$InputVersion."
$preview.Dispose()
$result.Dispose()
$original.Dispose()
$scaled.Dispose()
$generated.Dispose()
