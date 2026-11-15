$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$frontPath = Join-Path $root 'assets/front/pc1512-front.png'
$SourceImage = Join-Path $root 'assets/front/backups/pc1512-front-before-grille.png'
$GeneratedImage = Join-Path $root 'assets/front/backups/pc1512-front-grille-generated.png'
$source = [Drawing.Bitmap]::FromFile($SourceImage)
$generated = [Drawing.Bitmap]::FromFile($GeneratedImage)
if ($source.Width -ne 1254 -or $source.Height -ne 1254 -or
    $generated.Width -ne 1254 -or $generated.Height -ne 1254) {
    throw 'Expected matching 1254 x 1254 images.'
}

function Copy-Pixels([Drawing.Bitmap]$from, [Drawing.Bitmap]$to) {
    $rect = [Drawing.Rectangle]::new(0, 0, 1254, 1254)
    $format = [Drawing.Imaging.PixelFormat]::Format32bppArgb
    $src = $from.LockBits($rect, [Drawing.Imaging.ImageLockMode]::ReadOnly, $format)
    $dst = $to.LockBits($rect, [Drawing.Imaging.ImageLockMode]::WriteOnly, $format)
    try {
        $row = [byte[]]::new(1254 * 4)
        for ($y = 0; $y -lt 1254; $y++) {
            [Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($src.Scan0, $y * $src.Stride), $row, 0, $row.Length)
            [Runtime.InteropServices.Marshal]::Copy($row, 0, [IntPtr]::Add($dst.Scan0, $y * $dst.Stride), $row.Length)
        }
    } finally { $from.UnlockBits($src); $to.UnlockBits($dst) }
}

