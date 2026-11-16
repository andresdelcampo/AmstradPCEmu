$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
# The cabinet picture was painted with both drives closed, so each lever left a
# soft shadow on the grey panel just below its bay. The bays are redrawn by
# state patches (open, closed, blank, HDD) that stop at the bay edge, so that
# shadow stayed visible in every state. Remove it from the cabinet itself.
#
# Each row of the shadow area is rebuilt as a straight blend between the clean
# panel on its left and right, plus the fine grain of the clean strip beside
# it, so the panel's vertical shading and texture are preserved.
$root=Split-Path -Parent $PSScriptRoot
$frontPath=Join-Path $root 'assets/front/pc1512-front.png'
$x0=232;$x1=292;$y0=1134;$y1=1170;$edge=6;$grainShift=66
$file=[Drawing.Bitmap]::FromFile($frontPath)
$b=[Drawing.Bitmap]::new($file.Width,$file.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[Drawing.Graphics]::FromImage($b);$g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.DrawImage($file,[Drawing.Rectangle]::new(0,0,$file.Width,$file.Height));$g.Dispose();$file.Dispose()
function Mean($b,$xa,$xb,$y){
    $r=0.0;$gr=0.0;$bl=0.0;$n=$xb-$xa+1
    for($x=$xa;$x -le $xb;$x++){$p=$b.GetPixel($x,$y);$r+=$p.R;$gr+=$p.G;$bl+=$p.B}
    return @(($r/$n),($gr/$n),($bl/$n))
}
function Clamp($v){return [int][Math]::Max(0,[Math]::Min(255,[Math]::Round($v)))}
foreach($bay in 0,458){
    for($y=$y0;$y -le $y1;$y++){
        $left=Mean $b ($x0+$bay-$edge) ($x0+$bay-1) $y
        $right=Mean $b ($x1+$bay+1) ($x1+$bay+$edge) $y
        $grainMean=Mean $b ($x0+$bay+$grainShift) ($x1+$bay+$grainShift) $y
        for($x=$x0;$x -le $x1;$x++){
            $t=($x-$x0+0.5)/($x1-$x0+1)
            $s=$b.GetPixel($x+$bay+$grainShift,$y)
            $a=$b.GetPixel($x+$bay,$y).A
            $r=$left[0]+($right[0]-$left[0])*$t+($s.R-$grainMean[0])
            $gr=$left[1]+($right[1]-$left[1])*$t+($s.G-$grainMean[1])
            $bl=$left[2]+($right[2]-$left[2])*$t+($s.B-$grainMean[2])
            $b.SetPixel($x+$bay,$y,[Drawing.Color]::FromArgb($a,(Clamp $r),(Clamp $gr),(Clamp $bl)))
        }
    }
}
$b.Save($frontPath,[Drawing.Imaging.ImageFormat]::Png);$b.Dispose()
Write-Output 'Removed lever shadow under both bays.'
