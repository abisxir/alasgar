import ../shaders/base
import ../shaders/common
import ../texture


proc hash12(p: Vec2): float =
    var 
        MOD3 = vec3(0.1031, 0.11369, 0.13787)
        p3  = fract(vec3(p.xyx) * MOD3)
    p3 += dot(p3, p3.yzx + 19.19)
    result = fract((p3.x + p3.y) * p3.z)

proc doAmbientOcclusion(CAMERA: Camera, DEPTH_CHANNEL: Sampler2D, COORD: Vec2, P, N: Vec3, SCALE, MAX_DISTANCE, BIAS: float): float =
    let 
        depth = texture(DEPTH_CHANNEL, COORD).r
        diff = constructWorldPosition(CAMERA, COORD, depth) - P
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
        depth = texture(DEPTH_CHANNEL, UV).r
        p = constructWorldPosition(CAMERA, UV, depth)
        n = constructWorldNormal(CAMERA, UV, DEPTH_CHANNEL)
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

    ao = 1.0 - (ao * INTENSITY / SAMPLES.float)

    COLOR = texture(COLOR_CHANNEL, UV)
    COLOR.rgb = COLOR.rgb * ao
    #COLOR.rgb = vec3(ao)


proc newSSAOEffect*(samples=32'i32, 
                    sampleRadius=0.02'f32, 
                    intensity=1.0'f32, 
                    scale=2.5'f32, 
                    bias=0.05'f32, 
                    maxDistance=0.07'f32): Shader = 
    result = newCanvasShader(ssao)
    set(result, "SAMPLES", samples)
    set(result, "SAMPLE_RADIUS", sampleRadius)
    set(result, "INTENSITY", intensity)
    set(result, "SCALE", scale)
    set(result, "BIAS", bias)
    set(result, "MAX_DISTANCE", maxDistance)

