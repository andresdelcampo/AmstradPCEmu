# Derives the purple disk material (system disc 5, hard disc utilities) from the
# blue one: same strip, shading and lever shadow, recoloured to the jacket
# purple of assets/front/disks/disk-hdutils-5.png. No purple source photo
# exists. Run before apply-drive-masters.ps1.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$dir=Join-Path (Split-Path -Parent $PSScriptRoot) 'assets/front/drives/archive/disk-materials'
$file=[Drawing.Bitmap]::FromFile((Join-Path $dir 'disk-blue.png'))
$b=[Drawing.Bitmap]::new($file);$file.Dispose()
$target=[Drawing.ColorTranslator]::FromHtml('#7B3FA6')
# Scale each pixel's brightness against the blue strip's average, so the
# material keeps its grain and shadow around the target colour.
$sum=0.0;$n=0
for($y=0;$y -lt $b.Height;$y++){for($x=0;$x -lt $b.Width;$x++){$c=$b.GetPixel($x,$y);if($c.A -eq 255){$sum+=$c.GetBrightness();$n++}}}
$mean=$sum/$n
for($y=0;$y -lt $b.Height;$y++){
    for($x=0;$x -lt $b.Width;$x++){
        $c=$b.GetPixel($x,$y);if($c.A -eq 0){continue}
        $f=$c.GetBrightness()/$mean
        $b.SetPixel($x,$y,[Drawing.Color]::FromArgb($c.A,[int][Math]::Min(255,$target.R*$f),[int][Math]::Min(255,$target.G*$f),[int][Math]::Min(255,$target.B*$f)))
    }
}
$b.Save((Join-Path $dir 'disk-purple.png'),[Drawing.Imaging.ImageFormat]::Png);$b.Dispose()
Write-Output 'Made the purple disk material from the blue one.'
