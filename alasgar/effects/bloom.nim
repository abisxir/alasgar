import ../shaders/base
import ../shaders/common

proc samplef(COLOR_CHANNEL: Sampler2D, UV: Vec2): Vec3 = 
    pow(texture(COLOR_CHANNEL, UV).xyz, vec3(2.2, 2.2, 2.2))

proc highlights(pixel: Vec3, thres: float): Vec3 =
    let val = (pixel.x + pixel.y + pixel.z) / 3.0
    result = pixel * smoothstep(thres - 0.1, thres + 0.1, val)

proc hsample(COLOR_CHANNEL: Sampler2D, UV: Vec2): Vec3 = 
    highlights(samplef(COLOR_CHANNEL, UV), 0.6)

proc blur(FRAME: Frame, COLOR_CHANNEL: Sampler2D, UV: Vec2, offs: float): Vec3 =
    var 
        xoffs = offs * vec4(-2.0, -1.0, 1.0, 2.0) / FRAME.RESOLUTION.x
        yoffs = offs * vec4(-2.0, -1.0, 1.0, 2.0) / FRAME.RESOLUTION.y

    result = vec3(0.0, 0.0, 0.0)
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.x, yoffs.x)) * 0.00366
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.y, yoffs.x)) * 0.01465
    result += hsample(COLOR_CHANNEL, UV + vec2(    0.0, yoffs.x)) * 0.02564
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.z, yoffs.x)) * 0.01465
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.w, yoffs.x)) * 0.00366

    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.x, yoffs.y)) * 0.01465
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.y, yoffs.y)) * 0.05861
    result += hsample(COLOR_CHANNEL, UV + vec2(    0.0, yoffs.y)) * 0.09524
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.z, yoffs.y)) * 0.05861
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.w, yoffs.y)) * 0.01465

    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.x, 0.0)) * 0.02564
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.y, 0.0)) * 0.09524
    result += hsample(COLOR_CHANNEL, UV + vec2(    0.0, 0.0)) * 0.15018
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.z, 0.0)) * 0.09524
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.w, 0.0)) * 0.02564

    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.x, yoffs.z)) * 0.01465
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.y, yoffs.z)) * 0.05861
    result += hsample(COLOR_CHANNEL, UV + vec2(    0.0, yoffs.z)) * 0.09524
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.z, yoffs.z)) * 0.05861
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.w, yoffs.z)) * 0.01465

    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.x, yoffs.w)) * 0.00366
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.y, yoffs.w)) * 0.01465
    result += hsample(COLOR_CHANNEL, UV + vec2(    0.0, yoffs.w)) * 0.02564
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.z, yoffs.w)) * 0.01465
    result += hsample(COLOR_CHANNEL, UV + vec2(xoffs.w, yoffs.w)) * 0.00366

proc bloom(CAMERA: Uniform[Camera],
           FRAME: Uniform[Frame],
           COLOR_CHANNEL: Layout[0, Uniform[Sampler2D]],
           NORMAL_CHANNEL: Layout[1, Uniform[Sampler2D]],
           DEPTH_CHANNEL: Layout[2, Uniform[Sampler2D]],
           INTENSITY: Uniform[float],
           UV: Vec2,
           COLOR: var Vec4) =
    var 
        a: Vec3 = blur(FRAME, COLOR_CHANNEL, UV, 2.0)
        b: Vec3 = blur(FRAME, COLOR_CHANNEL, UV, 3.0)
        c: Vec3 = blur(FRAME, COLOR_CHANNEL, UV, 5.0)
        d: Vec3 = blur(FRAME, COLOR_CHANNEL, UV, 7.0)
        base = texture(COLOR_CHANNEL, UV) 
        color = (a + b + c + d) / 4.0 + pow(base.xyz, vec3(2.2, 2.2, 2.2))
    COLOR.rgb = color * INTENSITY
    COLOR.a = base.a

proc newBloomEffect*(intensity: float32=1.0): Shader = 
    result = newCanvasShader(bloom)
    set(result, "INTENSITY", intensity)

