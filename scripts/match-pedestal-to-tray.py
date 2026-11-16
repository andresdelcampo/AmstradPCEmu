"""Relight the pasted monitor-pedestal rectangle so it takes the tray's tones.

The rectangle collaged into the pedestal recess is brighter than the tray on
either side of it. Each row of the rectangle is scaled, per channel, by the
ratio between the untouched tray just outside the paste and the flat tray just
inside it. The flats therefore end up identical to the sides (straight shadow),
while the raised disc keeps its own relative shading (rounded shadow).

Only pixels inside the pasted rectangle are changed.

Usage: python match-pedestal-to-tray.py <source.png> <output.png>
Requires ImageMagick's `magick` on PATH.
"""
import subprocess
import sys

SIZE = 1254
X0, X1 = 344, 905          # pasted rectangle, inclusive
Y0, Y1 = 833, 895
STRIP_X0 = 898             # separate grey sliver at the paste's right edge
OUT_L = (328, 342)         # untouched tray left of the paste
OUT_R = (907, 921)         # untouched tray right of the paste
IN_L = (347, 400)          # flat tray inside the paste, left of the disc
IN_R = (838, 896)          # flat tray inside the paste, right of the disc
DISC_CONTRAST = float(sys.argv[3]) if len(sys.argv) > 3 else 1.6


def main(source, output):
    raw = bytearray(subprocess.run(
        ["magick", source, "-depth", "8", "rgba:-"],
        check=True, capture_output=True).stdout)
    assert len(raw) == SIZE * SIZE * 4, "unexpected image size"
    orig = bytes(raw)

    def px(x, y, c):
        return orig[(y * SIZE + x) * 4 + c]

    def median(band, y, c):
        values = sorted(px(x, y, c) for x in range(band[0], band[1] + 1))
        return float(values[len(values) // 2])

    rows = range(Y0, Y1 + 1)
    out_l = {y: [median(OUT_L, y, c) for c in range(3)] for y in rows}
    out_r = {y: [median(OUT_R, y, c) for c in range(3)] for y in rows}
    gain_l, gain_r = {}, {}
    for y in rows:
        # The last pasted row is a bright seam on the flats; borrow the gain
        # of the row above so the disc is not over-darkened there.
        ref = min(y, Y1 - 1)
        gain_l[y] = [out_l[ref][c] / max(1.0, median(IN_L, ref, c)) for c in range(3)]
        gain_r[y] = [out_r[ref][c] / max(1.0, median(IN_R, ref, c)) for c in range(3)]

    def smooth(gains):
        result = {}
        for y in rows:
            if y < Y0 + 3:            # steep contact shadow: keep exact
                result[y] = gains[y]
                continue
            near = [gains[k] for k in range(y - 2, y + 3) if k in gains]
            result[y] = [sum(g[c] for g in near) / len(near) for c in range(3)]
        return result

    gain_l, gain_r = smooth(gain_l), smooth(gain_r)

    def put(x, y, rgb):
        i = (y * SIZE + x) * 4
        for c in range(3):
            raw[i + c] = max(0, min(255, int(round(rgb[c]))))

    def get(x, y):
        i = (y * SIZE + x) * 4
        return [raw[i], raw[i + 1], raw[i + 2]]

    # The tray's own colour at each brightness, sampled from both sides. Every
    # relit pixel takes its hue from here, so the disc cannot drift away from
    # the cabinet colour when it is brighter or darker than the flat beside it.
    bins = {}
    for y in rows:
        for tone in (out_l[y], out_r[y]):
            bins.setdefault(int(sum(tone) // 24), []).append(tone)
    palette = sorted(
        [sum(t[c] for t in tones) / len(tones) for c in range(3)]
        for tones in bins.values())
    palette.sort(key=sum)

    def tray_tone(rgb):
        level = sum(rgb)
        if level <= sum(palette[0]):
            scale = level / max(1.0, sum(palette[0]))
            return [v * scale for v in palette[0]]
        for low, high in zip(palette, palette[1:]):
            if level <= sum(high):
                u = (level - sum(low)) / max(1.0, sum(high) - sum(low))
                return [low[c] * (1 - u) + high[c] * u for c in range(3)]
        scale = level / sum(palette[-1])
        return [v * scale for v in palette[-1]]

    # 1. Scale the main paste by the horizontally interpolated gain. Shading
    #    relative to the flat tray (the disc's dome and rim) is exaggerated a
    #    little so the disc still reads as lit once it sits in the shadow.
    flat_l = {y: [median(IN_L, min(y, Y1 - 1), c) for c in range(3)] for y in rows}
    flat_r = {y: [median(IN_R, min(y, Y1 - 1), c) for c in range(3)] for y in rows}
    for y in rows:
        for x in range(X0, STRIP_X0):
            t = (x - X0) / (STRIP_X0 - 1 - X0)
            flat = sum(flat_l[y][c] * (1 - t) + flat_r[y][c] * t for c in range(3))
            relief = max(0.2, sum(px(x, y, c) for c in range(3)) / max(1.0, flat))
            boost = relief ** (DISC_CONTRAST - 1.0)
            put(x, y, tray_tone([px(x, y, c) * (gain_l[y][c] * (1 - t) + gain_r[y][c] * t) * boost
                                 for c in range(3)]))

    # 2. The last pasted row is a seam; rebuild it from its neighbours.
    for x in range(X0, STRIP_X0):
        above, below = get(x, Y1 - 1), get(x, Y1 + 1)
        put(x, Y1, [(above[c] + below[c]) / 2 for c in range(3)])

    # 3. The grey sliver: rebuild as a blend from the corrected paste to the
    #    untouched tray beyond it, keeping the sliver's own fine grain.
    for y in range(Y0, Y1 + 1):
        strip_med = [median((STRIP_X0, X1), y, c) for c in range(3)]
        left = [sum(get(x, y)[c] for x in range(STRIP_X0 - 4, STRIP_X0)) / 4 for c in range(3)]
        right = out_r[y]
        for x in range(STRIP_X0, X1 + 1):
            t = (x - STRIP_X0 + 1) / (X1 - STRIP_X0 + 2)
            put(x, y, [left[c] * (1 - t) + right[c] * t + (px(x, y, c) - strip_med[c]) * 0.5
                       for c in range(3)])

    # 4. One-pixel seam columns at the left and right ends of the paste.
    for y in rows:
        a, b = get(X0 - 1, y), get(X0 + 1, y)
        put(X0, y, [(a[c] + b[c]) / 2 for c in range(3)])

    subprocess.run(
        ["magick", "-size", f"{SIZE}x{SIZE}", "-depth", "8", "rgba:-", output],
        input=bytes(raw), check=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
