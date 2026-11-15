$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$before=[Drawing.Bitmap]::FromFile((Join-Path $root 'local/artwork/case-edge/before.png'))
$lighting=[Drawing.Bitmap]::FromFile((Join-Path $root 'local/artwork/case-edge/generated-soft-highlight.png'))
$result=$before.Clone()
for($y=921;$y -le 943;$y++){for($x=108;$x -le 1146;$x++){
    $old=$before.GetPixel($x,$y);$new=$lighting.GetPixel($x,$y)
    $mask=[Math]::Max(0.0,[Math]::Min(1.0,[Math]::Min([Math]::Min(($x-108)/16.0,(1146-$x)/16.0),[Math]::Min(($y-921)/3.0,(943-$y)/4.0))))
    $mask*=[Math]::Max(0.0,[Math]::Min(1.0,($old.R-222)/25.0))
    $ratio=[Math]::Max(0.86,[Math]::Min(0.97,($new.R+$new.G+$new.B)/[double]($old.R+$old.G+$old.B)))
    $gain=1-$mask*(1-$ratio)
    $result.SetPixel($x,$y,[Drawing.Color]::FromArgb(255,[int][Math]::Round($old.R*$gain),[int][Math]::Round($old.G*$gain),[int][Math]::Round($old.B*$gain)))
}}
$result.Save((Join-Path $root 'assets/front/pc1512-front-v20.png'),[Drawing.Imaging.ImageFormat]::Png)
$sheet=[Drawing.Bitmap]::new(1100,250);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(28,29,32));$font=[Drawing.Font]::new('Segoe UI',12)
$g.DrawString('Before - bright bevel',$font,[Drawing.Brushes]::White,8,0)
$g.DrawImage($before,[Drawing.Rectangle]::new(0,25,1100,95),[Drawing.Rectangle]::new(77,870,1100,95),[Drawing.GraphicsUnit]::Pixel)
$g.DrawString('After - softer highlight, original geometry and detail',$font,[Drawing.Brushes]::White,8,125)
$g.DrawImage($result,[Drawing.Rectangle]::new(0,150,1100,95),[Drawing.Rectangle]::new(77,870,1100,95),[Drawing.GraphicsUnit]::Pixel)
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $root 'assets/front/case-highlight-comparison.png'));$sheet.Dispose()
$before.Dispose();$lighting.Dispose();$result.Dispose()
Copy-Item -LiteralPath (Join-Path $root 'assets/front/pc1512-front-v20.png') -Destination (Join-Path $root 'assets/front/pc1512-front.png')
Write-Output 'Softened only the case bevel highlight; original geometry and texture retained. Saved v20 and comparison.'
