$ErrorActionPreference='Stop'
if ((Get-Content (Join-Path $PSScriptRoot '../assets/front/drives/placement.json') -Raw | ConvertFrom-Json).geometry_revision -ge 4) {throw 'Use apply-closed-drive-master.ps1; this historical assembler would overwrite current artwork.'}
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v2'
$out=Join-Path $root 'assets/front/drives'
$backup=Join-Path $work 'before'
New-Item -ItemType Directory -Force $backup | Out-Null
if (!(Test-Path (Join-Path $backup 'drive-a-open-empty.png'))) {
    Get-ChildItem $out -File | Copy-Item -Destination $backup
}
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$samples=@{}
foreach($state in @('open','closed')) {
    $src=[Drawing.Bitmap]::FromFile((Join-Path $work ($state+'.png')))
    $sample=[Drawing.Bitmap]::new(450,180)
    $g=[Drawing.Graphics]::FromImage($sample)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($src,[Drawing.Rectangle]::new(0,0,450,180))
    $g.Dispose(); $src.Dispose(); $samples[$state]=$sample
}
$states=@('open-empty','closed-black','closed-yellow','closed-green','closed-blue','closed-red')
$manifest=Get-Content (Join-Path $out 'placement.json') -Raw | ConvertFrom-Json
$sheet=[Drawing.Bitmap]::new(940,($states.Count*170))
$sg=[Drawing.Graphics]::FromImage($sheet); $sg.Clear([Drawing.Color]::FromArgb(28,29,32))
$font=[Drawing.Font]::new('Segoe UI',11)
$row=0
foreach($state in $states) {
    foreach($drive in $manifest.drives) {
        $old=[Drawing.Bitmap]::FromFile((Join-Path $backup ($drive.id+'-'+$state+'.png')))
        $clean=[Drawing.Bitmap]::FromFile((Join-Path $backup ($drive.id+'-open-empty.png')))
        $patch=$old.Clone()
        $isOpen=$state -eq 'open-empty'
        $mask=$null
        if($state -eq 'closed-black'){
            $maskSource=[Drawing.Bitmap]::FromFile((Join-Path $backup ($drive.id+'-disk-color-mask.png')))
            $mask=$maskSource.Clone();$maskSource.Dispose()
        }
        for($y=12;$y -lt 146;$y++) {
            for($x=64;$x -lt 310;$x++) {
                # Keep the pocket boundary farther right, while retaining the
                # corrected pivot and the existing right-hand finger well.
                $sx=if($x -lt 95){64+($x-64)*12.0/31.0}elseif($x -lt 130){76+($x-95)*54.0/35.0}else{$x}
                $source=$samples['closed']
                if($isOpen) {
                    $source=$samples['open']
                }
                $c=$source.GetPixel([Math]::Max(0,[Math]::Min(449,[int][Math]::Round($sx))),$y)
                $blend=[Math]::Max(0,[Math]::Min(1,[Math]::Min([Math]::Min(($x-64)/22.0,(310-$x)/12.0),[Math]::Min(($y-12)/7.0,(127-$y)/4.0))))
                $base=$front.GetPixel(($drive.x+$x),($drive.y+$y))
                $o=$clean.GetPixel($x,$y)
                $oa=$o.A/255.0
                $r=$base.R*(1-$oa)+$o.R*$oa; $g=$base.G*(1-$oa)+$o.G*$oa; $b=$base.B*(1-$oa)+$o.B*$oa
                # Retain the already-approved upper-right and lower-right
                # cavity surfaces; feather only into their left boundaries.
                $rightFade=if($y -lt 62){(232-$x)/12.0}elseif($y -gt 73){(192-$x)/15.0}else{1.0}
                $blend *= [Math]::Max(0,[Math]::Min(1,$rightFade))
                if($y -ge 62 -and $y -le 73) {
                    $lever=(!$isOpen -and $x -ge 97 -and $x -le 132 -and [Math]::Max($c.R,[Math]::Max($c.G,$c.B)) -ge 75)
                    if(!$lever){$c=[Drawing.Color]::FromArgb(255,[int]$r,[int]$g,[int]$b)}
                    $blend=1.0
                    if($mask){$mask.SetPixel($x,$y,[Drawing.Color]::Black)}
                }
                # Insert the existing material behind the new latch. The
                # original gap at the old latch is filled from a clean donor.
                if(!$isOpen -and $y -ge 64 -and $y -le 69 -and [Math]::Max($c.R,[Math]::Max($c.G,$c.B)) -lt 75) {
                    $disk=$old.GetPixel($x,$y)
                    if($disk.A -eq 0){$disk=$old.GetPixel(150,$y)}
                    $da=$disk.A/255.0
                    if($mask){$v=[int](255*$da);$mask.SetPixel($x,$y,[Drawing.Color]::FromArgb($v,$v,$v))}
                    $c=[Drawing.Color]::FromArgb(255,[int]($c.R*(1-$da)+$disk.R*$da),[int]($c.G*(1-$da)+$disk.G*$da),[int]($c.B*(1-$da)+$disk.B*$da))
                }
                $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,[int][Math]::Round($r*(1-$blend)+$c.R*$blend),[int][Math]::Round($g*(1-$blend)+$c.G*$blend),[int][Math]::Round($b*(1-$blend)+$c.B*$blend)))
            }
        }
        # Prove the user's protected right side is bit-for-bit preserved.
        for($y=0;$y -lt 180;$y++){for($x=310;$x -lt 450;$x++){
            if($old.GetPixel($x,$y).ToArgb() -ne $patch.GetPixel($x,$y).ToArgb()){throw 'Protected right side changed'}
        }}
        $patch.Save((Join-Path $out ($drive.id+'-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png)
        if($mask){$mask.Save((Join-Path $out ($drive.id+'-disk-color-mask.png')));$mask.Dispose()}
        $composite=$front.Clone(); $g=[Drawing.Graphics]::FromImage($composite)
        $g.DrawImageUnscaled($patch,$drive.x,$drive.y); $g.Dispose()
        $column=if($drive.id -eq 'drive-a'){0}else{1}
        $sg.DrawImage($composite,[Drawing.Rectangle]::new(($column*470),($row*170+23),450,140),[Drawing.Rectangle]::new($drive.x,$drive.y,450,140),[Drawing.GraphicsUnit]::Pixel)
        $sg.DrawString(($drive.id+' / '+$state),$font,[Drawing.Brushes]::White,($column*470),($row*170))
        $composite.Dispose(); $patch.Dispose(); $old.Dispose(); $clean.Dispose()
    }
    $row++
}
$sg.Dispose();$font.Dispose()
$sheet.Save((Join-Path $out 'geometry-v2-preview.png'))
$sheet.Save((Join-Path $out 'all-states-preview.png'))
$pair=$sheet.Clone([Drawing.Rectangle]::new(0,0,940,340),$sheet.PixelFormat)
$pair.Save((Join-Path $out 'preview.png'));$pair.Dispose()
$detail=$sheet.Clone([Drawing.Rectangle]::new(0,0,940,170),$sheet.PixelFormat)
$detail.Save((Join-Path $out 'open-drives-detail.png'));$detail.Dispose();$sheet.Dispose()
$samples.Values | ForEach-Object { $_.Dispose() };$front.Dispose()
$manifest.version=3
$manifest | Add-Member -NotePropertyName geometry_revision -NotePropertyValue 2 -Force
$manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $out 'placement.json') -Encoding UTF8
Write-Output 'Updated twelve registered drive states. Rightmost 140 columns verified unchanged in every state.'