$result = [Drawing.Bitmap]::new(1254, 1254, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
Copy-Pixels $source $result
try {
    # Use only the generated lower apron, stretched vertically so the grille
    # reads at the same scale as the photographed machine. Keep the original
    # badge, drives, monitor and every overlay anchor byte-for-byte intact.
    for ($y = 1223; $y -lt 1254; $y++) {
        $sy = 1218 + [int][Math]::Round(($y - 1223) * 0.70)
        # The wide front lip overhangs a narrower base. Only the base itself
        # has a slight molded taper; it does not run diagonally from the
        # cabinet's outer corners down to the vents.
        $left = 150 + [int][Math]::Round(($y - 1223) * 0.40)
        $right = 1104 - [int][Math]::Round(($y - 1223) * 0.40)
        for ($x = 90; $x -le 1164; $x++) {
            $color = [Drawing.Color]::FromArgb(0, 0, 0, 0)
            if ($y -lt 1247 -and $x -ge $left -and $x -le $right) {
                $sample = $generated.GetPixel($x, $sy)
                # Generated exterior pixels have stray opaque speckles. The
                # original cutout defines the broad upper corners; below it,
                # the apron has a clean tapered silhouette.
                if ($sample.A -gt 150) {
                    $edge = [Math]::Min($x - $left, $right - $x)
                    $alpha = [Math]::Min(255, [int]($edge * 128))
                    # A shallow recess under the front lip: strongest at the
                    # top seam, settling to a small shade change below.
                    $shade = [Math]::Max(8, 36 - 4 * ($y - 1223))
                    $color = [Drawing.Color]::FromArgb($alpha,
                        [Math]::Max(0, $sample.R - $shade),
                        [Math]::Max(0, $sample.G - $shade),
                        [Math]::Max(0, $sample.B - $shade))
                }
            }
            $result.SetPixel($x, $y, $color)
        }
    }

    # The left bank is 8 open + 2 molded closed + 9 open; the right bank
    # mirrors it as 9 open + 2 closed + 8 open. Leave a solid case section
    # between the banks, as in the full front photograph.
    for ($y = 1223; $y -le 1245; $y++) {
        $row = $result.GetPixel(630, $y)
        for ($x = 225; $x -le 1028; $x++) {
            $light = [int][Math]::Round(4 * [Math]::Abs($x - 630) / 405)
            $base = [Drawing.Color]::FromArgb(255, $row.R + $light, $row.G + $light, $row.B + $light)
            $result.SetPixel($x, $y, $base)
        }
    }
    $banks = @(
        @{ Start = 230; Open = @((0..7) + (10..18)); Closed = @(8, 9) },
        @{ Start = 687; Open = @((0..8) + (11..18)); Closed = @(9, 10) }
    )
    foreach ($bank in $banks) {
        foreach ($index in $bank.Open) {
            $slotX = $bank.Start + 18 * $index
            for ($y = 1228; $y -le 1245; $y++) {
                for ($dx = 0; $dx -lt 10; $dx++) {
                    $base = $result.GetPixel($slotX + $dx, $y)
                    if ($dx -eq 0) {
                        $color = [Drawing.Color]::FromArgb(255, $base.R - 28, $base.G - 27, $base.B - 24)
                    } elseif ($dx -eq 9) {
                        $color = [Drawing.Color]::FromArgb(255, $base.R + 25, $base.G + 24, $base.B + 20)
                    } elseif ($dx -eq 1 -or $dx -eq 8) {
                        $color = [Drawing.Color]::FromArgb(255, 73, 58, 45)
                    } elseif ($y -eq 1228) {
                        $color = [Drawing.Color]::FromArgb(255, 88, 69, 52)
                    } elseif ($y -ge 1244) {
                        $color = [Drawing.Color]::FromArgb(255, 67, 52, 38)
                    } else {
                        $color = [Drawing.Color]::FromArgb(255, 29 + [int](($y - 1229) / 3), 22 + [int](($y - 1229) / 4), 16 + [int](($y - 1229) / 5))
                    }
                    $result.SetPixel($slotX + $dx, $y, $color)
                }
            }
        }
        foreach ($index in $bank.Closed) {
            $closedX = $bank.Start + 18 * $index
            for ($y = 1228; $y -le 1245; $y++) {
                foreach ($dx in 0, 9) {
                    $base = $result.GetPixel($closedX + $dx, $y)
                    $shade = if ($dx -eq 0) { 14 } else { -10 }
                    $result.SetPixel($closedX + $dx, $y, [Drawing.Color]::FromArgb(255,
                        [Math]::Min(255, [Math]::Max(0, $base.R - $shade)),
                        [Math]::Min(255, [Math]::Max(0, $base.G - $shade)),
                        [Math]::Min(255, [Math]::Max(0, $base.B - $shade))))
                }
            }
        }
    }

    # Bring the complete recessed grille a touch deeper into shadow,
    # including the open slots and molded closed positions. The existing
    # top-to-bottom shade still makes the upper edge darkest.
    for ($y = 1223; $y -le 1246; $y++) {
        $left = 150 + [int][Math]::Round(($y - 1223) * 0.40)
        $right = 1104 - [int][Math]::Round(($y - 1223) * 0.40)
        for ($x = $left; $x -le $right; $x++) {
            $pixel = $result.GetPixel($x, $y)
            if ($pixel.A -eq 0) { continue }
            $result.SetPixel($x, $y, [Drawing.Color]::FromArgb($pixel.A,
                [Math]::Max(0, $pixel.R - 6),
                [Math]::Max(0, $pixel.G - 6),
                [Math]::Max(0, $pixel.B - 6)))
        }
    }

    $g = [Drawing.Graphics]::FromImage($result)
    try {
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        # The real machine has low pads under the apron, not tall cylinders.
        foreach ($foot in @(@(168, 48), @(611, 34), @(1038, 48))) {
            $outer = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(210, 69, 65, 56))
            $inner = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(225, 118, 111, 93))
            try {
                $g.FillEllipse($outer, $foot[0], 1246, $foot[1], 7)
                $g.FillEllipse($inner, $foot[0] + 3, 1246, $foot[1] - 6, 3)
            } finally { $outer.Dispose(); $inner.Dispose() }
        }
    } finally { $g.Dispose() }

    $source.Dispose()
    $generated.Dispose()
    $tempPath = Join-Path $root 'assets/front/pc1512-front-bottom-new.png'
    $result.Save($tempPath, [Drawing.Imaging.ImageFormat]::Png)
    Copy-Item -LiteralPath $tempPath -Destination $frontPath -Force
    Remove-Item -LiteralPath $tempPath

    $iconPath = Join-Path $root 'assets/front/pc1512-icon-cutout.png'
    $icon = [Drawing.Bitmap]::FromFile($iconPath)
    $iconResult = [Drawing.Bitmap]::new(1254, 1254, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        Copy-Pixels $icon $iconResult
        $iconGraphics = [Drawing.Graphics]::FromImage($iconResult)
        try {
            $iconGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $strip = [Drawing.Rectangle]::new(0, 1218, 1254, 36)
            $iconGraphics.DrawImage($result, $strip, $strip, [Drawing.GraphicsUnit]::Pixel)
        } finally { $iconGraphics.Dispose() }
        $icon.Dispose()
        $iconTempPath = Join-Path $root 'assets/front/pc1512-icon-bottom-new.png'
        $iconResult.Save($iconTempPath, [Drawing.Imaging.ImageFormat]::Png)
        Copy-Item -LiteralPath $iconTempPath -Destination $iconPath -Force
        Remove-Item -LiteralPath $iconTempPath
    } finally { $iconResult.Dispose() }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($frontPath))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    foreach ($relative in @('assets/front/configurations.json', 'assets/front/drives/placement.json', 'assets/front/leds/placement.json')) {
        $path = Join-Path $root $relative
        $json = [IO.File]::ReadAllText($path)
        $json = [regex]::Replace($json, '("front_sha256"\s*:\s*")[a-f0-9]+(")', '${1}' + $hash + '${2}')
        [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false))
    }
    & rtk proxy magick $iconPath -define icon:auto-resize=256,128,96,64,48,32,24,16 (Join-Path $root 'assets/front/pc1512-front.ico')
    if ($LASTEXITCODE -ne 0) { throw 'Could not regenerate the front icon.' }
    Write-Output "Updated lower apron only; front SHA-256: $hash"
} finally {
    $result.Dispose()
}
