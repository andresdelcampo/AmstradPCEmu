$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $root 'assets/front'
$badges = Join-Path $assets 'badges'

# Preview composition only: never call a badge or cabinet artwork generator.
$sources = @(Get-ChildItem $assets -Recurse -File | Where-Object { $_.Name -notlike '*preview*' })
$hashes = @{}
function SourceHash([string]$path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($path))) } finally { $sha.Dispose() }
}
foreach ($source in $sources) { $hashes[$source.FullName] = SourceHash $source.FullName }
$front = [Drawing.Bitmap]::FromFile((Join-Path $assets 'pc1512-front.png'))
function CompositeBadge([Drawing.Rectangle]$crop, [string[]]$overlays) {
    $badge = $front.Clone($crop, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($badge)
    foreach ($name in $overlays) {
        $overlay = [Drawing.Bitmap]::FromFile((Join-Path $badges $name))
        try { $g.DrawImageUnscaled($overlay, 0, 0) } finally { $overlay.Dispose() }
    }
    $g.Dispose()
    return $badge
}
function SavePreview($bitmap, [string]$name) {
    $bitmap.Save((Join-Path $badges $name), [Drawing.Imaging.ImageFormat]::Png)
}
function DrawEnlarged($g, $badge, [Drawing.Rectangle]$destination) {
    # Show the actual asset pixels, without adding smoothing to the preview.
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($badge, $destination, [Drawing.Rectangle]::new(0, 0, $badge.Width, $badge.Height), [Drawing.GraphicsUnit]::Pixel)
}

try {
    $font = [Drawing.Font]::new('Segoe UI', 13)
    foreach ($layout in @(
        @{ name = 'monitor-options-preview.png'; labels = @('CM', 'MM', 'MD', 'CD', 'ECD'); width = 1050; height = 630; column = 525; top = 28; inset = 8; row = 210 },
        @{ name = 'monitor-preview.png'; labels = @('CM', 'MM'); width = 840; height = 210; column = 420; top = 25; inset = 0; row = 210 }
    )) {
        $sheet = [Drawing.Bitmap]::new($layout.width, $layout.height)
        $g = [Drawing.Graphics]::FromImage($sheet)
        $g.Clear([Drawing.Color]::FromArgb(28, 29, 32))
        for ($i = 0; $i -lt $layout.labels.Count; $i++) {
            $label = $layout.labels[$i]
            $badge = CompositeBadge ([Drawing.Rectangle]::new(923, 743, 140, 60)) @('monitor-' + $label.ToLowerInvariant() + '.png')
            $x = ($i % 2) * $layout.column
            $y = [int][Math]::Floor($i / 2) * $layout.row
            $g.DrawString($label, $font, [Drawing.Brushes]::White, ($x + 8), ($y + 3))
            DrawEnlarged $g $badge ([Drawing.Rectangle]::new(($x + $layout.inset), ($y + $layout.top), 420, 180))
            $badge.Dispose()
        }
        $g.Dispose()
        SavePreview $sheet $layout.name
        $sheet.Dispose()
    }
    $font.Dispose()
    $crop = [Drawing.Rectangle]::new(870, 1164, 216, 76)
    $badge = CompositeBadge $crop @('system-1640.png', 'model-dd.png')
    SavePreview $badge 'pc1640-dd-preview.png'
    $badge.Dispose()
    $sheet = [Drawing.Bitmap]::new(1296, 1368)
    $g = [Drawing.Graphics]::FromImage($sheet)
    $i = 0
    foreach ($model in @('dd', 'sd', 'hd20')) {
        $badge = CompositeBadge $crop @('model-' + $model + '.png')
        DrawEnlarged $g $badge ([Drawing.Rectangle]::new(0, ($i * 456), 1296, 456))
        $badge.Dispose()
        $i++
    }
    $g.Dispose()
    SavePreview $sheet 'model-options-preview.png'
    SavePreview $sheet 'model-options-aligned-preview.png'
    $sheet.Dispose()
} finally { $front.Dispose() }

foreach ($source in $sources) {
    if ((SourceHash $source.FullName) -ne $hashes[$source.FullName]) {
        throw "Source asset changed: $($source.FullName)"
    }
}
Write-Output "Refreshed five badge composite previews; all $($sources.Count) source files are unchanged."
