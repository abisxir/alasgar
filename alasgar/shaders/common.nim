import compile
import types
import base

export HALF_PI, ONE_OVER_PI, LOG2, EPSILON, compile, types, base, helpers

const OPACITY_CUTOFF* = 0.01
const LIGHT_TYPE_DIRECTIONAL* = 0
const LIGHT_TYPE_POINT* = 1
const LIGHT_TYPE_SPOT* = 2

#define SHADOW_BIAS 0.00001
#define MIN_SHADOW_BIAS 0.000001
#define MEDIUMP_FLT_MAX 65504.0
#define saturate(x) clamp(x, 0.00001, 1.0)
#define sq(x) x *x
#define GAMMA 2.2
#define INV_GAMMA 1.0 / GAMMA

proc pow5*(v: float): float =
    let v2 = v * v
    result = v2 * v2 * v

proc pow4*(v: float): float =
    let v2 = v * v
    result = v2 * v2

proc pow2*(v: float): float = v * v


#when defined(emscripten) or defined(linux):
#    proc unpackUnorm4x8*(i: uint): Vec4 = vec4(
#        float(i and 0xff.uint) / 255.0,
#        float(i / (0x100.uint and 0xff.uint)) / 255.0,
#        float(i / (0x10000.uint and 0xff.uint)) / 255.0,
#        float(i / 0x1000000.uint / 255.0))

proc calculateUV*(uv, sprite: Vec4): Vec2 =
    let
        frameSize = sprite.xy
        frameOffset = sprite.zw
    if frameSize.x > 0.0:
        result = (uv.xy * frameSize) + frameOffset
    else:
        result = uv.xy

proc getNormalMap*(P, N: Vec3, UV: Vec2, NORMAL_MAP: Sampler2D): Vec3 =
    var 
        dp1: Vec3 = dFdx(P)
        dp2: Vec3 = dFdy(P)
        duv1: Vec2 = dFdx(UV)
        duv2: Vec2 = dFdy(UV)
        dp2perp: Vec3 = cross(dp2, N)
        dp1perp: Vec3 = cross(N, dp1)
        T: Vec3 = dp2perp * duv1.x + dp1perp * duv2.x
        B: Vec3 = dp2perp * duv1.y + dp1perp * duv2.y
        invmax: float = inversesqrt(max(dot(T, T), dot(B, B)))
        TBN: Mat3 = mat3(T * invmax, B * invmax, N)
        map: Vec3 = texture(NORMAL_MAP, UV).rgb * 2.0 - 1.0
    result = normalize(TBN * vec3(-map.x, map.y, map.z))

proc getFogAmount*(density: float, minDistance: float, distance: float): float =
    result = 0.0
    if density > 0.0:
        let effective = distance - minDistance
        if effective > 0:
            let d = density * effective
            result = 1.0 - clamp(exp2(-d * d * LOG2), 0.0, 1.0)

proc constructWorldPosition*(CAMERA: Camera, UV: Vec2, z: float): Vec3 =
    let 
        x = UV.x * 2.0 - 1.0
        y = (1.0 - UV.y) * 2.0 - 1.0
        positionS = vec4(x, y, z, 1.0)
        positionV = CAMERA.INVERSE_VIEW_PROJECTION_MATRIX * positionS
    return positionV.xyz / positionV.w


proc constructWorldNormal*(CAMERA: Camera, UV: Vec2, DEPTH_CHANNEL: Sampler2D): Vec3 =
    var 
        depthDimensions = vec2(textureSize(DEPTH_CHANNEL, 0))
        uv0 = UV
        uv1 = UV + vec2(1, 0) / depthDimensions
        uv2 = UV + vec2(0, 1) / depthDimensions
        depth0 = texture(DEPTH_CHANNEL, uv0).r
        depth1 = texture(DEPTH_CHANNEL, uv1).r
        depth2 = texture(DEPTH_CHANNEL, uv2).r
        P0 = constructWorldPosition(CAMERA, uv0, depth0)
        P1 = constructWorldPosition(CAMERA, uv1, depth1)
        P2 = constructWorldPosition(CAMERA, uv2, depth2)
    result = normalize(cross(P2 - P0, P1 - P0))


proc getPosition*(CAMERA: Camera, UV: Vec2, DEPTH_CHANNEL: Sampler2D): Vec3 =
    let 
        z = texture(DEPTH_CHANNEL, UV).r * 2.0 - 1.0
        # Get x/w and y/w from the viewport position
        x = UV.x * 2.0 - 1.0
        y = (1.0 - UV.y) * 2.0 - 1.0
        pos = vec4(x, y, z, 1.0)
        #Transform by the inverse projection matrix
        projectedPos = CAMERA.INV_PROJECTION_MATRIX * pos
        normalized = projectedPos / projectedPos.w
        positionInViewSpace = CAMERA.INV_VIEW_MATRIX * normalized
    result = positionInViewSpace.xyz / positionInViewSpace.w


proc linearizeDepth*(CAMERA: Camera, UV: Vec2, DEPTH_CHANNEL: Sampler2D): float32 =
    let depth = texture(DEPTH_CHANNEL, UV).x
    return (2.0 * CAMERA.NEAR) / (CAMERA.FAR + CAMERA.NEAR - depth * (CAMERA.FAR - CAMERA.NEAR));


proc getNormal*(CAMERA: Camera, UV: Vec2, DEPTH_CHANNEL: Sampler2D): Vec3 =
    let 
        depthDimensions = vec2(textureSize(DEPTH_CHANNEL, 0))
        uv0 = UV
        uv1 = UV + vec2(1, 0) / depthDimensions
        uv2 = UV + vec2(0, 1) / depthDimensions
        P0 = getPosition(CAMERA, uv0, DEPTH_CHANNEL)
        P1 = getPosition(CAMERA, uv1, DEPTH_CHANNEL)
        P2 = getPosition(CAMERA, uv2, DEPTH_CHANNEL)
    result = normalize(cross(P2 - P0, P1 - P0))

proc reconstructNormal*(CAMERA: Camera, UV: Vec2, DEPTH_CHANNEL: Sampler2D): Vec3 =
    let 
        pos = getPosition(CAMERA, UV, DEPTH_CHANNEL)
        n: Vec3 = normalize(cross(dFdx(pos), dFdy(pos)))
    return n * -1.0

proc isPBR*(FRAGMENT: Fragment): bool = FRAGMENT.ROUGHNESS > 0.0 or FRAGMENT.METALLIC > 0.0
proc linearToGamma*(color: Vec3): Vec3 = sqrt(color)
proc gammaToLinear*(color: Vec3): Vec3 = color * color
proc linearToGamma*(color: Vec4): Vec4 = vec4(sqrt(color.rgb), color.a)
proc gammaToLinear*(color: Vec4): Vec4 = vec4(color.rgb * color.rgb, color.a)

