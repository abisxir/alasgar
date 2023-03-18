import types
import common
import pbr

proc getLightIntensity(LIGHT: Light, 
                       FRAGMENT: Fragment, 
                       pointToLight: Vec3, 
                       distance: float): Vec3 =
    var intensity: float = 0.0
    if LIGHT.TYPE == LIGHT_TYPE_DIRECTIONAL:
        intensity = dot(FRAGMENT.N, -LIGHT.NORMALIZED_DIRECTION) * LIGHT.INTENSITY
    elif LIGHT.TYPE == LIGHT_TYPE_SPOT:
        let 
            angle = dot(normalize(pointToLight), -LIGHT.NORMALIZED_DIRECTION)
            luma = LIGHT.LUMINANCE / (distance * distance)
        intensity = luma * smoothstep(LIGHT.OUTER_CUTOFF_COS, LIGHT.INNER_CUTOFF_COS, angle)
    else:
        intensity = LIGHT.LUMINANCE / (distance * distance)
    
    result = LIGHT.COLOR * intensity

proc getIrradianceSphericalHarmonics(N: Vec3): Vec3 = 
  # Irradiance from "Ditch River" IBL
  # (http://www.hdrlabs.com/sibl/archive.html)
  result = max(
      vec3(0.754554516862612, 0.748542953903366, 0.790921515418539) +
          vec3(-0.083856548007422, 0.092533500963210, 0.322764661032516) *
              (N.y) +
          vec3(0.308152705331738, 0.366796330467391, 0.466698181299906) *
              (N.z) +
          vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) *
              (N.x),
      0.0)

proc calculateBRDF(data: Fragment, NdotH: float, LdotH: float): float =
    let 
        d: float = NdotH * NdotH * data.ROUGHNESS2_MINUS_ONE + 1.00001
        LdotH2: float = LdotH * LdotH
        
    result = data.ALPHA / ((d * d) * max(0.1, LdotH2) * data.NORMALIZED_ROUGHNESS)

proc applyBRDF(LIGHT: Light, FRAGMENT: Fragment, L: Vec3, H: Vec3, NoH: float, NoL: float, LoH: float): Vec3 =
    let
        radiance: Vec3 = LIGHT.COLOR * NoL #* getIrradianceSphericalHarmonics(FRAGMENT.N)
        brdf: float = calculateBRDF(FRAGMENT, NoH, LoH)
    result = (brdf * FRAGMENT.SPECULAR + FRAGMENT.ALBEDO) * radiance

proc getSpecularCookTorrance(FRAGMENT: Fragment, LIGHT: Light, L: Vec3, H: Vec3): Vec3 =
    let 
        NoH = max(dot(FRAGMENT.N, H), 0.0)
        NoL = max(dot(FRAGMENT.N, L), 0.0)
        LoH = max(dot(L, H), 0.0)
        VoH = max(dot(FRAGMENT.V, H), 0.0)
        F0 = vec3(0.04)
        F = F0 + (1.0 - F0) * pow(1.0 - VoH, 5.0)
        G = NoL * FRAGMENT.NoV / (NoL * (1.0 - FRAGMENT.ROUGHNESS) + FRAGMENT.ROUGHNESS)
        D = (FRAGMENT.ALPHA) / (PI * pow2(NoH * NoH * FRAGMENT.ROUGHNESS2_MINUS_ONE + 1.0))
    
    result = F * G * D / (4.0 * NoL * FRAGMENT.NoV)

#proc getIndirectSpecular(FRAGMENT: Fragment, ENV: Environment, GGX_MAP: Sampler2D): Vec3 =
#    result = ENV.BACKGROUND_COLOR.rgb
#    if ENV.HAS_ENV_MAP > 0:
#        result = textureLod(GGX_MAP, FRAGMENT.R, FRAGMENT.GGX_MAP_LOD).rgb    

#proc getEnvironmentReflection(FRAGMENT: Fragment, ENV: Environment, bakedLighting: Vec3): Vec3 =
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
        #distance = length(pointToLight)
        L: Vec3 = normalize(pointToLight)
        H: Vec3 = normalize(FRAGMENT.V + L)
        NoH = max(dot(FRAGMENT.N, H), 0.0)
        NoL = max(dot(FRAGMENT.N, L), 0.0)
        #VoH = max(dot(FRAGMENT.V, H), 0.0)
        LoH = max(dot(L, H), 0.0)
        #base = getLightIntensity(LIGHT, FRAGMENT, pointToLight, distance)
        #light = getPBR(LIGHT, FRAGMENT, SURFACE, pointToLight)
    result = applyBRDF(LIGHT, FRAGMENT, L, H, NoH, NoL, LoH)
    #result = getSpecularCookTorrance(FRAGMENT, LIGHT, L, H)