# Draws the menu pictures of the Amstrad system discs: a 5.25" disc seen
# straight on, seated in its short "AMSTRAD PC System Discs" pocket sleeve.
# Disc and label are vector-drawn with System.Drawing and supersampled; the
# sleeve's white artwork is a cleaned trace of a straightened photo of the
# original set. All coordinates are in that photo's 920 x 880 frame.
# Output: assets/front/disks/<id>.png (RGBA, transparent).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/make-disk-assets.ps1 [-Width 640]

param(
    [int]$Width = 640,      # output width in pixels; height follows (880/920)
    [int]$Super = 4,        # supersampling factor
    [string]$OutDir = (Join-Path $PSScriptRoot '..\assets\front\disks')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$C = [char]0xA9   # (c)
$R = [char]0xAE   # (R), drawn as a small superscript

$disks = @(
    @{
        Id     = 'disk-msdos-1'
        Jacket = @('#D3222C', '#BC1A25')
        Part   = '46001/A'
        Title  = @("DISC 1. MICROSOFT$R MS-DOS$R", 'OPERATING SYSTEM', 'STARTUP & UTILITIES V3.2')
        Small  = @("$C 1986 Amstrad Consumer Electronics plc.", 'Programs', "$C Microsoft$R Corporation, 1981-85.", 'All Rights Reserved')
    }
)

# ---- geometry in the reference frame ----
$BW = 920; $BH = 880
$disk   = @{ X = 50; Y = 35;  W = 820; H = 820 }
$sleeve = @{ X = 20; Y = 270; W = 880; H = 585 }
$label  = @{ X = 62; Y = 44;  W = 320; H = 198 }
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

function Draw-Disk($d, [string]$path) {
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
    $sg.FillRectangle($sb, $disk.X + 5, $disk.Y + 9, $disk.W, 300)
    $sg.FillRectangle($sb, $sleeve.X + 5, $sleeve.Y + 9, $sleeve.W, $sleeve.H)
    $sg.Dispose()
    $g.DrawImage($small, 0, 0, $big.Width, $big.Height)
    $small.Dispose()

    $g.ScaleTransform($k * $Super, $k * $Super)

    # -- disc jacket (only the part above the sleeve shows) --
    $jp = RoundRect $disk.X $disk.Y $disk.W $disk.H 5
    $g.FillPath((VGrad $disk.X $disk.Y $disk.W 260 $d.Jacket[0] $d.Jacket[1]), $jp)
    $g.DrawLine((New-Object Drawing.Pen (Col '#FFFFFF' 70), 2), $disk.X + 5, $disk.Y + 1.5, $disk.X + $disk.W - 5, $disk.Y + 1.5)
    $g.DrawPath((New-Object Drawing.Pen (Col '#000000' 60), 1.6), $jp)

    # write-protect foil tab on the right edge, running down into the sleeve
    $tx = $disk.X + $disk.W - 68; $ty = 205; $tw = 68; $th = 70
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
    foreach ($line in $d.Small) {
        LabelLine $g $line 'Arial Narrow' 18.5 ([int][Drawing.FontStyle]::Regular) $ink ($label.X + 16) $y
        $y += 20.5
    }
    LabelLine $g $d.Part 'Arial Narrow' 10 ([int][Drawing.FontStyle]::Bold) $ink ($label.X + $label.W - 52) ($label.Y + $label.H - 17)

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
}
