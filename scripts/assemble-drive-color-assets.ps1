$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'assets/front/drives'
$work=Join-Path $root 'local/artwork/drive-states'
$colors=@('yellow','green','blue','red')
$manifestPath=Join-Path $out 'placement.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
foreach ($color in $colors) {
    $gen=[Drawing.Bitmap]::FromFile((Join-Path $work ('generated/disk-'+$color+'.png')))
    if ([Math]::Abs($gen.Width/[double]$gen.Height-3.0) -gt 0.01) {throw 'Unexpected source aspect ratio.'}
    $sample=[Drawing.Bitmap]::new(450,150)
    $g=[Drawing.Graphics]::FromImage($sample)
    $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($gen,[Drawing.Rectangle]::new(0,0,450,150))
    $g.Dispose(); $gen.Dispose()
    foreach ($drive in $manifest.drives) {
        $black=[Drawing.Bitmap]::FromFile((Join-Path $out $drive.closed_black))
        $patch=[Drawing.Bitmap]::new($black.Width,$black.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        for ($y=0; $y -lt $black.Height; $y++) {
            for ($x=0; $x -lt $black.Width; $x++) {
                $a=$black.GetPixel($x,$y).A
                if ($a -eq 0) {continue}
                # Sample the generated jacket material only. Avoid picking up
                # the left source's latch near the right drive's occlusion.
                $sx=if($x -ge 76 -and $x -le 112){150}else{$x}
                $c=$sample.GetPixel($sx,$y)
                $patch.SetPixel($x,$y,[Drawing.Color]::FromArgb($a,$c.R,$c.G,$c.B))
            }
        }
        $patch.Save((Join-Path $out ($drive.id+'-closed-'+$color+'.png')),[Drawing.Imaging.ImageFormat]::Png)
        $patch.Dispose(); $black.Dispose()
    }
    $sample.Dispose()
}
foreach ($drive in $manifest.drives) {
    $variants=[ordered]@{ black=$drive.closed_black }
    foreach ($color in $colors) { $variants[$color]=$drive.id+'-closed-'+$color+'.png' }
    $drive | Add-Member -NotePropertyName closed_variants -NotePropertyValue $variants -Force
}
$manifest.version=2
$manifest | Add-Member -NotePropertyName disk_colors -NotePropertyValue @('black','yellow','green','blue','red') -Force
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$states=@('open-empty','closed-black','closed-yellow','closed-green','closed-blue','closed-red')
$sheet=[Drawing.Bitmap]::new(1050,1050)
$sg=[Drawing.Graphics]::FromImage($sheet)
$sg.Clear([Drawing.Color]::FromArgb(28,29,32))
$font=[Drawing.Font]::new('Segoe UI',14)
$index=0
foreach ($state in $states) {
    $composite=$front.Clone()
    $g=[Drawing.Graphics]::FromImage($composite)
    foreach ($drive in $manifest.drives) {
        $patch=[Drawing.Bitmap]::FromFile((Join-Path $out ($drive.id+'-'+$state+'.png')))
        $g.DrawImageUnscaled($patch,$drive.x,$drive.y); $patch.Dispose()
        $lx=if($drive.id -eq 'drive-a'){522}else{980}
        $led=[Drawing.Bitmap]::FromFile((Join-Path $root ('assets/front/leds/'+$drive.id+'-off.png')))
        $g.DrawImageUnscaled($led,$lx,1015); $led.Dispose()
    }
    $g.Dispose()
    $composite.Save((Join-Path $work ('front-'+$state+'.png')),[Drawing.Imaging.ImageFormat]::Png)
    $label=if($state -eq 'open-empty'){'OPEN / EMPTY - MATCHED ORIGINAL SURFACE'}else{$state.Replace('-',' / ').ToUpperInvariant()}
    $sg.DrawString($label,$font,[Drawing.Brushes]::White,12,($index*175+4))
    $sg.DrawImage($composite,[Drawing.Rectangle]::new(0,($index*175+30),1050,140),[Drawing.Rectangle]::new(100,1010,1050,140),[Drawing.GraphicsUnit]::Pixel)
    $composite.Dispose(); $index++
}
$sg.Dispose();$font.Dispose();$front.Dispose()
$sheet.Save((Join-Path $out 'all-states-preview.png'),[Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output 'Saved eight coloured disk patches and updated the state manifest and overview. Existing geometry and alpha masks retained.'
