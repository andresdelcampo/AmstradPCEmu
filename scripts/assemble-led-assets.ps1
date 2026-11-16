param([switch]$PowerOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'assets/front/leds'
$work = Join-Path $root 'local/artwork/led-states'
$frontPath = Join-Path $root 'assets/front/pc1512-front.png'
$frontBytes = [IO.File]::ReadAllBytes($frontPath)
$sha = [Security.Cryptography.SHA256]::Create()
$frontHash = [BitConverter]::ToString($sha.ComputeHash($frontBytes)).Replace('-','').ToLowerInvariant()
$front = [Drawing.Bitmap]::FromFile($frontPath)
if ($front.Width -ne 1254 -or $front.Height -ne 1254) { throw 'LED placement requires the 1254 x 1254 front.' }
New-Item -ItemType Directory -Force -Path $out | Out-Null
# Coordinates are in the unchanged cabinet image. Each drive keeps its own
# recess and rim pixels; only the generated lens is transferred between them.
$items = @(
    @{ id='power'; x=208; y=960; cx=17.0; cy=27.0; rx=7.2; ry=7.8; source='power'; sx=615; sy=616; sr=267 },
    @{ id='drive-a'; x=522; y=1015; cx=23.5; cy=24.5; rx=8.0; ry=8.4; source='drive'; sx=616; sy=632; sr=221 },
    @{ id='drive-b'; x=980; y=1015; cx=23.0; cy=24.5; rx=7.5; ry=8.4; source='drive'; sx=616; sy=632; sr=221 }
)
# Drive geometry revisions can relocate indicators independently of this script.
$manifestPath = Join-Path $out 'placement.json'
$existing = if (Test-Path $manifestPath) { Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json }
foreach ($item in $items) {
    $position = @($existing.indicators | Where-Object { $_.id -eq $item.id })
    if ($position.Count -eq 1) { $item.x = $position[0].x; $item.y = $position[0].y }
}
$manifestItems = @()
foreach ($item in $items) {
    foreach ($state in @('off','on')) {
        if ($PowerOnly -and $item.id -ne 'power') { continue }
        $sourceName = if ($item.id -eq 'power') {
            if ($state -eq 'on') { 'power-on-v4' } else { 'power-off-v3' }
        } else { $item.source+'-'+$state }
        $gen = [Drawing.Bitmap]::FromFile((Join-Path $work ('generated/'+$sourceName+'.png')))
        $patch = [Drawing.Bitmap]::new(48,48,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        # Resample just the lens with the same fixed geometry for both states.
        $sample = [Drawing.Bitmap]::new(48,48,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [Drawing.Graphics]::FromImage($sample)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $sx = $item.sx * $gen.Width / 1254.0
        $sy = $item.sy * $gen.Height / 1254.0
        $scaleX = $item.sr * $gen.Width / 1254.0 / $item.rx
        $scaleY = $item.sr * $gen.Height / 1254.0 / $item.ry
        $sourceRect = [Drawing.RectangleF]::new(($sx-($item.cx+0.5)*$scaleX),($sy-($item.cy+0.5)*$scaleY),(48*$scaleX),(48*$scaleY))
        $g.DrawImage($gen,[Drawing.RectangleF]::new(0,0,48,48),$sourceRect,[Drawing.GraphicsUnit]::Pixel)
        $g.Dispose()
        for ($y=0; $y -lt 48; $y++) {
            for ($x=0; $x -lt 48; $x++) {
                $distance = [Math]::Sqrt([Math]::Pow(($x-$item.cx)/$item.rx,2)+[Math]::Pow(($y-$item.cy)/$item.ry,2))
                $alpha = [Math]::Max(0.0,[Math]::Min(1.0,(1.30-$distance)/0.15))
                if ($alpha -le 0) { continue }
                $blend = [Math]::Max(0.0,[Math]::Min(1.0,(1.14-$distance)/0.24))
                $old = $front.GetPixel(($item.x+$x),($item.y+$y))
                $new = $sample.GetPixel($x,$y)
                $r = [int][Math]::Round($old.R*(1-$blend)+$new.R*$blend)
                $green = [int][Math]::Round($old.G*(1-$blend)+$new.G*$blend)
                $b = [int][Math]::Round($old.B*(1-$blend)+$new.B*$blend)
                $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb([int][Math]::Round(255*$alpha),$r,$green,$b))
            }
        }
        $patch.Save((Join-Path $out ($item.id+'-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png)
        $sample.Dispose(); $patch.Dispose(); $gen.Dispose()
    }
    $manifestItems += [ordered]@{ id=$item.id; x=$item.x; y=$item.y; width=48; height=48; off=($item.id+'-off.png'); on=($item.id+'-on.png') }
}
# Configuration assembly also registers the HD20 LED; retain its placement.
if ($existing) {
    $manifestItems += @($existing.indicators | Where-Object { $_.id -notin $items.id })
}
$manifest = [ordered]@{
    version=1; front='../pc1512-front.png'; front_sha256=$frontHash
    canvas=[ordered]@{ width=1254; height=1254; origin='top-left'; units='pixels' }
    compositing='straight-alpha source-over; draw front first, then exactly one state per indicator at x,y; scale with the cabinet'
    indicators=$manifestItems
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'placement.json') -Encoding UTF8
# Context previews, plus a contact sheet with native context and 6x details.
$sheet = [Drawing.Bitmap]::new(1050,970)
$sg = [Drawing.Graphics]::FromImage($sheet)
$sg.Clear([Drawing.Color]::FromArgb(28,29,32))
$font = [Drawing.Font]::new('Segoe UI',14)
for ($i=0; $i -lt 2; $i++) {
    $state = @('off','on')[$i]
    $composite = $front.Clone()
    $cg = [Drawing.Graphics]::FromImage($composite)
    # Preview the current runtime drive faces before LEDs, just as paintPanel does.
    $driveDir = Join-Path $root 'assets/front/drives'
    $driveManifest = Get-Content -LiteralPath (Join-Path $driveDir 'placement.json') -Raw | ConvertFrom-Json
    foreach ($drive in $driveManifest.drives) {
        if ($drive.closed_mechanism) {
            $mechanism = [Drawing.Bitmap]::FromFile((Join-Path $driveDir $drive.closed_mechanism))
            $cg.DrawImageUnscaled($mechanism,$drive.x,$drive.y)
            $mechanism.Dispose()
        }
        $face = [Drawing.Bitmap]::FromFile((Join-Path $driveDir $drive.closed_black))
        $cg.DrawImageUnscaled($face,$drive.x,$drive.y)
        $face.Dispose()
    }
    foreach ($item in $items) {
        $patch = [Drawing.Bitmap]::FromFile((Join-Path $out ($item.id+'-'+$state+'.png')))
        $cg.DrawImageUnscaled($patch,$item.x,$item.y)
        $patch.Dispose()
    }
    $cg.Dispose()
    $composite.Save((Join-Path $work ('front-all-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    $top = $i*485
    $sg.DrawString(('POWER '+$state.ToUpper()+' / BOTH DRIVES '+$state.ToUpper()),$font,[Drawing.Brushes]::White,12,($top+8))
    $sg.DrawImage($composite,[Drawing.Rectangle]::new(0,($top+40),1050,275),[Drawing.Rectangle]::new(100,950,1050,275),[Drawing.GraphicsUnit]::Pixel)
    $sg.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    foreach ($n in 0..2) {
        $item=$items[$n]
        $dest=[Drawing.Rectangle]::new((185+$n*300),($top+320),144,144)
        $src=[Drawing.Rectangle]::new([int]($item.x+$item.cx-12),[int]($item.y+$item.cy-12),24,24)
        $sg.DrawImage($composite,$dest,$src,[Drawing.GraphicsUnit]::Pixel)
    }
    $composite.Dispose()
}
$sg.Dispose(); $font.Dispose()
$sheet.Save((Join-Path $out 'preview.png'),[Drawing.Imaging.ImageFormat]::Png)
# A compact review of just the two power states, at 3x cabinet scale.
$powerSheet = [Drawing.Bitmap]::new(840,220)
$pg = [Drawing.Graphics]::FromImage($powerSheet)
$pg.Clear([Drawing.Color]::FromArgb(28,29,32))
$pf = [Drawing.Font]::new('Segoe UI',14)
foreach ($i in 0..1) {
    $state = @('off','on')[$i]
    $pg.DrawString(('Power '+$state),$pf,[Drawing.Brushes]::White,(10+$i*420),8)
    $context = [Drawing.Bitmap]::FromFile((Join-Path $work ('front-all-'+$state+'.png')))
    $pg.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $pg.DrawImage($context,[Drawing.Rectangle]::new(($i*420),40,420,180),[Drawing.Rectangle]::new(200,954,140,60),[Drawing.GraphicsUnit]::Pixel)
    $context.Dispose()
}
$pg.Dispose(); $pf.Dispose()
$powerSheet.Save((Join-Path $out 'power-states-preview.png'),[Drawing.Imaging.ImageFormat]::Png)
$powerSheet.Dispose()
$sheet.Dispose(); $front.Dispose()
$afterHash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($frontPath))).Replace('-','').ToLowerInvariant()
$sha.Dispose()
if ($afterHash -ne $frontHash) { throw 'Front master changed during assembly.' }
Write-Output 'Saved LED assets, placement.json and preview.png. Front master unchanged.'
