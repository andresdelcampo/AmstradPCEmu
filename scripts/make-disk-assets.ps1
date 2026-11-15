# Draws the menu pictures of the Amstrad system discs: a 5.25" disc seen
# straight on, seated in its short "AMSTRAD PC System Discs" pocket sleeve.
# Disc and label are vector-drawn with System.Drawing and supersampled; the
# sleeve's white artwork is a cleaned trace of a straightened photo of the
# original set. All coordinates are in that photo's 924 x 895 frame.
# Output: assets/front/disks/<id>.png in the sleeve and <id>-bare.png without
# it, on the same canvas and at the same scale (RGBA, transparent).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/make-disk-assets.ps1 [-Width 640]

param(
    [int]$Width = 640,      # output width in pixels; height follows (895/924)
    [int]$Super = 4,        # supersampling factor
    [string]$OutDir = (Join-Path $PSScriptRoot '..\assets\front\disks')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$C = [char]0xA9   # (c)
$R = [char]0xAE   # (R), drawn as a small superscript
$T = [char]0x2122 # TM

$amstrad = "$C 1986 Amstrad Consumer Electronics plc."
$dri     = "$C Copyright Digital Research Inc. 1985/86."
$ms      = "$C Microsoft$R Corporation, 1981-85."
$arr     = 'All Rights Reserved'

# Small = fine-print lines; SmallSize/SmallStep shrink them when there are many.
$disks = @(
    @{
        Id     = 'disk-msdos-1'
        Jacket = @('#D3222C', '#BC1A25')
        Part   = '46001/A'
        Title  = @("DISC 1. MICROSOFT$R MS-DOS$R", 'OPERATING SYSTEM', 'STARTUP & UTILITIES V3.2')
        Small  = @($amstrad, 'Programs', $ms, $arr)
    },
    @{
        Id     = 'disk-gem-startup-2'
        Jacket = @('#2F72C8', '#2560AE')
        Part   = '46002/A'
        Title  = @("DISC 2. GEM$T STARTUP v2.0U")
        Small  = @($amstrad, 'Programs', $dri, $arr, $ms, $arr)
    },
    @{
        Id     = 'disk-gem-desktop-3'
        Jacket = @('#1F9A52', '#178444')
        Part   = '46003/A'
        Title  = @("DISC 3. GEM DESKTOP$T V2.0U", "/Locomotive BASIC2$T v1.0")
        Small  = @($amstrad, 'Programs', $dri, $arr, $ms, $arr, "$C 1986 Locomotive Software Ltd.")
        SmallSize = 16.5; SmallStep = 17.6
    },
    @{
        Id     = 'disk-dosplus-4'
        Jacket = @('#F3D530', '#E2C11F')
        Part   = '46004/A'
        Title  = @("DISC 4. DOS Plus$T", 'STARTUP & UTILITIES v1.2', "/GEM PAINT$T v1.0U")
        Small  = @($amstrad, 'Programs', $dri, $arr)
    }
)

# ---- geometry in the reference frame ----
$BW = 924; $BH = 895
$disk   = @{ X = 46; Y = 35;  W = 825; H = 825 }
$sleeve = @{ X = 20; Y = 278; W = 884; H = 592 }
$back   = @{ X = 20; Y = 50;  W = 884 }               # white rear panel of the sleeve, behind the disc
$label  = @{ X = 58; Y = 48;  W = 316; H = 198 }
$navy   = '#17172F'

function Col([string]$hex, [int]$a = 255) {
    $c = [Drawing.ColorTranslator]::FromHtml($hex)
    [Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B)
}
function RoundRect([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    $p
}
function VGrad($x, $y, $w, $h, [string]$top, [string]$bottom) {
    $r = New-Object Drawing.RectangleF ([single]$x), ([single]($y - 1)), ([single]$w), ([single]($h + 2))
    New-Object Drawing.Drawing2D.LinearGradientBrush $r, (Col $top), (Col $bottom), 90.0
}
# Text as a path, stretched to fill the target box exactly.
function TextPath([string]$text, [string]$family, [int]$style, $x, $y, $w, $h) {
    $p = New-Object Drawing.Drawing2D.GraphicsPath
    $ff = New-Object Drawing.FontFamily $family
    $p.AddString($text, $ff, $style, 100, (New-Object Drawing.PointF 0, 0), [Drawing.StringFormat]::GenericTypographic)
    $b = $p.GetBounds()
    $m = New-Object Drawing.Drawing2D.Matrix
    $m.Translate([single]$x, [single]$y)
    $m.Scale([single]($w / $b.Width), [single]($h / $b.Height))
    $m.Translate(-$b.X, -$b.Y)
    $p.Transform($m)
    $p
}
# One label line; the registered sign is drawn small and raised.
function LabelLine($g, [string]$text, [string]$family, [single]$size, [int]$style, $brush, [single]$x, [single]$y) {
    $fmt = [Drawing.StringFormat]::GenericTypographic.Clone()
    $fmt.FormatFlags = $fmt.FormatFlags -bor [Drawing.StringFormatFlags]::MeasureTrailingSpaces
    $font = New-Object Drawing.Font $family, $size, $style, ([Drawing.GraphicsUnit]::Pixel)
    $sup  = New-Object Drawing.Font 'Arial', ($size * 0.58), ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
    $parts = $text.Split($R)
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($parts[$i].Length) {
            $g.DrawString($parts[$i], $font, $brush, $x, $y, $fmt)
            $x += $g.MeasureString($parts[$i], $font, 9999, $fmt).Width
        }
        if ($i -lt $parts.Count - 1) {
            $g.DrawString([string]$R, $sup, $brush, $x + 0.5, $y - $size * 0.02, $fmt)
            $x += $g.MeasureString([string]$R, $sup, 9999, $fmt).Width + 1.5
        }
    }
    $font.Dispose(); $sup.Dispose()
}

# Openings of a bare 5.25" jacket: hub window, index hole, head slot (all
# showing the dark media), the punched centre hole and the two relief notches.
function Draw-Openings($g) {
    $u = $disk.W / 133.4                       # units per millimetre
    $mx = $disk.X + $disk.W / 2; $my = $disk.Y + $disk.H / 2
    $media = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.RectangleF $disk.X, $disk.Y, $disk.W, $disk.H), (Col '#3A322C'), (Col '#1D1917'), 60.0
    $rim = New-Object Drawing.Pen (Col '#000000' 110), 2.4
    $lip = New-Object Drawing.Pen (Col '#FFFFFF' 60), 1.6
    $cut = New-Object Drawing.Drawing2D.GraphicsPath

    $hubR = 19.9 * $u                          # hub window in the jacket
    $cut.AddEllipse([single]($mx - $hubR), [single]($my - $hubR), [single](2 * $hubR), [single](2 * $hubR))
    $idxR = 3.2 * $u; $idxD = 25.4 * $u        # index hole, right of the hub and a little up
    $ix = $mx + $idxD * [Math]::Cos(0.42); $iy = $my - $idxD * [Math]::Sin(0.42)
    $cut.AddEllipse([single]($ix - $idxR), [single]($iy - $idxR), [single](2 * $idxR), [single](2 * $idxR))
    $slotW = 12.7 * $u; $slotTop = $my + 24.5 * $u; $slotH = 33.5 * $u   # head slot, rounded ends
    $slot = RoundRect ($mx - $slotW / 2) $slotTop $slotW $slotH ($slotW / 2 - 0.01)
    $cut.AddPath($slot, $false)

    $g.FillPath($media, $cut)
    $g.DrawPath($rim, $cut)
    # light lower lips: the jacket has thickness
    $g.DrawArc($lip, [single]($mx - $hubR - 2), [single]($my - $hubR - 2), [single](2 * $hubR + 4), [single](2 * $hubR + 4), 20, 140)
    $g.DrawArc($lip, [single]($mx - $slotW / 2 - 2), [single]($slotTop + $slotH - $slotW - 2), [single]($slotW + 4), [single]($slotW + 4), 20, 140)

    # reinforcing hub ring on the media, then the centre hole right through
    $holeR = 14.3 * $u; $ringR = 17.2 * $u
    $ring = New-Object Drawing.Drawing2D.GraphicsPath
    $ring.AddEllipse([single]($mx - $ringR), [single]($my - $ringR), [single](2 * $ringR), [single](2 * $ringR))
    $g.FillPath((New-Object Drawing.SolidBrush (Col '#4A433D')), $ring)
    $g.DrawPath((New-Object Drawing.Pen (Col '#6A625A' 160), 1.4), $ring)

    $state = $g.Save()
    $g.SmoothingMode = 'None'                  # hard punch; supersampling smooths it
    $g.CompositingMode = 'SourceCopy'
    $clear = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.FillEllipse($clear, [single]($mx - $holeR), [single]($my - $holeR), [single](2 * $holeR), [single](2 * $holeR))
    $notchR = 1.6 * $u; $by = $disk.Y + $disk.H
    foreach ($nx in ($mx - 11.5 * $u), ($mx + 11.5 * $u)) {
        $g.FillEllipse($clear, [single]($nx - $notchR), [single]($by - $notchR), [single](2 * $notchR), [single](2 * $notchR))
    }
    $g.Restore($state)
    $g.DrawEllipse((New-Object Drawing.Pen (Col '#000000' 120), 1.6), [single]($mx - $holeR), [single]($my - $holeR), [single](2 * $holeR), [single](2 * $holeR))
}

