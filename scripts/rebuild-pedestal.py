"""Remove the collaged monitor pedestal and put it back with matching light.

Works only inside the pasted rectangle of the front artwork:

1. The rectangle is replaced by clean tray, rebuilt row by row from the
   untouched tray on either side of it (tone and grain), so no paste remains.
2. The disc from the collage is laid back on top, shifted so it is centred
   under the monitor. Only its shading relative to its own flat surround is
   kept (dome, rim highlight, the soft ring where it meets the tray), so it
   picks up the tray's straight shadow at the sides and a rounded one on top.
   Its brightness is a blend between "fully in the tray's shadow" and the
   brightness it had in the collage.
3. Every pixel takes its hue from the tray's tones at that brightness, so the
   disc is the cabinet colour.

Usage: python rebuild-pedestal.py <source.png> <output.png> [lift]
  source is the artwork that still contains the collaged rectangle.
  lift 0 = disc as dark as the tray shadow around it, 1 = as bright as it was
  in the collage. Requires ImageMagick's `magick` on PATH.
"""
import math
import random
import subprocess
import sys

SIZE = 1254
X0, X1 = 344, 905            # pasted rectangle, inclusive
Y0, Y1 = 833, 895
OUT_L = (328, 342)           # untouched tray left of the paste
OUT_R = (907, 921)           # untouched tray right of the paste

PASTE_X1 = 897              # last column of the main collage piece
PASTE_Y1 = 894              # last clean collage row (895 is a seam)
IN_L = (347, 395)           # flat tray inside the collage, left of the disc
IN_R = (848, 896)           # flat tray inside the collage, right of the disc
DISC = (620.0, 858.0, 222.0, 36.0)   # collage disc: centre x/y, radius x/y
SHIFT = 6                   # moves the disc centre to x = 626, under the monitor


def load(path, fmt, count):
    data = subprocess.run(["magick", path, "-alpha", "off" if fmt == "rgb" else "on",
                           "-depth", "8", fmt + ":-"],
                          check=True, capture_output=True).stdout
    assert len(data) == count, f"unexpected size for {path}"
    return data


def main(source, output, lift):
    orig = load(source, "rgba", SIZE * SIZE * 4)
    raw = bytearray(orig)
    rng = random.Random(1512)

    def px(x, y, c):
        return orig[(y * SIZE + x) * 4 + c]

    def median(band, y, c):
        values = sorted(px(x, y, c) for x in range(band[0], band[1] + 1))
        return float(values[len(values) // 2])

    def level_at(x, y):
        return px(x, y, 0) + px(x, y, 1) + px(x, y, 2)

    rows = range(Y0, Y1 + 1)
    out_l = {y: [median(OUT_L, y, c) for c in range(3)] for y in rows}
    out_r = {y: [median(OUT_R, y, c) for c in range(3)] for y in rows}

    # The tray's own colour at each brightness, sampled from both sides.
    bins = {}
    for y in rows:
        for tone in (out_l[y], out_r[y]):
            bins.setdefault(int(sum(tone) // 24), []).append(tone)
    palette = [[sum(t[c] for t in tones) / len(tones) for c in range(3)]
               for tones in bins.values()]
    palette.sort(key=sum)

    def tray_tone(level):
        if level <= sum(palette[0]):
            scale = level / max(1.0, sum(palette[0]))
            return [v * scale for v in palette[0]]
        for low, high in zip(palette, palette[1:]):
            if level <= sum(high):
                u = (level - sum(low)) / max(1.0, sum(high) - sum(low))
                return [low[c] * (1 - u) + high[c] * u for c in range(3)]
        scale = level / sum(palette[-1])
        return [v * scale for v in palette[-1]]

    # Flat tray inside the collage, per row, and the scale that maps the
    # collage's lit tray onto the real lit tray.
    flat_l = {y: sum(median(IN_L, min(y, PASTE_Y1), c) for c in range(3)) for y in rows}
    flat_r = {y: sum(median(IN_R, min(y, PASTE_Y1), c) for c in range(3)) for y in rows}
    lit_rows = range(PASTE_Y1 - 5, PASTE_Y1 + 1)
    lit_scale = (sum(sum(out_l[y]) + sum(out_r[y]) for y in lit_rows) /
                 sum(flat_l[y] + flat_r[y] for y in lit_rows))

    cx, cy, rx, ry = DISC
    for y in rows:
        sy = min(y, PASTE_Y1)
        for x in range(X0, X1 + 1):
            # 1. Clean tray: side tones blended across, with real tray grain.
            t = (x - X0) / (X1 - X0)
            band, tones = (OUT_L, out_l) if rng.random() > t else (OUT_R, out_r)
            gx = rng.randint(band[0], band[1])
            level = sum(out_l[y][c] * (1 - t) + out_r[y][c] * t for c in range(3))
            grain = sum(px(gx, y, c) - tones[y][c] for c in range(3))
            grain = max(-12.0, min(12.0, grain))

            # 2. The collage disc, shifted into place, as relief over the tray.
            sx = x - SHIFT
            dx = (sx - cx) / rx
            dy = max(0.0, (sy - cy) / ry)
            reach = math.hypot(dx, dy)
            if IN_L[0] <= sx <= IN_R[1] and reach < 1.12:
                u = (sx - IN_L[0]) / (IN_R[1] - IN_L[0])
                here = level_at(sx, sy)
                relief = here / max(1.0, flat_l[y] * (1 - u) + flat_r[y] * u)
                # fade the relief out just beyond the disc so flats stay clean
                relief = 1.0 + (relief - 1.0) * max(0.0, min(1.0, (1.12 - reach) / 0.06))
                shadowed = level * relief
                w = lift * max(0.0, min(1.0, (1.0 - reach) / 0.04))
                level = math.exp((1 - w) * math.log(max(1.0, shadowed)) +
                                 w * math.log(max(1.0, here * lit_scale)))
                grain *= 0.4          # the collage disc carries its own grain

            rgb = tray_tone(level + grain)
            i = (y * SIZE + x) * 4
            for c in range(3):
                raw[i + c] = max(0, min(255, int(round(rgb[c]))))

    subprocess.run(["magick", "-size", f"{SIZE}x{SIZE}", "-depth", "8", "rgba:-", output],
                   input=bytes(raw), check=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], float(sys.argv[3]) if len(sys.argv) > 3 else 0.6)
