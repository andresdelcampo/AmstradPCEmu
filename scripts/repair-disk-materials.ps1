# Rebuilds archive/disk-materials/disk-*.png from the pristine pre-shared-master
# copies. Idempotent: always starts from the untouched backup.
#  - x 75..134 (old lever gap, flat filler columns, misplaced old shadow) is
#    replaced by a straight copy of the clean material 60 px to its right.
#  - Missing bottom-row pixels are copied from the same row further left.
#  - A soft lever shadow is added right after the current lever (x 95..110).
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$drives=Join-Path $root 'assets/front/drives'
$backup=Join-Path $drives 'archive/before-shared-masters-2026-11-15/masters/disk-materials'
$target=Join-Path $drives 'archive/disk-materials'
$top=64;$bottom=69;$left=35;$right=415
$shadowStart=95;$shadowEnd=110;$shadowDepth=0.42
foreach($color in @('black','yellow','green','blue','red')){
    $file=[Drawing.Bitmap]::FromFile((Join-Path $backup "drive-a-closed-$color.png"))
    $b=[Drawing.Bitmap]::new($file);$file.Dispose()
    for($y=$top;$y -le $bottom;$y++){
        for($x=75;$x -le 134;$x++){$b.SetPixel($x,$y,$b.GetPixel(($x+60),$y))}
        for($x=$left;$x -le ($right+1);$x++){
            if($b.GetPixel($x,$y).A -eq 255){continue}
            $c=$b.GetPixel($x,$y)
            for($k=1;$c.A -lt 255 -and $k -le 60;$k++){$c=$b.GetPixel(($x-$k),$y)}
            if($c.A -lt 255){throw "Cannot fill $x,$y ($color)"}
            $b.SetPixel($x,$y,$c)
        }
        for($x=$shadowStart;$x -le $shadowEnd;$x++){
            $t=($x-$shadowStart)/[double]($shadowEnd-$shadowStart+1)
            $f=1-$shadowDepth*(1-$t)*(1-$t)
            $c=$b.GetPixel($x,$y)
            $b.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,[int]($c.R*$f),[int]($c.G*$f),[int]($c.B*$f)))
        }
    }
    $b.Save((Join-Path $target "disk-$color.png"),[Drawing.Imaging.ImageFormat]::Png);$b.Dispose()
}
Write-Output 'Repaired five disk materials from the pristine backups.'
