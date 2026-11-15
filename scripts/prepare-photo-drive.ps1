$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
$src=[Drawing.Bitmap]::FromFile('C:/Users/adelc/AppData/Local/Temp/codex-clipboard-4dde34be-facc-4d72-b619-8cedcca14ff8.png')
$crop=$src.Clone([Drawing.Rectangle]::new(110,276,1405,410),$src.PixelFormat)
$crop.Save((Join-Path $work 'real-drive-crop.png'));$crop.Dispose();$src.Dispose()
