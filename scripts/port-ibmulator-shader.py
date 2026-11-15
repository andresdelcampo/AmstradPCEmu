"""Reproduce the cabinet-only CRT shader from the pinned IBMulator sources."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
base = root / 'upstream/IBMulator/share/ibmulator/shaders'
out = root / 'assets/shaders'
out.mkdir(parents=True, exist_ok=True)
shader = (base/'ps1/crt.slang').read_text().split('#pragma stage fragment', 1)[1]
for inc, path in [('../common/filter_bicubic.glsl', 'common/filter_bicubic.glsl'),
                  ('../common/color_functions.glsl', 'common/color_functions.glsl'),
                  ('functions.glsl', 'ps1/functions.glsl')]:
    shader = shader.replace(f'#include "{inc}"', (base/path).read_text())
# Preserve the actual PS/1 CRT math. The cabinet defines sizing, so vgaScale=1;
# neutral color controls and no environment reflection avoid tinting CGA and
# duplicating the approved cabinet's glass. VGA_REFLECTION was a separate pass.
constants = {
    'globals.OutputSize':'OutputSize', 'globals.ibmu_Brightness':'1.0',
    'globals.ibmu_Contrast':'1.0', 'globals.ibmu_Saturation':'1.0',
    'globals.ibmu_Ambient':'0.0', 'globals.ibmu_Monochrome':'0',
    'globals.ibmu_PowerOn':'1', 'params.vgaScale':'1.0',
    'params.crtCurvature':'8.0', 'params.vgaConvergence':'CRTConvergence',
    'params.crtEnvMapEnabled':'0.0', 'params.ambientFromCRT':'0.0',
}
for old, new in constants.items():
    shader = shader.replace(old, new)
# B-spline is approximating (softens even source texel centers). The new
# interpolating kernel preserves thin CGA strokes; original remains selectable.
sharp_filter = '''
// Amstrad adaptation: interpolating Catmull-Rom, clamped to display range.
// The upstream B-spline helper above remains intact for the optional soft mode.
float CRTWeight(float x)
{
    x = abs(x);
    if (x < 1.0) return 1.5*x*x*x - 2.5*x*x + 1.0;
    if (x < 2.0) return -0.5*x*x*x + 2.5*x*x - 4.0*x + 2.0;
    return 0.0;
}
vec4 FetchCRT(sampler2D tex, vec2 uv)
{
    if (CRTSharpSampling < 0.5) return FetchTexelBicubic(tex, uv);
    vec2 size = vec2(textureSize(tex, 0));
    vec2 pixel = uv * size - 0.5;
    vec2 base = floor(pixel);
    vec2 phase = pixel - base;
    vec4 value = vec4(0.0);
    for (int y=-1; y<=2; ++y)
        for (int x=-1; x<=2; ++x)
            value += texture(tex, (base + vec2(x,y) + 0.5) / size)
                * CRTWeight(float(x)-phase.x) * CRTWeight(float(y)-phase.y);
    return clamp(value, 0.0, 1.0);
}
'''
shader = shader.replace('vec3 Saturation(', sharp_filter+'\nvec3 Saturation(')
shader = shader.replace('ToLinear(FetchTexelBicubic(Original,', 'ToLinear(FetchCRT(Original,')
header = '''#version 330 core
// Adapted from IBMulator ps1/crt.slang, ps1/functions.glsl and common helpers.
// IBMulator by Marco Bortolin, GPL-3.0-or-later. See NOTICE-IBMulator.md.
// Source pin: 48b5bb7a4733672e6fbc5c8b0e3b945ed5659e27.
// PS/1 curvature, convergence and color-transfer math retained.
// Optional original B-spline sampling; sharper interpolating CGA sampling default.
// Adaptation: standalone uniforms; aperture-filling scale; neutral color controls;
// no monitor, environment map or ambient/reflection passes.
#define VGA_REFLECTION 0
#define CRT_SCALE 1.0
#define BRT_TINT vec3(1.0)
uniform vec4 OutputSize;
uniform float CRTSharpSampling;
uniform float CRTConvergence;
'''
(out/'ibmulator-crt.frag').write_text(header+shader, encoding='utf-8')
(out/'COPYING-IBMulator').write_bytes((root/'upstream/IBMulator/COPYING').read_bytes())
