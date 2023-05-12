import ../shaders/base
import ../texture

const SOURCE = """
uniform float SAMPLE_RADIUS;
uniform float INTENSITY;

const int NUM_SAMPLES = 8;

vec3 RANDOM_DIRS[NUM_SAMPLES] = vec3[](
    vec3( 0.5381, 0.1856, 0.4290),
    vec3( 0.1379, 0.2486, 0.4430),
    vec3( 0.3371, 0.5679, 0.4153),
    vec3( 0.6999,-0.1856, 0.4153),
    vec3(-0.3371,-0.2486, 0.4458),
    vec3(-0.6999, 0.4290, 0.4458),
    vec3(-0.1379, 0.9324, 0.3577),
    vec3(-0.3371,-0.9324, 0.3577)
);

float HBAO(vec2 uv) {
    vec3 pos = get_position(uv);
    vec3 norm = get_normal(uv);
    float ao = 0.0;

    for (int i = 0; i < NUM_SAMPLES; i++) {
        vec3 dir = RANDOM_DIRS[i];
        vec3 r = reflect(dir, norm);
        vec3 sample_pos = pos + r * SAMPLE_RADIUS;
        float sample_depth = texture(depth_channel, (sample_pos.xy + 1.0) * 0.5).r;
        float dist = length(sample_pos - pos);
        ao += max(0.0, dot(norm, dir) - (sample_depth - pos.z) / dist);
    }

    return 1.0 - (INTENSITY * ao / float(NUM_SAMPLES));
}

void fragment() {
    if(UV.x > 0.5) {
        COLOR.rgb *= HBAO(UV);
    }
}
"""

proc newHBAOEffect*(sampleRadius=32'f32, intensity=1.0'f32, noiseTexture: Texture): Shader = 
    result = newCanvasShader(SOURCE)

    set(result, "SAMPLE_RADIUS", sampleRadius)
    set(result, "INTENSITY", intensity)
    set(result, "channel0", noiseTexture, 0)

