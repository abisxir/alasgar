import ../shaders/base
import ../texture

const SOURCE = """
#define MOD3 vec3(.1031,.11369,.13787)

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float srand(float seed) {
    float r = fract(sin(dot(vec2(seed, seed + 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    return hash12(seed * UV);
}

float SSDO(vec3 position, vec3 normal, sampler2D depthMap, sampler2D normalMap, mat4 inverseViewMatrix, mat4 projectionMatrix) {
    float ao = 0.0;
    float numRays = 16.0;
    float radius = 0.07;
    float bias = 0.05;
    for(float i = 0.0; i < numRays; i++) {
        // Create a random direction within a hemisphere around the normal
        //vec2 offset = UV + (i / numRays);
        //vec3 randomVec = texture(channel0, offset).xyz;
        vec3 randomVec = vec3(vec2(srand(i)), sqrt(1.0 - dot(vec2(srand(i + 1.0)), vec2(srand(i + 1.0)))));
        vec3 dir = normalize(mat3(inverseViewMatrix) * (normalize(randomVec) * radius));

        // Trace the ray in screen space
        vec4 ray = projectionMatrix * vec4(dir, 0.0);
        vec2 rayTexCoords = ray.xy / ray.w * 0.5 + 0.5;

        // Sample the depth and normal maps
        float depth = texture(depthMap, rayTexCoords).r;
        vec3 rayNormal = texture(normalMap, rayTexCoords).rgb;

        // Calculate the distance between the current pixel and the sample
        vec4 samplePos = inverseViewMatrix * vec4(rayTexCoords * depth, depth, 1.0);
        float dist = length(samplePos.xyz - position);

        // Add the sample's contribution to the ambient occlusion
        float occlusion = max(0.0, dot(normalize(rayNormal), normal) - bias);
        ao += occlusion / (1.0 + dist);
    }
    return 1. - (ao / numRays);
}

void fragment() {
    if(UV.x < 0.33) {
        vec3 P = get_position();
        vec3 N = get_normal();
        float ao = SSDO(P, N, depth_channel, normal_channel, inverse(camera.view), camera.projection);
        COLOR.rgb = vec3(ao);
    }
}
"""

proc newSSDOEffect*(sampleRadius=16'f32, intensity=1.0'f32, noiseTexture: Texture): Shader = 
    result = newCanvasShader(SOURCE)

    set(result, "u_sample_radius", sampleRadius)
    set(result, "u_intensity", intensity)
    set(result, "channel0", noiseTexture, 0)

