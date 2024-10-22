import ../shaders/base
import ../shaders/common

proc fxaa(CAMERA: Uniform[Camera],
          FRAME: Uniform[Frame],
          COLOR_CHANNEL: Layout[0, Uniform[Sampler2D]],
          DEPTH_CHANNEL: Layout[1, Uniform[Sampler2D]],
          FXAA_REDUCE_MIN: Uniform[float],
          FXAA_REDUCE_MUL: Uniform[float],
          FXAA_SPAN_MAX: Uniform[float],
          SPLIT: Uniform[float],
          UV: Vec2,
          COLOR: var Vec4) =
    var 
        fragCoord = UV * FRAME.RESOLUTION.xy
        inverseVP = 1.0 / FRAME.RESOLUTION.xy
        uvNW = (fragCoord + vec2(-1.0, -1.0)) * inverseVP
        uvNE = (fragCoord + vec2(1.0, -1.0)) * inverseVP
        uvSW = (fragCoord + vec2(-1.0, 1.0)) * inverseVP
        uvSE = (fragCoord + vec2(1.0, 1.0)) * inverseVP
        uvM = vec2(fragCoord * inverseVP)
        rgbNW = texture(COLOR_CHANNEL, uvNW).xyz
        rgbNE = texture(COLOR_CHANNEL, uvNE).xyz
        rgbSW = texture(COLOR_CHANNEL, uvSW).xyz
        rgbSE = texture(COLOR_CHANNEL, uvSE).xyz
        texColor = texture(COLOR_CHANNEL, uvM)
        rgbM  = texColor.xyz
        luma = vec3(0.299, 0.587, 0.114)
        lumaNW = dot(rgbNW, luma)
        lumaNE = dot(rgbNE, luma)
        lumaSW = dot(rgbSW, luma)
        lumaSE = dot(rgbSE, luma)
        lumaM  = dot(rgbM,  luma)
        lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)))
        lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)))
        dir: Vec2
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE))
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE))
    var dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                        (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN)
    var rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce)
    dir = inverseVP * min(
        vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
        max(
            vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), 
            dir * rcpDirMin
        )
    )
    var rgbA = 0.5 * (
        texture(COLOR_CHANNEL, fragCoord * inverseVP + dir * (1.0 / 3.0 - 0.5)).xyz +
        texture(COLOR_CHANNEL, fragCoord * inverseVP + dir * (2.0 / 3.0 - 0.5)).xyz)
    var rgbB = rgbA * 0.5 + 0.25 * (
        texture(COLOR_CHANNEL, fragCoord * inverseVP + dir * -0.5).xyz +
        texture(COLOR_CHANNEL, fragCoord * inverseVP + dir * 0.5).xyz)
    var lumaB = dot(rgbB, luma)
    if lumaB < lumaMin or lumaB > lumaMax:
        COLOR = vec4(rgbA, texColor.a)
    else:
        COLOR = vec4(rgbB, texColor.a)

proc newFxaaEffect*(spanMax=8'f32, reduceMul=1'f32 / 8'f32, reduceMin=1'f32 / 128'f32, split=0'f32): Shader = 
    result = newCanvasShader(fxaa)
    set(result, "FXAA_SPAN_MAX", spanMax)
    set(result, "FXAA_REDUCE_MUL", reduceMul)
    set(result, "FXAA_REDUCE_MIN", reduceMin)
    set(result, "SPLIT", split)

