$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$work=Join-Path $root 'local/artwork/drive-geometry-v3'
$out=Join-Path $root 'assets/front/drives'
$prior=[Drawing.Bitmap]::FromFile((Join-Path $work 'closed-depth-target.png'))
$front=[Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
$patch=[Drawing.Bitmap]::FromFile((Join-Path $out 'drive-a-closed-black.png'))
$g=[Drawing.Graphics]::FromImage($front);$g.DrawImageUnscaled($patch,174,1006);$g.Dispose();$patch.Dispose()
$current=$front.Clone([Drawing.Rectangle]::new(174,1006,450,180),$front.PixelFormat);$front.Dispose()
$outsideChanges=0
for($y=0;$y -lt 180;$y++){for($x=0;$x -lt 450;$x++){
    if($x -ge 80 -and $x -le 140 -and $y -ge 12 -and $y -le 126){continue}
    if($prior.GetPixel($x,$y).ToArgb() -ne $current.GetPixel($x,$y).ToArgb()){$outsideChanges++}
}}
if($outsideChanges){throw "Changed $outsideChanges pixels outside lever region"}
foreach($drive in @('drive-a','drive-b')){
    $black=[Drawing.Bitmap]::FromFile((Join-Path $out ($drive+'-closed-black.png')))
    $mask=[Drawing.Bitmap]::FromFile((Join-Path $out ($drive+'-disk-color-mask.png')))
    if($mask.GetPixel(100,66).R -ne 0){throw 'Disk mask crosses lever'}
    foreach($colour in @('yellow','green','blue','red')){
        $image=[Drawing.Bitmap]::FromFile((Join-Path $out ($drive+'-closed-'+$colour+'.png')))
        if($image.Width -ne 450 -or $image.Height -ne 180){throw 'Invalid patch dimensions'}
        if($image.GetPixel(100,66).ToArgb() -ne $black.GetPixel(100,66).ToArgb()){throw 'Disk colour crosses lever'}
        if($image.GetPixel(150,66).ToArgb() -eq $black.GetPixel(150,66).ToArgb()){throw 'Disk colour missing'}
        $image.Dispose()
    }
    $black.Dispose();$mask.Dispose()
}
$sheet=[Drawing.Bitmap]::new(1000,430);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(28,29,32))
$font=[Drawing.Font]::new('Segoe UI',14)
$g.DrawString('Approved recess / previous lever',$font,[Drawing.Brushes]::White,10,5)
$g.DrawString('Same recess / shorter lever with depth',$font,[Drawing.Brushes]::White,510,5)
for($col=0;$col -lt 2;$col++){
    $src=if($col -eq 0){$prior}else{$current}
    $g.DrawImage($src,[Drawing.Rectangle]::new(($col*500+10),40,480,360),[Drawing.Rectangle]::new(70,12,160,120),[Drawing.GraphicsUnit]::Pixel)
}
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $out 'closed-lever-detail.png'));$sheet.Dispose()
$prior.Dispose();$current.Dispose()
Write-Output 'PASS: approved closed recess unchanged outside x80-140/y12-126; all disk colours preserve the lever and remain visible.'
