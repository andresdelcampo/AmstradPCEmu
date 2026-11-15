param([string]$InputPath='')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
$output=Join-Path $root 'assets/front/drives/masters/closed-clean.png'
$ownership=Get-Content (Join-Path $root 'assets/front/drives/masters/masters.json') -Raw | ConvertFrom-Json
if($ownership.closed_geometry_source -like '*manually corrected*'){throw 'The user replaced closed-clean.png manually. Its historical shadow retouch must not overwrite it.'}
$before=Join-Path $work 'closed-before-shadow.png'
if($InputPath){Copy-Item -LiteralPath $InputPath -Destination $before -Force}
elseif(!(Test-Path $before)){Copy-Item -LiteralPath $output -Destination $before}
$base=[Drawing.Bitmap]::FromFile($before)
$gen=[Drawing.Bitmap]::FromFile((Join-Path $work 'shadow-transition-generated.png'))
$sample=[Drawing.Bitmap]::new(180,80)
$g=[Drawing.Graphics]::FromImage($sample);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($gen,[Drawing.Rectangle]::new(0,0,180,80));$g.Dispose();$gen.Dispose()
$result=$base.Clone();$changed=0
for($y=321;$y -le 352;$y++){for($x=762;$x -le 832;$x++){
    $radius=[Math]::Sqrt([Math]::Pow(($x-797)/35.0,2)+[Math]::Pow(($y-336)/16.0,2))
    if($radius -ge 1){continue}
    $old=$base.GetPixel($x,$y);$new=$sample.GetPixel(($x-720),($y-300))
    # Preserve every black slot pixel and never paint new black geometry.
    if([Math]::Max($old.R,[Math]::Max($old.G,$old.B)) -lt 32 -or [Math]::Max($new.R,[Math]::Max($new.G,$new.B)) -lt 32){continue}
    $a=[Math]::Min(1,(1-$radius)*2)
    $a=$a*$a*(3-2*$a)
    # This is a tiny tonal retouch: retain the original texture and cap each
    # channel correction, so the generated light field cannot add a blotch.
    $dr=[Math]::Max(-4,[Math]::Min(4,$new.R-$old.R))
    $dg=[Math]::Max(-4,[Math]::Min(4,$new.G-$old.G))
    $db=[Math]::Max(-4,[Math]::Min(4,$new.B-$old.B))
    $c=[Drawing.Color]::FromArgb($old.A,[int][Math]::Round($old.R+$dr*$a),[int][Math]::Round($old.G+$dg*$a),[int][Math]::Round($old.B+$db*$a))
    $result.SetPixel($x,$y,$c)
    if($old.ToArgb() -ne $c.ToArgb()){$changed++}
}}
# Verify the entire remainder of the approved closed master is untouched.
for($y=0;$y -lt $base.Height;$y++){for($x=0;$x -lt $base.Width;$x++){
    $o=$base.GetPixel($x,$y);$n=$result.GetPixel($x,$y)
    $outside=($x -lt 762 -or $x -gt 832 -or $y -lt 321 -or $y -gt 352)
    $slot=([Math]::Max($o.R,[Math]::Max($o.G,$o.B)) -lt 32)
    if(($outside -or $slot) -and $o.ToArgb() -ne $n.ToArgb()){throw 'Protected pixel changed'}
}}
$result.Save($output)
$sheet=[Drawing.Bitmap]::new(900,240);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(28,29,32))
$font=[Drawing.Font]::new('Segoe UI',12)
$g.DrawString('Before',$font,[Drawing.Brushes]::White,10,4);$g.DrawString('Small shadow correction',$font,[Drawing.Brushes]::White,460,4)
$g.DrawImage($base,[Drawing.Rectangle]::new(0,30,450,200),[Drawing.Rectangle]::new(720,300,180,80),[Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($result,[Drawing.Rectangle]::new(450,30,450,200),[Drawing.Rectangle]::new(720,300,180,80),[Drawing.GraphicsUnit]::Pixel)
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $work 'shadow-transition-before-after.png'))
$sheet.Dispose();$base.Dispose();$result.Dispose();$sample.Dispose()
Write-Output "Retouched $changed shadow pixels; all pixels outside 71x32 bounds and every black slot pixel verified unchanged."
