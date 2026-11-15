#version 330 core
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


/*
	Bicubic filtering.

	The texture sampler must have bilinear filtering enabled (GL_LINEAR). 

	This shader relies on the fact that bilinear filtering gives us a weighted 
	average of texels in a 2x2 area. By sampling 4 bilinear samples with 
	carefully modified offsets and how we combine these 4 samples, we can get 
	the correct weights for all 16 texels we need. The result is an extremely 
	fast bicubic filtering function that only requires 4 texture samples.
	
	This shader uses texture() instead of texelFetch() so it works with texture 
	coordinate wrapping and clamping.
	
	http://http.developer.nvidia.com/GPUGems2/gpugems2_chapter20.html
	http://vec3.ca/bicubic-filtering-in-fewer-taps/
	
	Credit to:
	http://www.java-gaming.org/index.php?topic=35123.0
*/

vec4 cubic(float v)
{
	vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
	vec4 s = n * n * n;
	float x = s.x;
	float y = s.y - 4.0 * s.x;
	float z = s.z - 4.0 * s.y + 6.0 * s.x;
	float w = 6.0 - x - y - z;
	return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 FetchTexelBicubic(sampler2D sampler, vec2 texCoords)
{
	vec2 texSize = textureSize(sampler, 0);
	vec2 invTexSize = 1.0 / texSize;

	texCoords = texCoords * texSize - 0.5;

	vec2 fxy = fract(texCoords);
	texCoords -= fxy;

	vec4 xcubic = cubic(fxy.x);
	vec4 ycubic = cubic(fxy.y);
	
	vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;
	
	vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
	vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
	
	offset *= invTexSize.xxyy;
	
	vec4 sample0 = texture(sampler, offset.xz);
	vec4 sample1 = texture(sampler, offset.yz);
	vec4 sample2 = texture(sampler, offset.xw);
	vec4 sample3 = texture(sampler, offset.yw);
	
	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);

	return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}
#define BlendAdd(base, blend) min(base + blend, vec3(1.0))
#define Luma(c) dot(vec3(0.299,0.587,0.114), c)
//#define Luma(c) dot(vec3(0.2126,0.7152,0.0722), c)

// sRGB to Linear.
// Assuming using sRGB typed textures this should not be needed.
float ToLinear1(float c) 
{
	if(c <= 0.04045) {
		return c / 12.92;
	} else {
		return pow((c+0.055)/1.055, 2.4);
	}
}

vec3 ToLinear(vec3 c) 
{
	return vec3(ToLinear1(c.r), ToLinear1(c.g), ToLinear1(c.b));
}

// Linear to sRGB.
// Assuming using sRGB typed textures this should not be needed.
float ToSrgb1(float c)
{
	if(c < 0.0031308) { 
		return c * 12.92;
	} else { 
		return 1.055 * pow(c,0.41666) - 0.055;
	}
}

vec3 ToSrgb(vec3 c)
{
	return vec3(ToSrgb1(c.r), ToSrgb1(c.g), ToSrgb1(c.b));
}


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

vec3 Saturation(vec3 color, float value)
{
	const vec3 lumaCoeff = vec3(0.299,0.587,0.114);
	vec3 intensity = vec3(dot(color, lumaCoeff));
	return mix(intensity, color, value);
}

vec3 BrightnessSaturationContrast(vec4 color, float brightness, vec3 brightness_color, 
	float saturation, float contrast)
{
	/* On CRTs the control labeled Contrast is actually gain or the slope of 
	 * the output curve with increasing input voltage, and the control labeled 
	 * Brightness is actually offset or the overall level of all the points on 
	 * the curve, with the whole curve shifted up or down with increasing or 
	 * decreasing control adjustements.
	 */
	brightness -= 1.0;
	if(brightness < 0.0) {
		brightness_color = vec3(1.0);
	}
	brightness_color = mix(vec3(0.0), brightness_color, color.a);
	color.rgb += brightness * brightness_color;
	
	color.rgb = Saturation(color.rgb, saturation);

	color.rgb *= contrast;
	
	return max(vec3(0.0), color.rgb);
}

vec3 Exposure(vec3 color, float exposure)
{
	return vec3(1.0) - exp(-color * exposure);
}

float Vignette(vec2 uv, float intensity, float extent)
{
    uv *= 1.0 - uv.xy;
    float vig = uv.x*uv.y * intensity;
    vig = pow(vig, extent);
    return vig; 
}


in vec2 vTexCoord;

uniform sampler2D Original;
uniform sampler2D CRTEnv;
uniform vec4 CRTEnvSize;
#if VGA_REFLECTION
uniform sampler2D Reflection;
uniform vec4 ReflectionSize;
#endif

out vec4 FragColor;

#define VGA_SCALE   (1.0 * CRT_SCALE)
#define CONVERGENCE (CRTConvergence * 0.001)

