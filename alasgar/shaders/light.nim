import types
import common
import pbr

proc getLightIntensity(LIGHT: Light, 
                       FRAGMENT: Fragment, 
                       pointToLight: Vec3): Vec3 =
    var intensity: float = 0.0
        
    if LIGHT.TYPE == LIGHT_TYPE_DIRECTIONAL:
        intensity = dot(FRAGMENT.N, -LIGHT.NORMALIZED_DIRECTION) * LIGHT.INTENSITY
    elif LIGHT.TYPE == LIGHT_TYPE_SPOT:
        let
            distance: float = length(pointToLight) 
            angle = dot(normalize(pointToLight), -LIGHT.NORMALIZED_DIRECTION)
            luma = LIGHT.LUMINANCE / (distance * distance)
        intensity = luma * smoothstep(LIGHT.OUTER_CUTOFF_COS, LIGHT.INNER_CUTOFF_COS, angle)
    else:
        let distance: float = length(pointToLight)
        intensity = LIGHT.LUMINANCE / (distance * distance)
    
    result = LIGHT.COLOR * intensity

#proc getIndirectSpecular(FRAGMENT: Fragment, ENVIRONMENT: Environment, GGX_MAP: Sampler2D): Vec3 =
#    result = ENVIRONMENT.BACKGROUND_COLOR.rgb
#    if ENVIRONMENT.HAS_ENV_MAP > 0:
#        result = textureLod(GGX_MAP, FRAGMENT.R, FRAGMENT.GGX_MAP_LOD).rgb    

#proc getEnvironmentReflection(FRAGMENT: Fragment, ENVIRONMENT: Environment, bakedLighting: Vec3): Vec3 =
#    let 
#        c: Vec3 = bakedLighting * data.ALBEDO * data.AO
#        reflection = -normalize(reflect(data.V, data.N))
#        irradiance = getIndirectSpecular(data, unity_SpecCube0_HDR) * data.AO
#        surfaceReduction = 1.0 / (data.ALPHA2 + 1.0)
#        fresnelTerm = pow5(1.0 - saturate(data.NoV))
#    result = c + surfaceReduction * irradiance * lerp(data.SPECULAR, vec3(data.REFLECTANCE), fresnelTerm)

proc getLight*(LIGHT: Light, FRAGMENT: Fragment, SURFACE: Surface): Vec3 = 
    var 
        pointToLight: Vec3 = LIGHT.POSITION - SURFACE.POSITION.xyz
        L: Vec3 = normalize(pointToLight)
        H: Vec3 = normalize(FRAGMENT.V + L)
        NoH = max(dot(FRAGMENT.N, H), 0.0)
        NoL = max(dot(FRAGMENT.N, L), 0.0)
        #VoH = max(dot(FRAGMENT.V, H), 0.0)
        LoH = max(dot(L, H), 0.0)
        intensity = getLightIntensity(LIGHT, FRAGMENT, pointToLight)
        light = getCookTorranceV1(FRAGMENT, LIGHT, NoL, NoH, LoH)

    result = intensity * light

