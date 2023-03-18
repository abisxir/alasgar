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

proc cookTorranceBRDF*(FRAGMENT: Fragment,
                       NoH: float, 
                       NoL: float, 
                       HoV: float): Vec3 = 
    let 
        NDF: float = distributionGGX(NoH, FRAGMENT.ALPHA2)
        G: float = geometrySmith(FRAGMENT.NoV, NoL, FRAGMENT.K)
        F: Vec3 = fresnelSchlick(HoV, vec3(0.04))
        nominator = NDF * G * F
        denominator = 4.0 * FRAGMENT.NoV * NoL
        specular = FRAGMENT.SPECULAR * nominator / max(denominator, 0.001)
        diffuse = FRAGMENT.ALBEDO * (1.0 - F) * (1.0 - FRAGMENT.METALLIC)
  
    result = diffuse + specular * FRAGMENT.METALLIC

proc getPBR*(LIGHT: Light, FRAGMENT: Fragment, SURFACE: Surface, pointToLight: Vec3): Vec3 =
    var 
        L: Vec3 = normalize(pointToLight)
        #R: Vec3 = normalize(reflect(-L, FRAGMENT.N))
        H: Vec3 = normalize(FRAGMENT.V + L)
        NoL: float = saturate(dot(FRAGMENT.N, L))
        NoH: float = saturate(dot(FRAGMENT.N, H))
        #LoH = saturate(dot(L, H))
        HoV: float = saturate(dot(H, FRAGMENT.V))
    result = cookTorranceBRDF(
            FRAGMENT,
            NoH, 
            NoL, 
            HoV,
        )


# K = pow2(roughness + 1.0) / 8.0
# alpha2 = roughness * roughness * roughness * roughness
# NoV = max(dot(N, V), 0.0)
# NoL = max(dot(N, L), 0.0)
