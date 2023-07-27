import types
import common
import brdf

proc getLightProps(LIGHT: Light, 
                   FRAGMENT: Fragment, 
                   L: var Vec3,
                   NoL: var float,
                   intensity: var float) =
    if LIGHT.TYPE == LIGHT_TYPE_DIRECTIONAL:
        L = -LIGHT.NORMALIZED_DIRECTION
        NoL = dot(FRAGMENT.N, L)
        intensity = LIGHT.LUMINANCE / 100.0
    else:
        let 
            pointToLight = LIGHT.POSITION - FRAGMENT.POSITION
            distance = length(pointToLight) 
        L = normalize(pointToLight)
        NoL = max(dot(FRAGMENT.N, L), 0.0)
        intensity = LIGHT.LUMINANCE / (distance * distance)
        if LIGHT.TYPE == LIGHT_TYPE_SPOT:
            let
                angle = dot(L, -LIGHT.NORMALIZED_DIRECTION)
            intensity *= smoothstep(LIGHT.OUTER_CUTOFF_COS, LIGHT.INNER_CUTOFF_COS, angle)
    intensity *= NoL


proc sampleShadow(POSITION: Vec4,
                  SHADOW_MVP: Mat4,
                  SHADOW_BIAS: float,
                  DEPTH_MAPS: Sampler2DArrayShadow,
                  DEPTH_MAP_LAYER: int): float =
    result = 1.0
    if DEPTH_MAP_LAYER >= 0:
        let 
            shadowPosition: Vec4 = SHADOW_MVP * POSITION
            lightSpacePositionNormalized: Vec4 = shadowPosition / shadowPosition.w
            lightSpacePosition: Vec4 = lightSpacePositionNormalized * 0.5 + 0.5
            shadowDepth = texture(DEPTH_MAPS, vec4(lightSpacePosition.xy, DEPTH_MAP_LAYER.float, lightSpacePosition.z))
        if shadowDepth < SHADOW_BIAS:
            result = shadowDepth

proc getLight*(LIGHT: Light, FRAGMENT: Fragment, SURFACE: Surface, DEPTH_MAPS: Sampler2DArrayShadow): Vec3 = 
    var 
        L: Vec3
        NoL: float
        intensity: float
        shadow: float
        light: Vec3

    # Calculates    
    getLightProps(LIGHT, FRAGMENT, L, NoL, intensity)
    
    if intensity > 0.0:
        shadow = sampleShadow(SURFACE.POSITION, LIGHT.SHADOW_MVP, LIGHT.SHADOW_BIAS, DEPTH_MAPS, LIGHT.DEPTH_MAP_LAYER)
        let
            H: Vec3 = normalize(FRAGMENT.V + L)
            NoH = max(dot(FRAGMENT.N, H), 0.0)
        if isPBR(FRAGMENT):
            let
                LoH = max(dot(L, H), 0.0)
            light = getBRDF(FRAGMENT, LIGHT, NoL, NoH, LoH)
        else:
            let
                VoH = max(dot(FRAGMENT.V, H), 0.0)
            light = getPhong(FRAGMENT, LIGHT, L, H, NoL, NoH, VoH)
        result = shadow * light * intensity
