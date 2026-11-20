$ErrorActionPreference='Stop'
if ((Get-Content (Join-Path $PSScriptRoot '../assets/front/drives/placement.json') -Raw | ConvertFrom-Json).geometry_revision -ge 4) {throw 'Use apply-closed-drive-master.ps1; this historical assembler would overwrite current artwork.'}
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
$out=Join-Path $root 'assets/front/drives'
New-Item -ItemType Directory -Force (Join-Path $out 'previews') | Out-Null  # comparison sheets, not shipped
$backup=Join-Path $work 'before'
New-Item -ItemType Directory -Force $backup | Out-Null
if (!(Test-Path (Join-Path $backup 'drive-a-open-empty.png'))) { Get-ChildItem $out -File | Copy-Item -Destination $backup }
$original=Join-Path $root 'local/artwork/drive-geometry-v2/before'
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$samples=@{}
$depth=[Drawing.Bitmap]::new(450,180)
$depthSrc=[Drawing.Bitmap]::FromFile((Join-Path $work 'closed-depth.png'))
$dg=[Drawing.Graphics]::FromImage($depth);$dg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$dg.DrawImage($depthSrc,[Drawing.Rectangle]::new(0,0,450,180));$dg.Dispose();$depthSrc.Dispose()
$depthMask=[Drawing.Bitmap]::new(450,180)
$dg=[Drawing.Graphics]::FromImage($depthMask);$dg.Clear([Drawing.Color]::Black)
$dg.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
$outline=[Drawing.PointF[]]@([Drawing.PointF]::new(114,14),[Drawing.PointF]::new(125,17),[Drawing.PointF]::new(130,25),[Drawing.PointF]::new(128,34),[Drawing.PointF]::new(110,59),[Drawing.PointF]::new(109,111),[Drawing.PointF]::new(106,115),[Drawing.PointF]::new(91,115),[Drawing.PointF]::new(89,111),[Drawing.PointF]::new(89,57),[Drawing.PointF]::new(104,24))
$dg.FillPolygon([Drawing.Brushes]::White,$outline)
$dg.Dispose()
foreach($state in @('open','closed')) {
    $src=[Drawing.Bitmap]::FromFile((Join-Path $work ('photo-'+$state+'.png')))
    $sample=[Drawing.Bitmap]::new(450,180)
    $g=[Drawing.Graphics]::FromImage($sample)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    # Normalize photographed face to the existing bezel and slit. Keep the
    # photographed horizontal spacing; no local horizontal stretching.
    $scaleX=$src.Width/2170.0;$scaleY=$src.Height/725.0
    $g.DrawImage($src,[Drawing.RectangleF]::new(12,12,425,54),[Drawing.RectangleF]::new([single](24*$scaleX),[single](55*$scaleY),[single](2130*$scaleX),[single](251*$scaleY)),[Drawing.GraphicsUnit]::Pixel)
    $g.DrawImage($src,[Drawing.RectangleF]::new(12,66,425,60),[Drawing.RectangleF]::new([single](24*$scaleX),[single](306*$scaleY),[single](2130*$scaleX),[single](354*$scaleY)),[Drawing.GraphicsUnit]::Pixel)
    $g.Dispose();$src.Dispose();$samples[$state]=$sample
    $sample.Save((Join-Path $work ('registered-'+$state+'.png')))
}
$states=@('open-empty','closed-black','closed-yellow','closed-green','closed-blue','closed-red')
$manifest=Get-Content (Join-Path $out 'placement.json') -Raw | ConvertFrom-Json
$sheet=[Drawing.Bitmap]::new(940,1020);$sg=[Drawing.Graphics]::FromImage($sheet)
$sg.Clear([Drawing.Color]::FromArgb(28,29,32));$font=[Drawing.Font]::new('Segoe UI',11)
$row=0
foreach($state in $states){foreach($drive in $manifest.drives){
    $prior=[Drawing.Bitmap]::FromFile((Join-Path $backup ($drive.id+'-'+$state+'.png')))
    $diskSource=[Drawing.Bitmap]::FromFile((Join-Path $original ($drive.id+'-'+$state+'.png')))
    $clean=[Drawing.Bitmap]::FromFile((Join-Path $original ($drive.id+'-open-empty.png')))
    $patch=$prior.Clone();$isOpen=$state -eq 'open-empty'
    $mask=$null
    if($state -eq 'closed-black'){
        $ms=[Drawing.Bitmap]::FromFile((Join-Path $original ($drive.id+'-disk-color-mask.png')))
        $mask=$ms.Clone();$ms.Dispose()
    }
    $donor=$front.GetPixel(($drive.x+55),($drive.y+100));$photoDonor=$samples['open'].GetPixel(55,100)
    for($y=12;$y -lt 146;$y++){for($x=64;$x -lt 230;$x++){
        $base=$front.GetPixel(($drive.x+$x),($drive.y+$y));$o=$clean.GetPixel($x,$y);$oa=$o.A/255.0
        $r=$base.R*(1-$oa)+$o.R*$oa;$g=$base.G*(1-$oa)+$o.G*$oa;$b=$base.B*(1-$oa)+$o.B*$oa
        $source=$samples['open']
        if(!$isOpen -and ($y -lt 74 -or ($x -ge 85 -and $x -le 114))){$source=$samples['closed']}
        if(!$isOpen -and $y -ge 110){$source=$samples['open']}
        $sy=[Math]::Min(125,$y)
        # Join the photographic pocket divider and upper shelf end to the
        # protected cabinet's existing boundaries, without moving the pivot.
        $sx=$x
        if($y -gt 73 -and $x -ge 90){$sx=[int][Math]::Round(90+($x-90)*80.0/85.0)}
        if($y -lt 62 -and $x -ge 115){$sx=[int][Math]::Round(115+($x-115)*95.0/102.0)}
        $raw=$source.GetPixel($sx,$sy)
        $cr=[Math]::Max(0,[Math]::Min(255,$raw.R+$donor.R-$photoDonor.R))
        $cg=[Math]::Max(0,[Math]::Min(255,$raw.G+$donor.G-$photoDonor.G))
        $cb=[Math]::Max(0,[Math]::Min(255,$raw.B+$donor.B-$photoDonor.B))
        if(!$isOpen){
            $da=$depthMask.GetPixel($x,$y).R/255.0
            if($da -gt 0){
                $dc=$depth.GetPixel($x,$y)
                $cr=$cr*(1-$da)+$dc.R*$da;$cg=$cg*(1-$da)+$dc.G*$da;$cb=$cb*(1-$da)+$dc.B*$da
                $raw=[Drawing.Color]::FromArgb([int]$cr,[int]$cg,[int]$cb)
            }
        }
        $blend=[Math]::Max(0,[Math]::Min(1,[Math]::Min(($x-64)/18.0,[Math]::Min(($y-12)/3.0,(126-$y)/3.0))))
        $fade=if($y -lt 62){(222-$x)/5.0}elseif($y -ge 70){if($x -lt 175){1}else{0}}else{1}
        $blend*=[Math]::Max(0,[Math]::Min(1,$fade))
        # Only retain the old slit/disk pixels above the lower pocket. The
        # old y70-73 bevel is the false white rail under the mechanism.
        if($y -ge 62 -and $y -le 69){
            $lever=(!$isOpen -and $x -ge 89 -and $x -le 112 -and [Math]::Max($raw.R,[Math]::Max($raw.G,$raw.B)) -gt 110)
            if(!$lever){$cr=$r;$cg=$g;$cb=$b}
            $blend=1
            if($mask){$mask.SetPixel($x,$y,[Drawing.Color]::Black)}
            if(!$isOpen -and !$lever -and $y -ge 64 -and $y -le 69){
                $disk=$diskSource.GetPixel($x,$y);if($disk.A -eq 0){$disk=$diskSource.GetPixel(150,$y)}
                $a=$disk.A/255.0
                $cr=$cr*(1-$a)+$disk.R*$a;$cg=$cg*(1-$a)+$disk.G*$a;$cb=$cb*(1-$a)+$disk.B*$a
                if($mask){$v=[int](255*$a);$mask.SetPixel($x,$y,[Drawing.Color]::FromArgb($v,$v,$v))}
            }
        }
        $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,[int][Math]::Round($r*(1-$blend)+$cr*$blend),[int][Math]::Round($g*(1-$blend)+$cg*$blend),[int][Math]::Round($b*(1-$blend)+$cb*$blend)))
    }}
    for($y=0;$y -lt 180;$y++){for($x=230;$x -lt 450;$x++){
        if($prior.GetPixel($x,$y).ToArgb() -ne $patch.GetPixel($x,$y).ToArgb()){throw 'Protected right side changed'}
    }}
    $patch.Save((Join-Path $out ($drive.id+'-'+$state+'.png')))
    if($mask){$mask.Save((Join-Path $out ($drive.id+'-disk-color-mask.png')));$mask.Dispose()}
    $comp=$front.Clone();$g=[Drawing.Graphics]::FromImage($comp);$g.DrawImageUnscaled($patch,$drive.x,$drive.y);$g.Dispose()
    if($drive.id -eq 'drive-a' -and $isOpen){$target=$comp.Clone([Drawing.Rectangle]::new($drive.x,$drive.y,450,180),$comp.PixelFormat);$target.Save((Join-Path $work 'final-open.png'));$target.Dispose()}
    $col=if($drive.id -eq 'drive-a'){0}else{1}
    $sg.DrawImage($comp,[Drawing.Rectangle]::new(($col*470),($row*170+23),450,140),[Drawing.Rectangle]::new($drive.x,$drive.y,450,140),[Drawing.GraphicsUnit]::Pixel)
    $sg.DrawString(($drive.id+' / '+$state),$font,[Drawing.Brushes]::White,($col*470),($row*170))
    $comp.Dispose();$patch.Dispose();$prior.Dispose();$clean.Dispose();$diskSource.Dispose()
};$row++}
$sg.Dispose();$font.Dispose()
$sheet.Save((Join-Path $out 'previews/geometry-v3-preview.png'));$sheet.Save((Join-Path $out 'previews/all-states-preview.png'))
$pair=$sheet.Clone([Drawing.Rectangle]::new(0,0,940,340),$sheet.PixelFormat);$pair.Save((Join-Path $out 'previews/preview.png'));$pair.Dispose()
$detail=$sheet.Clone([Drawing.Rectangle]::new(0,0,940,170),$sheet.PixelFormat);$detail.Save((Join-Path $out 'open-drives-detail.png'));$detail.Dispose();$sheet.Dispose()
$samples.Values | ForEach-Object {$_.Dispose()};$front.Dispose();$depth.Dispose();$depthMask.Dispose()
$manifest.geometry_revision=3
$manifest | Add-Member -NotePropertyName mechanism_reference -NotePropertyValue 'Photo-based: pivot approx. 24% of face width from left; left diagonal and lower planar ramp retained.' -Force
$manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $out 'placement.json') -Encoding UTF8
Write-Output 'Updated twelve photo-based states; columns 230-449 exactly preserved from revision 2.'
