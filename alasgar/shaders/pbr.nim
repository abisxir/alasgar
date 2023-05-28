import types
import common

proc distributionGGX*(NoH: float, alpha2: float): float = 
    let 
        NoH2 = NoH * NoH
 
    var denom = NoH2 * (alpha2 - 1.0) + 1.0
    denom = PI * denom * denom

    result = alpha2 / max(denom, 0.001)

proc fresnelSchlick*(cosTheta: float, F0: Vec3): Vec3 = F0 + (1.0 - F0) * pow5(1.0 - cosTheta)
proc geometrySchlickGGX(NoV: float, K: float): float = (NoV * (1.0 - K) + K)
proc geometrySmith(NoV: float, NoL: float, roughness: float): float = 
    geometrySchlickGGX(NoV, roughness) * geometrySchlickGGX(NoL, roughness)


proc getCookTorranceV1*(FRAGMENT: Fragment, 
                        LIGHT: Light, 
                        NoL, NoH, VoH: float): Vec3 =
    let 
        F0 = vec3(0.04)
        F = fresnelSchlick(VoH, F0)
        G = NoL * FRAGMENT.NoV / (NoL * (1.0 - FRAGMENT.ROUGHNESS) + FRAGMENT.ROUGHNESS)
        D = FRAGMENT.ALPHA / (PI * pow2(NoH * NoH * FRAGMENT.ROUGHNESS2_MINUS_ONE + 1.0))
        specular = F * G * D / max(4.0 * NoL * FRAGMENT.NoV, EPSILON)
        diffuse = (1.0 - F) * (1.0 - FRAGMENT.METALLIC)
    result = FRAGMENT.SPECULAR * specular + FRAGMENT.ALBEDO * diffuse

proc getCookTorranceV2*(FRAGMENT: Fragment,
                        LIGHT: Light, 
                        NoL, NoH, VoH: float): Vec3 = 
    let 
        NDF: float = distributionGGX(NoH, FRAGMENT.ALPHA2)
        G: float = geometrySmith(FRAGMENT.NoV, NoL, FRAGMENT.K)
        F: Vec3 = fresnelSchlick(VoH, vec3(0.04))
        nominator = NDF * G * F
        denominator = 4.0 * FRAGMENT.NoV * NoL
        specular = FRAGMENT.SPECULAR * nominator / max(denominator, 0.001)
        diffuse = FRAGMENT.ALBEDO * (1.0 - F) * (1.0 - FRAGMENT.METALLIC)
    result = LIGHT.COLOR * (diffuse + specular * FRAGMENT.METALLIC)

proc calculateBRDF(FRAGMENT: Fragment, NoH: float, LoH: float): float =
    let 
        d: float = NoH * NoH * FRAGMENT.ROUGHNESS2_MINUS_ONE + 1.00001
        LoH2: float = LoH * LoH
        
    result = FRAGMENT.ALPHA / ((d * d) * max(0.1, LoH2) * FRAGMENT.NORMALIZED_ROUGHNESS)

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

proc getBRDF*(FRAGMENT: Fragment, LIGHT: Light, NoH: float, NoL: float, LoH: float): Vec3 =
    let
        radiance: Vec3 = LIGHT.COLOR * NoL * getIrradianceSphericalHarmonics(FRAGMENT.N)
        brdf: float = calculateBRDF(FRAGMENT, NoH, LoH)
    result = (brdf * FRAGMENT.SPECULAR + FRAGMENT.ALBEDO) * radiance

proc getEnvironmentReflection*(FRAGMENT: Fragment, GGX_MAP: SamplerCube): Vec3 =
    let 
        c: Vec3 = FRAGMENT.ALBEDO * FRAGMENT.AO
        irradiance: Vec3 = textureLod(GGX_MAP, FRAGMENT.R, FRAGMENT.GGX_MAP_LOD).rgb * FRAGMENT.AO
        surfaceReduction: float = 1.0 / (FRAGMENT.ALPHA2 + 1.0)
        fresnelTerm: float = pow5(1.0 - saturate(FRAGMENT.NoV))
    result = c + surfaceReduction * irradiance * lerp(FRAGMENT.SPECULAR, vec3(FRAGMENT.REFLECTANCE), fresnelTerm)
    result = gammaToLinear(result)