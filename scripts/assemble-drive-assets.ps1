param([switch]$OpenOnly)
$ErrorActionPreference = 'Stop'
if ((Get-Content (Join-Path $PSScriptRoot '../assets/front/drives/placement.json') -Raw | ConvertFrom-Json).geometry_revision -ge 2) { throw 'Use apply-closed-drive-master.ps1 for current masters; this legacy assembler would restore old geometry.' }
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$work = Join-Path $root 'local/artwork/drive-states'
$out = Join-Path $root 'assets/front/drives'
$frontPath = Join-Path $root 'assets/front/pc1512-front.png'
$sha = [Security.Cryptography.SHA256]::Create()
$hashBefore = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($frontPath))).Replace('-','').ToLowerInvariant()
$front = [Drawing.Bitmap]::FromFile($frontPath)
if ($front.Width -ne 1254 -or $front.Height -ne 1254) { throw 'Expected 1254x1254 front.' }
New-Item -ItemType Directory -Force -Path $out | Out-Null
$items = @(@{id='drive-a'; x=174; y=1006},@{id='drive-b'; x=632; y=1006})
# Both mechanisms use ONE open lever master. The separate generated right
# drive had invented a subtly different arm/pivot; keep only its empty slit.
$leverGen=[Drawing.Bitmap]::FromFile((Join-Path $work 'generated/drive-a-open-empty.png'))
$leverSample=[Drawing.Bitmap]::new(450,150)
$leverGraphics=[Drawing.Graphics]::FromImage($leverSample)
$leverGraphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$leverGraphics.DrawImage($leverGen,[Drawing.Rectangle]::new(0,0,450,150))
$leverGraphics.Dispose();$leverGen.Dispose()
$entries = @()
foreach ($item in $items) {
    foreach ($state in @('open-empty','closed-black')) {
        if ($OpenOnly -and $state -ne 'open-empty') { continue }
        $gen = [Drawing.Bitmap]::FromFile((Join-Path $work ('generated/'+$item.id+'-'+$state+'.png')))
        if ([Math]::Abs($gen.Width/[double]$gen.Height-3.0) -gt 0.01) { throw 'Unexpected generated aspect ratio.' }
        $sample = [Drawing.Bitmap]::new(450,150)
        $g = [Drawing.Graphics]::FromImage($sample)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($gen,[Drawing.Rectangle]::new(0,0,450,150))
        $g.Dispose(); $gen.Dispose()
        $patch = [Drawing.Bitmap]::new(450,180,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $colorMask = [Drawing.Bitmap]::new(450,180,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $mg = [Drawing.Graphics]::FromImage($colorMask)
        $mg.Clear([Drawing.Color]::Black); $mg.Dispose()
        for ($y=0; $y -lt 180; $y++) {
            for ($x=0; $x -lt 450; $x++) {
                $old = $front.GetPixel(($item.x+$x),($item.y+$y))
                $new = if ($y -lt 150) { $sample.GetPixel($x,$y) } else { $old }
                if ($state -eq 'open-empty') {
                    # Three overlapping feathered regions: upper latch, old
                    # downward arm/shadow, and the now-empty insertion slit.
                    $upper = [Math]::Min([Math]::Min(($x-64)/4.0,(230-$x)/4.0),[Math]::Min(($y-12)/4.0,(68-$y)/4.0))
                    $lower = [Math]::Min([Math]::Min(($x-65)/8.0,(151-$x)/8.0),[Math]::Min(($y-48)/8.0,(175-$y)/8.0))
                    $slot = [Math]::Min([Math]::Min(($x-30)/2.0,(421-$x)/2.0),[Math]::Min(($y-56)/2.0,(74-$y)/2.0))
                    $alpha = [Math]::Max(0.0,[Math]::Min(1.0,[Math]::Max($upper,[Math]::Max($lower,$slot))))
                    if ($x -ge 64 -and $x -le 230 -and $y -ge 12 -and $y -le 68) {
                        $new=$leverSample.GetPixel($x,$y)
                    }
                    # Reveal the corrected native finger-well aperture, so
                    # the old generated open slit cannot reintroduce its rail.
                    $cavityRight=if($item.id -eq 'drive-a'){303}else{299}
                    if($x -gt 174 -and $x -lt $cavityRight -and $y -ge 70 -and $y -le 91) {
                        $cut=[Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min(($x-174)/1.5,($cavityRight-$x)/1.5)))
                        $alpha *= (1-$cut)
                    }
                    # Reconstruct the whole flat area behind the old arm from
                    # clean ORIGINAL columns on either side. Interpolation
                    # retains this drive's own row shading/colour and registers
                    # the bottom frame exactly, avoiding a generated beige fill.
                    if ($y -ge 73 -and $x -gt 65 -and $x -lt 151) {
                        $left = $front.GetPixel(($item.x+55),($item.y+$y))
                        $right = $front.GetPixel(($item.x+155),($item.y+$y))
                        $t = [Math]::Max(0.0,[Math]::Min(1.0,($x-55)/100.0))
                        $donor = [Drawing.Color]::FromArgb(
                            [int][Math]::Round($left.R*(1-$t)+$right.R*$t),
                            [int][Math]::Round($left.G*(1-$t)+$right.G*$t),
                            [int][Math]::Round($left.B*(1-$t)+$right.B*$t))
                        $mix = [Math]::Min(1.0,($y-73)/3.0)
                        $new = [Drawing.Color]::FromArgb(
                            [int][Math]::Round($new.R*(1-$mix)+$donor.R*$mix),
                            [int][Math]::Round($new.G*(1-$mix)+$donor.G*$mix),
                            [int][Math]::Round($new.B*(1-$mix)+$donor.B*$mix))
                    }
                } else {
                    # Isolate the visible black disk jacket. The original
                    # cabinet supplies the EXACT unchanged closed latch.
                    $alpha = [Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min([Math]::Min(($x-33)/1.2,(418-$x)/1.2),[Math]::Min(($y-63)/0.8,(70-$y)/0.8))))
                    # Preserve the physical latch, its occlusion, and beige
                    # slot bevels; never tint those with later disk colours.
                    if ([Math]::Max($old.R,[Math]::Max($old.G,$old.B)) -gt 75 -or [Math]::Max($new.R,[Math]::Max($new.G,$new.B)) -gt 130) { $alpha=0 }
                    $v = [int][Math]::Round(255*$alpha)
                    $colorMask.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,$v,$v,$v))
                }
                if ($alpha -gt 0) {
                    $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb([int][Math]::Round(255*$alpha),$new.R,$new.G,$new.B))
                }
            }
        }
        $patch.Save((Join-Path $out ($item.id+'-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png)
        if ($state -eq 'closed-black') { $colorMask.Save((Join-Path $out ($item.id+'-disk-color-mask.png')),[Drawing.Imaging.ImageFormat]::Png) }
        $patch.Dispose(); $colorMask.Dispose(); $sample.Dispose()
    }
    $entries += [ordered]@{ id=$item.id; x=$item.x; y=$item.y; width=450; height=180; open_empty=($item.id+'-open-empty.png'); closed_black=($item.id+'-closed-black.png'); disk_color_mask=($item.id+'-disk-color-mask.png') }
}
$metadata = [ordered]@{
    version=1; front='../pc1512-front.png'; front_sha256=$hashBefore
    canvas=[ordered]@{width=1254; height=1254; origin='top-left'; units='pixels'}
    draw_order=@('cabinet','one drive state per drive','LED state patches')
    alpha='straight-alpha source-over; restore cabinet before selecting a different state'
    disk_color='black'; drives=$entries
}
$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'placement.json') -Encoding UTF8
$sheet = [Drawing.Bitmap]::new(1050,700)
$sg = [Drawing.Graphics]::FromImage($sheet)
$sg.Clear([Drawing.Color]::FromArgb(28,29,32))
$font=[Drawing.Font]::new('Segoe UI',14)
$index=0
foreach ($state in @('open-empty','closed-black')) {
    $composite=$front.Clone()
    $g=[Drawing.Graphics]::FromImage($composite)
    foreach ($item in $items) {
        $patch=[Drawing.Bitmap]::FromFile((Join-Path $out ($item.id+'-'+$state+'.png')))
        $g.DrawImageUnscaled($patch,$item.x,$item.y); $patch.Dispose()
    }
    # Demonstrate independent LED layers; drives are idle in both examples.
    foreach ($led in @(@('power',208,960,'on'),@('drive-a',522,1015,'off'),@('drive-b',980,1015,'off'))) {
        $patch=[Drawing.Bitmap]::FromFile((Join-Path $root ('assets/front/leds/'+$led[0]+'-'+$led[3]+'.png')))
        $g.DrawImageUnscaled($patch,$led[1],$led[2]); $patch.Dispose()
    }
    $g.Dispose()
    $composite.Save((Join-Path $work ('front-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    $label = if ($state -eq 'open-empty') { 'OPEN / EMPTY - LATCHES TO THE RIGHT' } else { 'CLOSED / BLACK DISKS INSERTED - LATCHES DOWN' }
    $sg.DrawString($label,$font,[Drawing.Brushes]::White,12,($index*350+8))
    $sg.DrawImage($composite,[Drawing.Rectangle]::new(0,($index*350+40),1050,275),[Drawing.Rectangle]::new(100,950,1050,275),[Drawing.GraphicsUnit]::Pixel)
    $composite.Dispose(); $index++
}
$sg.Dispose(); $font.Dispose()
$sheet.Save((Join-Path $out 'preview.png'),[Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose(); $front.Dispose(); $leverSample.Dispose()
$hashAfter=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($frontPath))).Replace('-','').ToLowerInvariant()
$sha.Dispose()
if ($hashBefore -ne $hashAfter) { throw 'Cabinet master changed.' }
Write-Output 'Saved four 450x180 RGBA drive patches, two disk colour masks, placement.json and preview.png. Cabinet master unchanged.'
