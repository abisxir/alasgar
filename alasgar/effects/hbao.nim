import ../shaders/base
import ../shaders/common

proc hbao(CAMERA: Uniform[Camera],
          FRAME: Uniform[Frame],
          COLOR_CHANNEL: Layout[0, Uniform[Sampler2D]],
          DEPTH_CHANNEL: Layout[1, Uniform[Sampler2D]],
          INTENSITY: Uniform[float],
          SAMPLE_RADIUS: Uniform[float],
          SAMPLES: Uniform[int],
          UV: Vec2,
          COLOR: var Vec4) =
    var 
        pos = getPosition(CAMERA, UV, DEPTH_CHANNEL)
        n = getNormal(CAMERA, UV, DEPTH_CHANNEL)
        ao = 0.0
        RANDOM_DIRS: array[8, Vec3] = [
            vec3( 0.5381, 0.1856, 0.4290),
            vec3( 0.1379, 0.2486, 0.4430),
            vec3( 0.3371, 0.5679, 0.4153),
            vec3( 0.6999,-0.1856, 0.4153),
            vec3(-0.3371,-0.2486, 0.4458),
            vec3(-0.6999, 0.4290, 0.4458),
            vec3(-0.1379, 0.9324, 0.3577),
            vec3(-0.3371,-0.9324, 0.3577)
        ]

    for i in 0..<SAMPLES:
        let
            dir = RANDOM_DIRS[i]
            r = reflect(dir, n)
            samplePos = pos + r * SAMPLE_RADIUS
            sampleDepth = texture(DEPTH_CHANNEL, (samplePos.xy + 1.0) * 0.5).r
            dist = length(samplePos - pos)
        ao += max(0.0, dot(n, dir) - (sampleDepth - pos.z) / dist)
    
    ao = 1.0 - (INTENSITY * ao / float(SAMPLES))
    COLOR.rgb = COLOR.rgb * ao

proc newHBAOEffect*(sampleRadius=32'f32, intensity=1.0'f32, samples=8'i32): Shader = 
    result = newCanvasShader(hbao)

    set(result, "SAMPLE_RADIUS", sampleRadius)
    set(result, "INTENSITY", intensity)
    set(result, "SAMPLES", min(8, samples))

