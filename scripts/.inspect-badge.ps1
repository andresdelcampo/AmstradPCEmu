Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$base = [Drawing.Bitmap]::FromFile((Join-Path $root 'assets/front/pc1512-front.png'))
foreach ($name in @('dd', 'sd', 'hd20')) {
    $image = $base.Clone()
    if ($name -ne 'dd') {
        $overlay = [Drawing.Bitmap]::FromFile((Join-Path $root "assets/front/badges/model-$name.png"))
        $g = [Drawing.Graphics]::FromImage($image)
        $g.DrawImageUnscaled($overlay, 870, 1164)
        $g.Dispose(); $overlay.Dispose()
    }
    $pixels = @()
    for ($y=1186; $y -le 1212; $y++) {
        for ($x=994; $x -le 1068; $x++) {
            $c = $image.GetPixel($x,$y)
            if ($c.R - [Math]::Max($c.G,$c.B) -gt 25) {
                $pixels += [pscustomobject]@{x=$x;y=$y;r=$c.R;g=$c.G;b=$c.B;d=($c.R-[Math]::Max($c.G,$c.B))}
            }
        }
    }
    $top = $pixels | Sort-Object d -Descending | Select-Object -First 50
    $avg = $top | Measure-Object -Property r,g,b -Average
    $rv = [int][Math]::Round(($top | Measure-Object r -Average).Average)
    $gv = [int][Math]::Round(($top | Measure-Object g -Average).Average)
    $bv = [int][Math]::Round(($top | Measure-Object b -Average).Average)
    $allR = [int][Math]::Round(($pixels | Measure-Object r -Average).Average)
    $allG = [int][Math]::Round(($pixels | Measure-Object g -Average).Average)
    $allB = [int][Math]::Round(($pixels | Measure-Object b -Average).Average)
    $xs = $pixels.x | Measure-Object -Minimum -Maximum
    $ys = $pixels.y | Measure-Object -Minimum -Maximum
    Write-Output "$name bbox=$($xs.Minimum),$($ys.Minimum)..$($xs.Maximum),$($ys.Maximum) count=$($pixels.Count) top50=($rv,$gv,$bv) all=($allR,$allG,$allB)"
    $image.Dispose()
}
$base.Dispose()
