param([switch]$Final)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
New-Item -ItemType Directory -Force $work | Out-Null
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$patch=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/drives/drive-a-open-empty.png'))
$g=[Drawing.Graphics]::FromImage($front);$g.DrawImageUnscaled($patch,174,1006);$g.Dispose();$patch.Dispose()
$crop=$front.Clone([Drawing.Rectangle]::new(174,1006,450,180),$front.PixelFormat)
if(!$Final){$crop.Save((Join-Path $work 'target-open.png'))};$front.Dispose()
$sheet=[Drawing.Bitmap]::new(1400,980)
$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(32,33,36))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=[Drawing.Font]::new('Segoe UI',17)
$refs=@('C:/Users/adelc/AppData/Local/Temp/codex-clipboard-46dda963-0ef1-413a-9307-6b7f83af5d06.png','C:/Users/adelc/AppData/Local/Temp/codex-clipboard-98df9afa-0140-42bd-86c8-939fd124d5e4.png')
$rects=@([Drawing.Rectangle]::new(65,40,165,92),[Drawing.Rectangle]::new(83,12,76,53))
for($i=0;$i -lt 2;$i++){
    $ref=[Drawing.Bitmap]::FromFile($refs[$i]);$detail=$crop.Clone($rects[$i],$crop.PixelFormat)
    $g.DrawString('REAL - '+@('lower recess','left of pivot')[$i],$font,[Drawing.Brushes]::White,15,($i*490+10))
    $label=if($Final){'CORRECTED PHOTO-BASED'}else{'PREVIOUS GENERATED'}
    $g.DrawString($label,$font,[Drawing.Brushes]::White,715,($i*490+10))
    foreach($col in @(0,1)){
        $src=if($col -eq 0){$ref}else{$detail}
        $scale=[Math]::Min(670.0/$src.Width,425.0/$src.Height)
        $w=[int]($src.Width*$scale);$h=[int]($src.Height*$scale)
        $g.DrawImage($src,[Drawing.Rectangle]::new(($col*700+15),($i*490+50),$w,$h))
    }
    $ref.Dispose();$detail.Dispose()
}
$g.Dispose();$font.Dispose();$crop.Dispose()
$name=if($Final){'real-vs-after.png'}else{'real-vs-before.png'}
$sheet.Save((Join-Path $work $name));$sheet.Dispose()
