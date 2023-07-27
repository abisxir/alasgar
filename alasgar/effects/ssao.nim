import ../shaders/base
import ../shaders/common
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

proc hash12(p: Vec2): float =
    var 
        MOD3 = vec3(0.1031, 0.11369, 0.13787)
        p3  = fract(vec3(p.xyx) * MOD3)
    p3 += dot(p3, p3.yzx + 19.19)
    result = fract((p3.x + p3.y) * p3.z)

proc doAmbientOcclusion(CAMERA: Camera, DEPTH_CHANNEL: Sampler2D, COORD: Vec2, P, N: Vec3, SCALE, MAX_DISTANCE, BIAS: float): float =
    let 
        diff = getPosition(CAMERA, COORD, DEPTH_CHANNEL) - P
        l = length(diff)
        v = diff / l
        d = l * SCALE
        ao = max(0.0, dot(N, v) - BIAS) * (1.0 / (1.0 + d))
    result = ao * smoothstep(MAX_DISTANCE, MAX_DISTANCE * 0.5, l)

proc ssao(CAMERA: Uniform[Camera],
          FRAME: Uniform[Frame],
          COLOR_CHANNEL: Layout[0, Uniform[Sampler2D]],
          NORMAL_CHANNEL: Layout[1, Uniform[Sampler2D]],
          DEPTH_CHANNEL: Layout[2, Uniform[Sampler2D]],
          INTENSITY: Uniform[float],
          SCALE: Uniform[float],
          BIAS: Uniform[float],
          SAMPLE_RADIUS: Uniform[float],
          MAX_DISTANCE: Uniform[float],
          SAMPLES: Uniform[int],
          UV: Vec2,
          COLOR: var Vec4) =
    let 
        p = getPosition(CAMERA, UV, DEPTH_CHANNEL)
        n = texture(NORMAL_CHANNEL, UV).xyz
        rad = SAMPLE_RADIUS / p.z
        goldenAngle = 2.4
        inv = 1.0 / float(SAMPLES)
        rStep = inv * rad
    
    var 
        spiralUV: Vec2
        ao = 0.0
        radius = 0.0
        rotatePhase = hash12(UV * 100) * 6.28

    for i in 0..<SAMPLES:
        spiralUV.x = sin(rotatePhase)
        spiralUV.y = cos(rotatePhase)
        radius += rStep
        ao += doAmbientOcclusion(CAMERA, DEPTH_CHANNEL, UV + spiralUV * radius, p, n, SCALE, MAX_DISTANCE, BIAS)
        rotatePhase += goldenAngle

    ao *= inv
    ao = 1.0 - (ao * INTENSITY)

    COLOR.rgb = COLOR.rgb * ao


proc newSSAOEffect*(samples=32'i32, 
                    sampleRadius=0.02'f32, 
                    intensity=1.0'f32, 
                    scale=2.5'f32, 
                    bias=0.05'f32, 
                    maxDistance=0.07'f32, 
                    noiseTexture: Texture): Shader = 
    result = newCanvasShader(ssao)
    set(result, "SAMPLES", samples)
    set(result, "SAMPLE_RADIUS", sampleRadius)
    set(result, "INTENSITY", intensity)
    set(result, "SCALE", scale)
    set(result, "BIAS", bias)
    set(result, "MAX_DISTANCE", maxDistance)

