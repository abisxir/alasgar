import ../shaders/base
import ../texture

const SOURCE = """
uniform float INTENSITY;
uniform float SCALE;
uniform float BIAS;
uniform float SAMPLE_RADIUS;
uniform float MAX_DISTANCE;
uniform int SAMPLES;

#define MOD3 vec3(.1031,.11369,.13787)

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}


float doAmbientOcclusion1(vec2 uv, vec2 offset, vec3 p, vec3 n)
{
     vec3 diff = get_position(offset + uv) - p;
     vec3 v = normalize(diff);
     float d = length(v) * SCALE;
     float ao = max(0.0, dot(n, v) - BIAS) * (1.0 / (1.0 + d)) * INTENSITY;
     float l = length(diff);
     ao *= smoothstep(MAX_DISTANCE, MAX_DISTANCE * 0.5, l);
     return ao;
}



float doAmbientOcclusion2(in vec2 tcoord,in vec2 uv, in vec3 p, in vec3 cnorm)
{
    vec3 diff = get_position(tcoord + uv) - p;
    float l = length(diff);
    vec3 v = diff / l;
    float d = l * SCALE;
    float ao = max(0.0, dot(cnorm, v) - BIAS) * (1.0 / (1.0 + d));
    ao *= smoothstep(MAX_DISTANCE,MAX_DISTANCE * 0.5, l);
    return ao;
}

float SSAO2(vec2 uv)
{
    vec3 p = get_position(uv);
    vec3 n = get_normal(uv);
    float rad = SAMPLE_RADIUS / p.z;
    float goldenAngle = 2.4;
    float ao = 0.;
    float inv = 1. / float(SAMPLES);
    float radius = 0.;

    float rotatePhase = hash12( uv * 100. ) * 6.28;
    float rStep = inv * rad;
    vec2 spiralUV;

    for (int i = 0; i < SAMPLES; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radius += rStep;
        ao += doAmbientOcclusion2(uv, spiralUV * radius, p, n);
        rotatePhase += goldenAngle;
    }
    ao *= inv;
    return 1. - (ao * INTENSITY);
}

void fragment() {
    COLOR.rgb *= SSAO2(UV);
}
"""

proc newSSAOEffect*(samples=32'i32, 
                    sampleRadius=0.02'f32, 
                    intensity=1.0'f32, 
                    scale=2.5'f32, 
                    bias=0.05'f32, 
                    maxDistance=0.07'f32, 
                    noiseTexture: Texture): Shader = 
    result = newCanvasShader(SOURCE)
    set(result, "SAMPLES", samples)
    set(result, "SAMPLE_RADIUS", sampleRadius)
    set(result, "INTENSITY", intensity)
    set(result, "SCALE", scale)
    set(result, "BIAS", bias)
    set(result, "MAX_DISTANCE", maxDistance)
    set(result, "channel0", noiseTexture, 0)

