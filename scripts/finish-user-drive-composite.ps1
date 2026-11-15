$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$masters=Join-Path $root 'assets/front/drives/masters'
$ownership=Get-Content (Join-Path $masters 'masters.json') -Raw | ConvertFrom-Json
if($ownership.closed_geometry_source -like '*manually corrected*'){throw 'closed-clean.png is manually corrected by the user. Rebuild dependents with apply-closed-drive-master.ps1; do not overwrite the master.'}
$generated=Join-Path $root 'local/artwork/drive-geometry-v3/user-draft-cleanup-generated.png'
if(!('DriveCompositeFinish' -as [type])){
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class DriveCompositeFinish {
  static double Region(int x,int y,int l,int t,int r,int b,double feather){
    return Math.Max(0,Math.Min(1,Math.Min(Math.Min(x-l,r-x),Math.Min(y-t,b-y))/feather));
  }
  public static void Run(string draftPath,string openPath,string generatedPath,string outputPath){
    using(var draft=new Bitmap(draftPath))
    using(var approved=new Bitmap(openPath))
    using(var generated=new Bitmap(generatedPath))
    using(var sample=new Bitmap(draft.Width,draft.Height,PixelFormat.Format32bppArgb))
    using(var result=(Bitmap)draft.Clone()){
      using(var g=Graphics.FromImage(sample)){
        g.InterpolationMode=InterpolationMode.HighQualityBicubic;
        g.DrawImage(generated,new Rectangle(0,0,sample.Width,sample.Height));
      }
      int protectedChanges=0;
      for(int y=0;y<draft.Height;y++) for(int x=0;x<draft.Width;x++){
        // Confine retouching to the user's photographic inserts and their
        // paste seams. The remaining approved photograph stays untouched.
        double a=Math.Max(Region(x,y,378,43,652,678,14),Region(x,y,567,60,1421,306,10));
        if(a>0){
          Color old=draft.GetPixel(x,y),fresh=sample.GetPixel(x,y);
          result.SetPixel(x,y,Color.FromArgb(old.A,
            (int)Math.Round(old.R*(1-a)+fresh.R*a),
            (int)Math.Round(old.G*(1-a)+fresh.G*a),
            (int)Math.Round(old.B*(1-a)+fresh.B*a)));
        }
        // The isolated fine vertical line is an accidental paste mark on
        // unchanged flat face plastic. Restore its exact approved pixels.
        if(x>=1417 && x<=1431 && y>=77 && y<=142)
          result.SetPixel(x,y,approved.GetPixel(x,y));
        if(x>=1432 && result.GetPixel(x,y).ToArgb()!=draft.GetPixel(x,y).ToArgb()) protectedChanges++;
      }
      if(protectedChanges!=0)throw new Exception("Protected right side changed");
      result.Save(outputPath,ImageFormat.Png);
      Console.WriteLine("Saved closed master. Right-hand face/LED outside retouch bounds exactly preserved. Open master read only.");
    }
  }
}
'@
}
$openPath=Join-Path $masters 'open-empty-approved.png'
$sha=[Security.Cryptography.SHA256]::Create()
$before=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($openPath))).Replace('-','').ToLowerInvariant()
[DriveCompositeFinish]::Run((Join-Path $masters 'closed-user-draft.png'),$openPath,$generated,(Join-Path $masters 'closed-clean.png'))
$after=[BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($openPath))).Replace('-','').ToLowerInvariant()
$sha.Dispose()
if($before -ne $after){throw 'Approved open master changed'}
[ordered]@{
  open='open-empty-approved.png';open_sha256=$after
  closed='closed-clean.png';closed_geometry_source='closed-user-draft.png'
  note='User-approved open master frozen. Closed retouch limited to photographed inserts and collage seams; no runtime resampling or deployment in this step.'
} | ConvertTo-Json | Set-Content (Join-Path $masters 'masters.json') -Encoding UTF8
Write-Output "Approved open master SHA-256 unchanged: $after"
$shadowSource=Join-Path $root 'local/artwork/drive-geometry-v3/shadow-transition-generated.png'
if(Test-Path $shadowSource){ & (Join-Path $PSScriptRoot 'finish-drive-shadow-transition.ps1') -InputPath (Join-Path $masters 'closed-clean.png') }
