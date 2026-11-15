$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v2'
New-Item -ItemType Directory -Force $work | Out-Null
$f=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$c=$f.Clone([Drawing.Rectangle]::new(174,1006,450,180),$f.PixelFormat)
$c.Save((Join-Path $work 'target.png'))
$c.Dispose(); $f.Dispose()
