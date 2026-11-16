$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$frontPath = Join-Path $root 'assets/front/pc1512-front.png'
$work = Join-Path $root 'local/artwork/fascia-lighting'
$referencePath = Join-Path $root 'assets/front/pc1512-fascia-lighting-reference.png'
$backupPath = Join-Path $work 'front-before-lighting.png'
if (!(Test-Path -LiteralPath $referencePath)) { throw "Missing approved preview: $referencePath" }
function FileHash([string]$path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($path)
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
}
$beforeHash = '74ef5fa02c96a0fd5d6d15454467224f446d36614d41fb2ed278a51287ad09d6'
$afterHash = '4e00e2ade6e034b7c7ca3e9e7d169fdbb22672b98b776c0402a077fe1a168a08'
$currentHash = FileHash $frontPath
if ($currentHash -eq $afterHash) { Write-Output 'Fascia lighting already applied.'; exit 0 }
if ($currentHash -ne $beforeHash) { throw 'Front differs from the expected source; refusing to replace later artwork.' }
New-Item -ItemType Directory -Force -Path $work | Out-Null
Copy-Item -LiteralPath $frontPath -Destination $backupPath -Force

$source = [Drawing.Bitmap]::FromFile($backupPath)
$reference = [Drawing.Bitmap]::FromFile($referencePath)
$result = $source.Clone([Drawing.Rectangle]::new(0, 0, $source.Width, $source.Height), $source.PixelFormat)

# Transfer only the approved preview's vertical light profile. Preserve every
# original contour, texture detail, hue variation, and alpha value.
for ($y = 912; $y -le 952; $y++) {
    $referenceY = [int][Math]::Round(320 + ($y - 915) * 2.25)
    $referenceY = [Math]::Max(0, [Math]::Min($reference.Height - 1, $referenceY))
    $referenceColor = $reference.GetPixel(1085, $referenceY)
    $sourceCenter = $source.GetPixel(625, $y)
    $verticalFade = [Math]::Min(1.0, [Math]::Min(($y - 912) / 7.0, (952 - $y) / 6.0))
    for ($x = 105; $x -le 1149; $x++) {
        $horizontalFade = [Math]::Min(1.0, [Math]::Min(($x - 105) / 65.0, (1149 - $x) / 65.0))
        $weight = $verticalFade * $horizontalFade
        if ($weight -le 0) { continue }
        $old = $source.GetPixel($x, $y)
        if ($old.A -eq 0) { continue }
        $r = [int][Math]::Round([Math]::Max(0, [Math]::Min(255, $old.R + ($referenceColor.R - $sourceCenter.R) * $weight)))
        $g = [int][Math]::Round([Math]::Max(0, [Math]::Min(255, $old.G + ($referenceColor.G - $sourceCenter.G) * $weight)))
        $b = [int][Math]::Round([Math]::Max(0, [Math]::Min(255, $old.B + ($referenceColor.B - $sourceCenter.B) * $weight)))
        $result.SetPixel($x, $y, [Drawing.Color]::FromArgb($old.A, $r, $g, $b))
    }
}

$source.Dispose()
$reference.Dispose()
$result.Save($frontPath, [Drawing.Imaging.ImageFormat]::Png)
$result.Dispose()

$hash = FileHash $frontPath
Write-Output "Applied fascia lighting; front SHA-256: $hash"
