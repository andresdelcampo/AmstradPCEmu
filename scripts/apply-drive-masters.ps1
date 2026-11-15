$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'assets/front/drives'
$colors=@('black','yellow','green','blue','red','purple')
$hashes=@{}
function Get-FileHash($path){$sha=[Security.Cryptography.SHA256]::Create();try{return @{Hash=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($path))).Replace('-','')}}finally{$sha.Dispose()}}
foreach($name in @('closed','opened')){$hashes[$name]=(Get-FileHash (Join-Path $out "masters/$name.png")).Hash}
function Save-Png($b,$name){$b.Save((Join-Path $out $name),[Drawing.Imaging.ImageFormat]::Png)}
function Master-Patch($name){
    $src=[Drawing.Bitmap]::FromFile((Join-Path $out "masters/$name.png"))
    $b=[Drawing.Bitmap]::new(450,180,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g=[Drawing.Graphics]::FromImage($b);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    # Register the complete master face; exclude its white external margins.
    $g.DrawImage($src,[Drawing.Rectangle]::new(10,10,428,120),[Drawing.Rectangle]::new(0,40,$src.Width,640),[Drawing.GraphicsUnit]::Pixel)
    $g.Dispose();$src.Dispose();return ,$b
}
$opened=Master-Patch 'opened';$closed=Master-Patch 'closed'
Save-Png $opened 'drive-open-empty.png';Save-Png $closed 'drive-closed-mechanism.png'
foreach($color in $colors){
    $src=[Drawing.Bitmap]::FromFile((Join-Path $out "archive/disk-materials/disk-$color.png"))
    $disk=[Drawing.Bitmap]::new(450,180,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    # One straight, constant-height strip (rows 57..62 fit inside the slot along
    # its whole length). Only the lever and the slanted slot ends interrupt it.
    # Cuts are whole columns: near the lever and the slot ends a column is drawn
    # only when the slot is open over all six rows, so no column is ever partial.
    # Materials are complete (see repair-disk-materials.ps1) and copied 1:1.
    for($x=36;$x -le 415;$x++){
        if(($x -ge 60 -and $x -le 100) -or $x -le 38 -or $x -ge 413){
            $open=$true
            for($y=57;$y -le 62;$y++){$face=$closed.GetPixel($x,$y);if([Math]::Max($face.R,[Math]::Max($face.G,$face.B)) -gt 38){$open=$false}}
            if(-not $open){continue}
        }
        for($y=57;$y -le 62;$y++){
            $c=$src.GetPixel($x,($y+7))
            if($c.A -lt 255){throw "No disk material at $x,$y ($color)"}
            $disk.SetPixel($x,$y,$c)
        }
    }
    Save-Png $disk "drive-closed-$color.png";$disk.Dispose();$src.Dispose()
}
$m=Get-Content (Join-Path $out 'placement.json') -Raw | ConvertFrom-Json
$m.version=5;$m.geometry_revision=5
$m.mechanism_reference='Complete user masters, shared between both bays.'
$m.closed_master_sha256=$hashes['closed'].ToLowerInvariant()
$m | Add-Member -NotePropertyName open_master_sha256 -NotePropertyValue $hashes['opened'].ToLowerInvariant() -Force
foreach($d in $m.drives){
    $d.open_empty='drive-open-empty.png';$d.closed_mechanism='drive-closed-mechanism.png';$d.closed_black='drive-closed-black.png'
    $d.PSObject.Properties.Remove('disk_color_mask')
    foreach($color in $colors){$d.closed_variants | Add-Member -NotePropertyName $color -NotePropertyValue "drive-closed-$color.png" -Force}
}
$m.disk_colors=$colors
$m | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $out 'placement.json') -Encoding UTF8
$ledPath=Join-Path $root 'assets/front/leds/placement.json'
$leds=Get-Content $ledPath -Raw | ConvertFrom-Json
foreach($led in $leds.indicators){if($led.id -eq 'drive-a'){$led.x=511;$led.y=1014};if($led.id -eq 'drive-b'){$led.x=969;$led.y=1014}}
$leds | ConvertTo-Json -Depth 8 | Set-Content $ledPath -Encoding UTF8
$font=[Drawing.Font]::new('Segoe UI',12)
$sheet=[Drawing.Bitmap]::new(460,(160*($colors.Count+1)));$sg=[Drawing.Graphics]::FromImage($sheet);$sg.Clear([Drawing.Color]::FromArgb(28,29,32));$row=0
foreach($state in @('open-empty')+@($colors | ForEach-Object {"closed-$_"})){
    $sg.DrawString($state,$font,[Drawing.Brushes]::White,10,($row*160))
    if($state -ne 'open-empty'){$sg.DrawImageUnscaled($closed,5,($row*160+20))}
    $p=[Drawing.Bitmap]::FromFile((Join-Path $out "drive-$state.png"));$sg.DrawImageUnscaled($p,5,($row*160+20));$p.Dispose();$row++
}
$sg.Dispose();Save-Png $sheet 'all-states-preview.png';$sheet.Dispose()
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$configs=@(@('DD - OPEN / RED','open-empty','closed-red','dd'),@('SD - BLUE','blank','closed-blue','sd'),@('SD - STICKER / GREEN','blank-sticker','closed-green','sd'),@('HD20 - YELLOW','hdd','closed-yellow','hd20'))
$sheet=[Drawing.Bitmap]::new(1050,1260);$sg=[Drawing.Graphics]::FromImage($sheet);$sg.Clear([Drawing.Color]::FromArgb(28,29,32));$row=0
foreach($config in $configs){
    $comp=$front.Clone();$g=[Drawing.Graphics]::FromImage($comp)
    for($bay=0;$bay -lt 2;$bay++){
        $x=174+458*$bay;$state=$config[$bay+1]
        if($state.StartsWith('closed-')){$g.DrawImageUnscaled($closed,$x,1006)}
        $name=if($state -in @('blank','blank-sticker','hdd')){"bay-left-$state.png"}else{"drive-$state.png"}
        $p=[Drawing.Bitmap]::FromFile((Join-Path $out $name));$g.DrawImageUnscaled($p,$x,1006);$p.Dispose()
    }
    $p=[Drawing.Bitmap]::FromFile((Join-Path $root ('assets/front/badges/model-'+$config[3]+'.png')));$g.DrawImageUnscaled($p,870,1164);$p.Dispose();$g.Dispose()
    $sg.DrawString($config[0],$font,[Drawing.Brushes]::White,12,($row*315+4))
    $sg.DrawImage($comp,[Drawing.Rectangle]::new(0,($row*315+30),1050,275),[Drawing.Rectangle]::new(100,950,1050,275),[Drawing.GraphicsUnit]::Pixel)
    $comp.Dispose();$row++
}
$sg.Dispose();Save-Png $sheet 'configurations-preview.png'
$sheet.Dispose();$front.Dispose();$font.Dispose();$opened.Dispose();$closed.Dispose()
foreach($name in @('closed','opened')){if((Get-FileHash (Join-Path $out "masters/$name.png")).Hash -ne $hashes[$name]){throw "Master changed: $name"}}
Write-Output 'Built shared drive set and previews; both master hashes unchanged.'
