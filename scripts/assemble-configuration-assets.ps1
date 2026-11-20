$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/configurations'
$assets=Join-Path $root 'assets/front'
New-Item -ItemType Directory -Force (Join-Path (Join-Path $assets 'drives') 'previews') | Out-Null  # comparison sheets, not shipped
$frontPath=Join-Path $assets 'pc1512-front.png'
$front=[Drawing.Bitmap]::FromFile($frontPath)
function Scaled([string]$name,[int]$w,[int]$h) {
    $source=[Drawing.Bitmap]::FromFile((Join-Path $work ('generated/'+$name+'.png')))
    $b=[Drawing.Bitmap]::new($w,$h)
    $g=[Drawing.Graphics]::FromImage($b)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($source,[Drawing.Rectangle]::new(0,0,$w,$h))
    $g.Dispose();$source.Dispose();return $b
}
$blank=Scaled 'bay-blank' 450 180
$sticker=Scaled 'bay-blank-sticker' 450 180
$hdd=Scaled 'bay-hdd' 450 180
foreach($mode in @('blank','blank-sticker','hdd')) {
    foreach($side in @('left','right')) {
        if($mode -eq 'hdd' -and $side -eq 'right'){continue}
        $ox=if($side -eq 'left'){174}else{632}
        $edge=if($side -eq 'left'){438}else{433}
        $patch=[Drawing.Bitmap]::new(450,180,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        for($y=0;$y -lt 180;$y++) {for($x=0;$x -lt 450;$x++) {
            $face=[Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min([Math]::Min(($x-11)/1.0,($edge-$x)/1.0),[Math]::Min(($y-11)/1.0,(124-$y)/1.0))))
            $cleanup=0.0
            if($y -ge 124) {$cleanup=[Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min([Math]::Min(($x-65)/8.0,(151-$x)/8.0),(175-$y)/8.0)))}
            $alpha=[Math]::Max($face,$cleanup)
            if($alpha -le 0){continue}
            if($y -lt 124) {
                $sx=[int][Math]::Round(12+($x-12)*425.0/($edge-13))
                $sx=[Math]::Max(0,[Math]::Min(449,$sx))
                $new=if($mode -eq 'hdd'){$hdd.GetPixel($sx,$y)}else{$blank.GetPixel($sx,$y)}
                if($mode -eq 'blank-sticker' -and $sx -ge 30 -and $sx -le 422 -and $y -ge 19 -and $y -le 122){$new=$sticker.GetPixel($sx,$y)}
            } else {
                # Remove the original downward latch shadow using native row
                # colours; keep the original straight border/grey fascia.
                $l=$front.GetPixel(($ox+55),(1011+$y));$r=$front.GetPixel(($ox+155),(1011+$y))
                $t=[Math]::Max(0.0,[Math]::Min(1.0,($x-55)/100.0))
                $new=[Drawing.Color]::FromArgb([int][Math]::Round($l.R*(1-$t)+$r.R*$t),[int][Math]::Round($l.G*(1-$t)+$r.G*$t),[int][Math]::Round($l.B*(1-$t)+$r.B*$t))
            }
            $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb([int][Math]::Round(255*$alpha),$new.R,$new.G,$new.B))
        }}
        $patch.Save((Join-Path $assets ('drives/bay-'+$side+'-'+$mode+'.png')),[Drawing.Imaging.ImageFormat]::Png);$patch.Dispose()
    }
}
$blank.Dispose();$sticker.Dispose();$hdd.Dispose()
# Preserve native PC/1512 lettering and badge material. Transfer only the red
# suffix glyph coverage, removing the original DD ink with a clean badge row.
foreach($model in @('dd','sd','hd20')) {
    $sample=if($model -ne 'dd'){Scaled ('model-'+$model) 216 76}else{$null}
    $patch=[Drawing.Bitmap]::new(216,76,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $max=1.0
    if($sample){for($y=24;$y -le 51;$y++){for($x=122;$x -le 200;$x++){$c=$sample.GetPixel($x,$y);$max=[Math]::Max($max,($c.R-($c.G+$c.B)/2.0))}}}
    for($y=24;$y -le 51;$y++){for($x=122;$x -le 200;$x++){
        $old=$front.GetPixel((870+$x),(1164+$y))
        if($model -eq 'dd'){$new=$old}else{
            $new=if($old.R-($old.G+$old.B)/2.0 -gt 2){$front.GetPixel(1056,(1164+$y))}else{$old}
            $c=$sample.GetPixel($x,$y)
            $ink=[Math]::Max(0.0,[Math]::Min(1.0,($c.R-($c.G+$c.B)/2.0-2)/($max-2)))
            $new=[Drawing.Color]::FromArgb([int][Math]::Round($new.R*(1-$ink)+151*$ink),[int][Math]::Round($new.G*(1-$ink)+64*$ink),[int][Math]::Round($new.B*(1-$ink)+53*$ink))
        }
        $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,$new.R,$new.G,$new.B))
    }}
    $patch.Save((Join-Path $assets ('badges/model-'+$model+'.png')),[Drawing.Imaging.ImageFormat]::Png);$patch.Dispose();if($sample){$sample.Dispose()}
}
# Off is sampled from the exact assembled HDD master, ensuring identical fit.
$hddFront=$front.Clone();$g=[Drawing.Graphics]::FromImage($hddFront)
$module=[Drawing.Bitmap]::FromFile((Join-Path $assets 'drives/bay-left-hdd.png'))
$g.DrawImageUnscaled($module,174,1011);$g.Dispose();$module.Dispose()
$lit=Scaled 'hdd-led-on' 48 40
foreach($state in @('off','on')) {
    $patch=[Drawing.Bitmap]::new(48,40,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for($y=0;$y -lt 40;$y++){for($x=0;$x -lt 48;$x++){
        $a=[Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min([Math]::Min(($x-11)/1.2,(36-$x)/1.2),[Math]::Min(($y-13)/1.2,(27-$y)/1.2))))
        if($a -le 0){continue}
        $c=if($state -eq 'off'){$hddFront.GetPixel((276+$x),(1061+$y))}else{$lit.GetPixel($x,$y)}
        $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb([int][Math]::Round(255*$a),$c.R,$c.G,$c.B))
    }}
    $patch.Save((Join-Path $assets ('leds/hdd-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png);$patch.Dispose()
}
$lit.Dispose();$hddFront.Dispose()
# Change only the first white letter of PC-CM. The trailing M, red PC,
# hyphen and badge housing continue to come from the exact original pixels.
$mm=Scaled 'monitor-mm' 140 60
foreach($type in @('cm','mm')) {
    $patch=[Drawing.Bitmap]::new(140,60,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $peak=1.0
    for($y=15;$y -le 40;$y++){for($x=72;$x -le 95;$x++){$c=$mm.GetPixel($x,$y);$bg=$mm.GetPixel(123,$y);$peak=[Math]::Max($peak,($c.R+$c.G+$c.B-$bg.R-$bg.G-$bg.B)/3.0)}}
    for($y=15;$y -le 40;$y++){for($x=72;$x -le 95;$x++){
        $old=$front.GetPixel((923+$x),(743+$y));$new=$old
        if($type -eq 'mm'){
            $bg=$front.GetPixel(1044,(743+$y))
            if(($old.R+$old.G+$old.B-$bg.R-$bg.G-$bg.B)/3.0 -gt 2){$new=$bg}
            $c=$mm.GetPixel($x,$y);$gb=$mm.GetPixel(123,$y)
            $a=[Math]::Max(0.0,[Math]::Min(1.0,((($c.R+$c.G+$c.B-$gb.R-$gb.G-$gb.B)/3.0)-2)/($peak-2)))
            $new=[Drawing.Color]::FromArgb([int][Math]::Round($new.R*(1-$a)+175*$a),[int][Math]::Round($new.G*(1-$a)+175*$a),[int][Math]::Round($new.B*(1-$a)+184*$a))
        }
        $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,$new.R,$new.G,$new.B))
    }}
    $patch.Save((Join-Path $assets ('badges/monitor-'+$type+'.png')),[Drawing.Imaging.ImageFormat]::Png);$patch.Dispose()
}
$mm.Dispose()
$manifest=[ordered]@{
    version=1;front='pc1512-front.png';canvas=@{width=1254;height=1254;origin='top-left'}
    bays=@{left=@{x=174;y=1011;width=450;height=180;hdd='drives/bay-left-hdd.png';blank='drives/bay-left-blank.png';blank_sticker='drives/bay-left-blank-sticker.png'};right=@{x=632;y=1011;width=450;height=180;blank='drives/bay-right-blank.png';blank_sticker='drives/bay-right-blank-sticker.png'}}
    badge=@{x=870;y=1164;width=216;height=76;dd='badges/model-dd.png';sd='badges/model-sd.png';hd20='badges/model-hd20.png'}
    monitor_badge=@{x=923;y=743;width=140;height=60;cm='badges/monitor-cm.png';mm='badges/monitor-mm.png';md='badges/monitor-md.png';cd='badges/monitor-cd.png';ecd='badges/monitor-ecd.png'}
    hdd_led=@{x=276;y=1061;width=48;height=40;off='leds/hdd-off.png';on='leds/hdd-on.png';requires='left HDD module'}
    configurations=@{dd=@{left='floppy A';right='floppy B';badge='dd'};sd=@{left='blank or blank_sticker';right='floppy A';badge='sd'};hd20=@{left='hdd';right='floppy A';badge='hd20'}}
    draw_order=@('cabinet','selected bay modules or floppy state patches','model badge','power LED and activity LEDs belonging to installed devices')
}
$manifest|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $assets 'configurations.json') -Encoding UTF8
$ledPath=Join-Path $assets 'leds/placement.json';$ledMeta=Get-Content -LiteralPath $ledPath -Raw|ConvertFrom-Json
$ledMeta.indicators=@($ledMeta.indicators|Where-Object {$_.id -ne 'hdd'})+@(@{id='hdd';x=276;y=1061;width=48;height=40;off='hdd-off.png';on='hdd-on.png';requires='left HDD module'})
$ledMeta|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $ledPath -Encoding UTF8
& (Join-Path $PSScriptRoot 'refresh-front-badges.ps1')
& (Join-Path $PSScriptRoot 'create-monitor-badges.ps1')
$sheet=[Drawing.Bitmap]::new(1050,1260);$sg=[Drawing.Graphics]::FromImage($sheet);$sg.Clear([Drawing.Color]::FromArgb(28,29,32));$font=[Drawing.Font]::new('Segoe UI',14)
$index=0
foreach($config in @(@('SD - PLAIN BLANK COVER','blank','sd','off'),@('SD - FACTORY STICKER','blank-sticker','sd','off'),@('HD20 - HDD IDLE','hdd','hd20','off'),@('HD20 - HDD ACTIVE','hdd','hd20','on'))) {
    $b=$front.Clone();$g=[Drawing.Graphics]::FromImage($b)
    $draws=@(@(('drives/bay-left-'+$config[1]+'.png'),174,1011),@('drives/drive-closed-mechanism.png',632,1011),@('drives/drive-closed-black.png',632,1011),@(('badges/model-'+$config[2]+'.png'),870,1164),@('leds/power-on.png',208,960),@('leds/drive-b-off.png',969,1019))
    if($config[1] -eq 'hdd'){$draws+=,@(('leds/hdd-'+$config[3]+'.png'),276,1061)}
    foreach($draw in $draws){$p=[Drawing.Bitmap]::FromFile((Join-Path $assets $draw[0]));$g.DrawImageUnscaled($p,$draw[1],$draw[2]);$p.Dispose()}
    $g.Dispose();$b.Save((Join-Path $work ('front-config-'+$index+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    $sg.DrawString($config[0],$font,[Drawing.Brushes]::White,12,($index*315+4))
    $sg.DrawImage($b,[Drawing.Rectangle]::new(0,($index*315+30),1050,275),[Drawing.Rectangle]::new(100,950,1050,275),[Drawing.GraphicsUnit]::Pixel)
    $b.Dispose();$index++
}
$sg.Dispose();$font.Dispose();$front.Dispose();$sheet.Save((Join-Path $assets 'drives/previews/configurations-preview.png'),[Drawing.Imaging.ImageFormat]::Png);$sheet.Dispose()
Write-Output 'Saved five bay modules, DD/SD/HD20 suffix badges, HDD LED off/on, configuration metadata and preview.'
