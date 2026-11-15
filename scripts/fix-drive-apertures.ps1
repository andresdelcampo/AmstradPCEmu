$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$path=Join-Path $root 'assets/front/pc1512-front.png'
$current=[Drawing.Bitmap]::FromFile($path)
$before=[Drawing.Bitmap]::FromFile((Join-Path $root 'local/artwork/drive-states/before-aperture-fix/pc1512-front.png'))
$gen=[Drawing.Bitmap]::FromFile((Join-Path $root 'local/artwork/drive-states/generated/aperture-no-rail.png'))
$sample=[Drawing.Bitmap]::new(450,150)
$g=[Drawing.Graphics]::FromImage($sample)
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($gen,[Drawing.Rectangle]::new(0,0,450,150));$g.Dispose();$gen.Dispose()
$result=$current.Clone()
foreach($region in @(@(348,477),@(806,931))) {
    $left=$region[0];$right=$region[1]
    for($y=1076;$y -le 1097;$y++) {
        for($x=$left;$x -le $right;$x++) {
            $alpha=[Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min([Math]::Min(($x-$left)/1.5,($right-$x)/1.5),[Math]::Min(($y-1075)/1.0,(1098-$y)/9.0))))
            if($alpha -le 0){continue}
            $sx=[int][Math]::Round(174+($x-$left)*129.0/($right-$left))
            $new=$sample.GetPixel($sx,($y-1006))
            $old=$before.GetPixel($x,$y)
            $result.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,
                [int][Math]::Round($old.R*(1-$alpha)+$new.R*$alpha),
                [int][Math]::Round($old.G*(1-$alpha)+$new.G*$alpha),
                [int][Math]::Round($old.B*(1-$alpha)+$new.B*$alpha)))
        }
    }
}
$result.Save((Join-Path $root 'assets/front/pc1512-front-v19.png'),[Drawing.Imaging.ImageFormat]::Png)
$result.Dispose();$current.Dispose();$before.Dispose();$sample.Dispose()
Copy-Item -LiteralPath (Join-Path $root 'assets/front/pc1512-front-v19.png') -Destination $path
Write-Output 'Removed only the false rail in both central finger wells; original retained in before-aperture-fix and v18.'
