$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'assets/front/backups/pc1512-front-before-transparency.png'
$target = Join-Path $root 'assets/front/pc1512-front.png'
if (!(Test-Path -LiteralPath $source)) { Copy-Item -LiteralPath $target -Destination $source }

# Refine the built-in image tool's cutout against the original silhouette.
# Work on alpha only, except for unmatting the one-pixel antialiased rim;
# the original cabinet pixels and every overlay coordinate are preserved.
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;
public static class FrontCutout {
    public static void Save(string source, string target) {
        using (var src = new Bitmap(source))
        using (var dst = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb)) {
            int w = src.Width, h = src.Height;
            var pixels = new Color[w*h];
            var outside = new bool[w*h];
            var queue = new Queue<int>();
            for (int y=0; y<h; y++) for (int x=0; x<w; x++) pixels[y*w+x] = src.GetPixel(x,y);
            Action<int> visit = i => {
                var c = pixels[i];
                int x=i%w, y=i/w;
                // The feet are shaded much darker than the beige cabinet.
                // Their local backdrop is almost black; retain their full rim.
                bool feet = y>=1220 && ((x>=155 && x<=225) || (x>=1030 && x<=1100));
                int threshold = feet ? 20 : 80;
                if (!outside[i] && Math.Max(c.R,Math.Max(c.G,c.B)) <= threshold) {
                    outside[i] = true; queue.Enqueue(i);
                }
            };
            for (int x=0; x<w; x++) { visit(x); visit((h-1)*w+x); }
            for (int y=0; y<h; y++) { visit(y*w); visit(y*w+w-1); }
            while (queue.Count>0) {
                int i=queue.Dequeue(), x=i%w, y=i/w;
                if (x>0) visit(i-1); if (x<w-1) visit(i+1);
                if (y>0) visit(i-w); if (y<h-1) visit(i+w);
            }
            int removed=0, rim=0;
            for (int y=0; y<h; y++) for (int x=0; x<w; x++) {
                int i=y*w+x;
                if (outside[i]) { dst.SetPixel(x,y,Color.Transparent); removed++; continue; }
                Color c=pixels[i], fg=c;
                bool edge=false;
                int br=0,bg=0,bb=0,n=0;
                for (int dy=-1; dy<=1; dy++) for (int dx=-1; dx<=1; dx++) {
                    int xx=x+dx, yy=y+dy;
                    if (xx<0 || xx>=w || yy<0 || yy>=h || !outside[yy*w+xx]) continue;
                    var b=pixels[yy*w+xx]; br+=b.R; bg+=b.G; bb+=b.B; n++; edge=true;
                }
                if (edge) {
                    for (int dy=-2; dy<=2; dy++) for (int dx=-2; dx<=2; dx++) {
                        int xx=x+dx, yy=y+dy;
                        if (xx<0 || xx>=w || yy<0 || yy>=h || outside[yy*w+xx]) continue;
                        var f=pixels[yy*w+xx];
                        if (f.R+f.G+f.B > fg.R+fg.G+fg.B) fg=f;
                    }
                    double bR=br/(double)n,bG=bg/(double)n,bB=bb/(double)n;
                    double denom=fg.R+fg.G+fg.B-bR-bG-bB;
                    double alpha=denom>0 ? Math.Min(1,Math.Max(.05,(c.R+c.G+c.B-bR-bG-bB)/denom)) : 1;
                    Func<double,int> clip = v => (int)Math.Round(Math.Min(255,Math.Max(0,v)));
                    dst.SetPixel(x,y,Color.FromArgb(clip(255*alpha),clip((c.R-(1-alpha)*bR)/alpha),clip((c.G-(1-alpha)*bG)/alpha),clip((c.B-(1-alpha)*bB)/alpha)));
                    rim++;
                } else dst.SetPixel(x,y,c);
            }
            dst.Save(target,ImageFormat.Png);
            Console.WriteLine("Transparent exterior: {0} pixels; antialiased rim: {1}; canvas: {2}x{3}",removed,rim,w,h);
        }
    }
}
'@
[FrontCutout]::Save($source, $target)