function Draw-Disk($d, [string]$path, [bool]$bare = $false) {
    $k = $Width / $BW
    $big = New-Object Drawing.Bitmap ([int]($BW * $k * $Super)), ([int]($BH * $k * $Super)), ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($big)
    $g.SmoothingMode = 'AntiAlias'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'

    # -- soft drop shadow: drawn tiny, stretched back up so it blurs --
    $sw = [int]($BW / 16); $sh = [int]($BH / 16)
    $small = New-Object Drawing.Bitmap $sw, $sh, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $sg = [Drawing.Graphics]::FromImage($small)
    $sg.SmoothingMode = 'AntiAlias'
    $sg.ScaleTransform($sw / $BW, $sh / $BH)
    $sb = New-Object Drawing.SolidBrush (Col '#000000' 75)
    if ($bare) {
        $sg.FillRectangle($sb, $disk.X + 5, $disk.Y + 9, $disk.W, $disk.H)
    } else {
        $sg.FillPath($sb, (RoundRect ($back.X + 5) ($back.Y + 9) $back.W 300 44))
        $sg.FillRectangle($sb, $sleeve.X + 5, $sleeve.Y + 9, $sleeve.W, $sleeve.H)
    }
    $sg.Dispose()
    $g.DrawImage($small, 0, 0, $big.Width, $big.Height)
    $small.Dispose()

    $g.ScaleTransform($k * $Super, $k * $Super)

    if (-not $bare) {
    # -- sleeve rear panel: plain white card, taller than the printed front --
    $rearH = $sleeve.Y - $back.Y + 10
    $rp = New-Object Drawing.Drawing2D.GraphicsPath      # top corners are rounded
    $rr = 44; $rx2 = $back.X + $back.W; $ry2 = $back.Y + $rearH
    $rp.AddArc($back.X, $back.Y, 2 * $rr, 2 * $rr, 180, 90)
    $rp.AddArc($rx2 - 2 * $rr, $back.Y, 2 * $rr, 2 * $rr, 270, 90)
    $rp.AddLine($rx2, $ry2, $back.X, $ry2)
    $rp.CloseFigure()
    $g.FillPath((VGrad $back.X $back.Y $back.W $rearH '#F3F2EE' '#E4E3DE'), $rp)
    $g.DrawPath((New-Object Drawing.Pen (Col '#000000' 55), 1.4), $rp)
    # the disc's shadow on it
    $g.FillRectangle((New-Object Drawing.SolidBrush (Col '#000000' 40)), $disk.X + $disk.W, $disk.Y + 16, 5, $sleeve.Y - $disk.Y - 16)
    }

    # -- disc jacket (in the sleeve only the top part shows) --
    $jp = RoundRect $disk.X $disk.Y $disk.W $disk.H 5
    $shadeH = 260; if ($bare) { $shadeH = $disk.H }
    $g.FillPath((VGrad $disk.X $disk.Y $disk.W $shadeH $d.Jacket[0] $d.Jacket[1]), $jp)
    $g.DrawLine((New-Object Drawing.Pen (Col '#FFFFFF' 70), 2), $disk.X + 5, $disk.Y + 1.5, $disk.X + $disk.W - 5, $disk.Y + 1.5)
    $g.DrawPath((New-Object Drawing.Pen (Col '#000000' 60), 1.6), $jp)

    # write-protect foil tab on the right edge, running down into the sleeve
    $tx = $disk.X + $disk.W - 76; $ty = $sleeve.Y - 76; $tw = 76; $th = 80
    $foil = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.RectangleF ($tx - 1), ($ty - 1), ($tw + 2), ($th + 2)), (Col '#EBD98A'), (Col '#A8862E'), 55.0
    $g.FillRectangle($foil, $tx, $ty, $tw, $th)
    $crease = New-Object Drawing.Pen (Col '#FFF6C8' 150), 2
    $g.DrawLine($crease, $tx + 6, $ty + 14, $tx + 40, $ty + 4)
    $g.DrawLine($crease, $tx + 22, $ty + 46, $tx + 62, $ty + 24)
    $g.DrawLine((New-Object Drawing.Pen (Col '#6B5415' 110), 2), $tx + 10, $ty + 34, $tx + 50, $ty + 60)
    $g.DrawRectangle((New-Object Drawing.Pen (Col '#5E4A12' 120), 1.4), $tx, $ty, $tw, $th)

    # -- label --
    $lp = RoundRect $label.X $label.Y $label.W $label.H 9
    $g.FillPath((New-Object Drawing.SolidBrush (Col '#000000' 45)), (RoundRect ($label.X + 2) ($label.Y + 3) $label.W $label.H 9))
    $g.FillPath((VGrad $label.X $label.Y $label.W $label.H '#F6F1E2' '#EAE3D0'), $lp)
    $g.DrawPath((New-Object Drawing.Pen (Col '#B9B09A' 200), 1.4), $lp)
    $ink = New-Object Drawing.SolidBrush (Col '#1B1B22')
    $y = $label.Y + 14
    foreach ($line in $d.Title) {
        LabelLine $g $line 'Arial Narrow' 22 ([int][Drawing.FontStyle]::Bold) $ink ($label.X + 16) $y
        $y += 25
    }
    $y += 9
    $ss = 18.5; $st = 20.5
    if ($d.SmallSize) { $ss = $d.SmallSize; $st = $d.SmallStep }
    foreach ($line in $d.Small) {
        LabelLine $g $line 'Arial Narrow' $ss ([int][Drawing.FontStyle]::Regular) $ink ($label.X + 16) $y
        $y += $st
    }
    LabelLine $g $d.Part 'Arial Narrow' 10 ([int][Drawing.FontStyle]::Bold) $ink ($label.X + $label.W - 52) ($label.Y + $label.H - 17)

    if ($bare) { Draw-Openings $g } else {
    # -- sleeve --
    $state = $g.Save()
    $g.SetClip((New-Object Drawing.RectangleF $sleeve.X, $sleeve.Y, $sleeve.W, $sleeve.H))
    $g.FillRectangle((VGrad $sleeve.X $sleeve.Y $sleeve.W $sleeve.H '#1B1B38' '#14142B'), $sleeve.X, $sleeve.Y, $sleeve.W, $sleeve.H)

    # the white artwork (grid, AMSTRAD, PC, System Discs) is a clean trace of
    # the original sleeve: masters/sleeve-artwork.png, white with alpha
    $art = [Drawing.Image]::FromFile((Join-Path $OutDir 'masters\sleeve-artwork.png'))
    $g.DrawImage($art, [single]$sleeve.X, [single]$sleeve.Y, [single]$sleeve.W, [single]$sleeve.H)
    $art.Dispose()
    $g.Restore($state)

    # sleeve mouth: shade on the disc just above it, a light lip on the edge
    $shade = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.RectangleF $disk.X, ($sleeve.Y - 13), $disk.W, 14), (Col '#000000' 0), (Col '#000000' 95), 90.0
    $g.FillRectangle($shade, $disk.X, $sleeve.Y - 12, $disk.W, 12)
    $g.DrawLine((New-Object Drawing.Pen (Col '#4A4A72'), 2), $sleeve.X, $sleeve.Y + 1, $sleeve.X + $sleeve.W, $sleeve.Y + 1)
    $g.DrawRectangle((New-Object Drawing.Pen (Col '#000000' 90), 1.6), $sleeve.X + 0.8, $sleeve.Y + 0.8, $sleeve.W - 1.6, $sleeve.H - 1.6)
    }
    $g.Dispose()

    # -- downsample --
    $out = New-Object Drawing.Bitmap ([int]($BW * $k)), ([int]($BH * $k)), ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $og = [Drawing.Graphics]::FromImage($out)
    $og.InterpolationMode = 'HighQualityBicubic'
    $og.PixelOffsetMode = 'HighQuality'
    $og.CompositingMode = 'SourceCopy'
    $attr = New-Object Drawing.Imaging.ImageAttributes
    $attr.SetWrapMode('TileFlipXY')
    $og.DrawImage($big, (New-Object Drawing.Rectangle 0, 0, $out.Width, $out.Height), 0, 0, $big.Width, $big.Height, [Drawing.GraphicsUnit]::Pixel, $attr)
    $og.Dispose(); $big.Dispose()
    $out.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
    Write-Host "wrote $path"
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
foreach ($d in $disks) {
    Draw-Disk $d (Join-Path (Resolve-Path $OutDir) "$($d.Id).png")
    Draw-Disk $d (Join-Path (Resolve-Path $OutDir) "$($d.Id)-bare.png") $true
}
