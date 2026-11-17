$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$frontPath = Join-Path $root 'assets/front/pc1512-front.png'
$sourcePath = Join-Path $root 'assets/front/leds/power-panel-source.png'
$front = [Drawing.Bitmap]::FromFile($frontPath)
$source = [Drawing.Bitmap]::FromFile($sourcePath)
if ($front.Width -ne 1254 -or $front.Height -ne 1254 -or $source.Width -ne 176 -or $source.Height -ne 64) {
    throw 'Unexpected power panel dimensions.'
}

function Mix([Drawing.Color]$a, [Drawing.Color]$b, [double]$weight) {
    $weight = [Math]::Max(0.0, [Math]::Min(1.0, $weight))
    return [Drawing.Color]::FromArgb(
        [int][Math]::Round($a.A*(1-$weight)+$b.A*$weight),
        [int][Math]::Round($a.R*(1-$weight)+$b.R*$weight),
        [int][Math]::Round($a.G*(1-$weight)+$b.G*$weight),
        [int][Math]::Round($a.B*(1-$weight)+$b.B*$weight))
}

function PanelPixel([int]$x, [int]$y) {
    return $source.GetPixel($x-160, $y-956)
}

try {
    # Restore the exact source panel first, making this transformation repeatable.
    for ($y=960; $y -lt 1008; $y++) {
        for ($x=208; $x -lt 304; $x++) {
            $front.SetPixel($x, $y, (PanelPixel $x $y))
        }
    }

    # Replace the former large lens with nearby grey panel from both sides.
    for ($y=970; $y -le 1004; $y++) {
        for ($x=214; $x -le 250; $x++) {
            $left = PanelPixel ($x-40) $y
            $right = PanelPixel ($x+80) $y
            $background = Mix $left $right 0.5
            $edge = [Math]::Min([Math]::Min($x-214,250-$x),[Math]::Min($y-970,1004-$y))
            $front.SetPixel($x,$y,(Mix (PanelPixel $x $y) $background ($edge/3.0)))
        }
    }

    # Clear the old label using the same panel just below it.
    for ($y=977; $y -le 998; $y++) {
        for ($x=247; $x -le 297; $x++) {
            $background = PanelPixel $x ($y+20)
            $edge = [Math]::Min([Math]::Min($x-247,297-$x),[Math]::Min($y-977,998-$y))
            $front.SetPixel($x,$y,(Mix ($front.GetPixel($x,$y)) $background ($edge/2.0)))
        }
    }

    # Scale the original lens, including its mounting shadow and pale rim.
    $lens = [Drawing.Bitmap]::new(18,18,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($lens)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,18,18),[Drawing.Rectangle]::new(60,18,24,24),[Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    for ($y=0; $y -lt 18; $y++) {
        for ($x=0; $x -lt 18; $x++) {
            $radius = [Math]::Sqrt([Math]::Pow($x-8.5,2)+[Math]::Pow($y-8.5,2))
            $weight = (9.0-$radius)/1.5
            $front.SetPixel(215+$x,980+$y,(Mix ($front.GetPixel(215+$x,980+$y)) ($lens.GetPixel($x,$y)) $weight))
        }
    }
    $lens.Dispose()

    # Move the original letter shapes left and two pixels down without changing their size or font.
    $ink = [Drawing.Color]::FromArgb(17,17,16)
    for ($y=979; $y -le 996; $y++) {
        for ($x=249; $x -le 296; $x++) {
            $original = PanelPixel $x $y
            $background = PanelPixel $x ($y+20)
            $originalLuma = 0.2126*$original.R + 0.7152*$original.G + 0.0722*$original.B
            $backgroundLuma = 0.2126*$background.R + 0.7152*$background.G + 0.0722*$background.B
            $inkAlpha = ($backgroundLuma-$originalLuma)/100.0
            if ($inkAlpha -gt 0) {
                $front.SetPixel($x-11,$y+2,(Mix ($front.GetPixel($x-11,$y+2)) $ink $inkAlpha))
            }
        }
    }

    $temporary = $frontPath + '.resize-power-led.tmp.png'
    $front.Save($temporary,[Drawing.Imaging.ImageFormat]::Png)
} finally {
    $source.Dispose()
    $front.Dispose()
}
Move-Item -LiteralPath $temporary -Destination $frontPath -Force
Write-Output 'Resized power lens and moved its existing lettering; all other front pixels preserved.'
