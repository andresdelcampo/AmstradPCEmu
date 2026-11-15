$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
$src=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/drives/masters/closed-clean.png'))
$crop=$src.Clone([Drawing.Rectangle]::new(720,300,180,80),$src.PixelFormat)
$crop.Save((Join-Path $work 'shadow-transition-target.png'));$crop.Dispose();$src.Dispose()
