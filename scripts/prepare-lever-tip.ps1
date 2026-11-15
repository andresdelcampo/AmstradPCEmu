$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$patch=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/drives/drive-a-closed-black.png'))
$g=[Drawing.Graphics]::FromImage($front);$g.DrawImageUnscaled($patch,174,1006);$g.Dispose();$patch.Dispose()
$full=$front.Clone([Drawing.Rectangle]::new(174,1006,450,180),$front.PixelFormat)
$full.Save((Join-Path $work 'closed-depth-target.png'));$full.Dispose()
$crop=[Drawing.Bitmap]::new(480,360);$g=[Drawing.Graphics]::FromImage($crop)
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($front,[Drawing.Rectangle]::new(0,0,480,360),[Drawing.Rectangle]::new(254,1102,48,36),[Drawing.GraphicsUnit]::Pixel)
$g.Dispose();$front.Dispose();$crop.Save((Join-Path $work 'tip-target.png'));$crop.Dispose()