vec2 ScaleUV(vec2 uv, float scale, vec2 ratio) 
{
    uv = (uv - 0.5) * 2.0; // move to [-1,1]
    uv /= vec2(OutputSize.y/OutputSize.x, 1.0); // make it square
    uv /= scale; // apply scale
    uv /= ratio; // apply aspect ratio
    uv = (uv / 2.0) + 0.5; // move back to [0,1]
	return uv;
}

vec2 CurvedSurface(vec2 uv, float r)
{
    return r * uv/sqrt(r * r - dot(uv, uv));
}

vec2 VGACurv(vec2 uv, float scale, float curvature) 
{
    uv = (uv - 0.5) * 2.0; // move to [-1,1]
    uv /= vec2(OutputSize.y/OutputSize.x, 1.0); // make it square
    uv /= scale; // scale
    uv = CurvedSurface(uv, curvature); // apply curvature
    uv /= vec2(4.0/3.0, 1.0); // apply aspect ratio
    uv = (uv / 2.0) + 0.5; // move back to [0,1]
	return uv;
}

float RoundBox(vec2 pos, vec2 size, float radius, float dist) 
{
    pos = (pos - 0.5) * 2.0; // move to [-1,1]
    pos /= vec2(OutputSize.y/OutputSize.x, 1.0); // make it square
    vec2 q = abs(pos) - size + radius;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - radius + dist;
}

int MaxLOD(vec4 size)
{
    return int(floor(log2(max(size.x, size.y))));
}

float Rand(vec2 co)
{
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

float ScaleN(float n, float l, float h)
{
	return (n - l) / (h - l);
}

float ScaleN(float n, float l0, float h0, float l1, float h1)
{
	return (n - l0) * (h1 - l1) / (h0 - l0) + l1;
}

vec3 Ambient()
{
    // take the global ambient value
    vec3 ambient = ToLinear(vec3(0.0, 0.0, 0.0));

#if VGA_REFLECTION
    // and add the contribution from the light that comes from the CRT
    //  (Reflection texture is already in linear space)
    vec3 crtAmbient = texelFetch(Reflection, ivec2(0,0), MaxLOD(ReflectionSize)).rgb;
    ambient += Saturation(crtAmbient, 0.3) // reduce saturation 
        * mix(0.0, 0.0, 1.0 - 0.0*1.2); // as global ambient increases, ambient from crt lowers
#endif

    // but don't go over 1.0
    ambient = vec3(
        min(ambient.r, 1.0),
        min(ambient.g, 1.0),
        min(ambient.b, 1.0)
    );
    return ambient;
}


void main()
{
    vec2 crtUV = ScaleUV(vTexCoord, CRT_SCALE, vec2(CRTEnvSize.x/CRTEnvSize.y, 1.0));

    // === VGA color
    float convergence = CONVERGENCE - CONVERGENCE * 0;
    vec2 vgaUV = VGACurv(vTexCoord * (convergence*2.0 + 1.0) - convergence, VGA_SCALE, 8.0);
    
    float chabx = clamp(abs(vgaUV.x*2.0 - 1.0) + 0.5, 0.0, 1.0) * convergence;
    vec2 rOffset = vec2(-1.0*chabx, 0.0 );
    vec2 gOffset = vec2( 0.0*chabx, 0.0 );
    vec2 bOffset = vec2( 1.0*chabx, 0.0 );

    float rValue = ToLinear(FetchCRT(Original, vgaUV - rOffset).rgb).r;
    float gValue = ToLinear(FetchCRT(Original, vgaUV - gOffset).rgb).g;
    float bValue = ToLinear(FetchCRT(Original, vgaUV - bOffset).rgb).b;

    vec4 vgaColor = vec4(rValue, gValue, bValue, 1.0);
    vgaColor.rgb = BrightnessSaturationContrast(vgaColor,
        1.0, BRT_TINT * 1, 1.0, 1.0);

    if(1.0 > 1.0) {
        vgaColor.rgb *= min(Vignette(crtUV, 200.0, 0.2), 1.0);
    }

    // === Ambient color & intensity
    vec3 ambient3 = Ambient();
    float ambient1 = Luma(ambient3);

    // === CRT glass effects
    vec3 crtEnvColor = ToLinear(texture(CRTEnv, crtUV).rgb);
    crtEnvColor *= ambient1 * 0.0; // the higher the ambient light, the grater the reflections are

    // This will act as a crude substitute for proper tone mapping.
    // VGA image will be prioritized for usability reasons.
    float vgaLuma = Luma(vgaColor.rgb);
    const float luma_w = 1.0;
    crtEnvColor *= max(0.0, 1.0 - vgaLuma*luma_w);

    vec3 crtColor = BlendAdd(vgaColor.rgb, crtEnvColor);
    
    // === Final color with alpha blending
    FragColor.rgb = ToSrgb(crtColor);
    if(crtUV.x >= 0.0 && crtUV.x <= 1.0 && crtUV.y >= 0.0 && crtUV.y <= 1.0) {
        FragColor.a = 1.0;
    } else {
        FragColor.a = 0.0;
    }
}
