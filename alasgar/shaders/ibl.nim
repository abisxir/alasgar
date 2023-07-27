import common
import brdf

proc uvToXYZ(FACE: int, UV: Vec2): Vec3 =
    if FACE == 0:
        result = vec3(1.0, UV.y, -UV.x)
    elif FACE == 1:
        result = vec3(-1.0, UV.y, UV.x)
    elif FACE == 2:
        result = vec3(UV.x, -1.0, UV.y)
    elif FACE == 3:
        result = vec3(UV.x, 1.0, -UV.y)
    elif FACE == 4:
        result = vec3(UV.x, UV.y, 1.0)
    else:
        result = vec3(-UV.x, UV.y, -1.0)

proc dirToUV(dir: Vec3): Vec2 = 
    let 
        x: float = 0.5 + 0.5 * atan(dir.z, dir.x) / PI
        y: float = 1.0 - acos(dir.y) / PI
    result = vec2(x, y)

proc panoramaToCubemapFragment*(UV: Vec2,
                                FACE: Uniform[int],
                                PANAROMA_MAP: Layout[0, Uniform[Sampler2D]],
                                COLOR: var Vec4) =
    let 
        texCoordNew = UV * 2.0 - 1.0
        scan = uvToXYZ(FACE, texCoordNew)
        direction: Vec3 = normalize(scan)
        src = dirToUV(direction)
    COLOR.rgb = texture(PANAROMA_MAP, src).rgb
    COLOR.a = 1.0

# Karis 2014, "Physically Based Material on Mobile"
proc prefilteredDFG(roughness, NoV: float): Vec2 =
    let 
        c0 = vec4(-1.0, -0.0275, -0.572,  0.022)
        c1 = vec4( 1.0,  0.0425,  1.040, -0.040)
        r = roughness * c0 + c1
        a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y

    result = vec2(-1.04, 1.04) * a004 + r.zw

#[
proc getIBL*(ENVIRONMENT: Environment, FRAGMENT: Fragment, GGX_MAP: SamplerCube, LUT_MAP: Sampler2D): Vec3 =
    let 
        ROUGHNESS = if isPBR(FRAGMENT): FRAGMENT.ROUGHNESS else: (1.0 - FRAGMENT.REFLECTANCE)
        F_AB: Vec2 = texture(LUT_MAP, vec2(FRAGMENT.NoV, ROUGHNESS)).xy
        #FR: Vec3 = max(vec3(1.0 - FRAGMENT.ROUGHNESS), FRAGMENT.F0) - FRAGMENT.F0
        #KS: Vec3 = FRAGMENT.F0 + FR * pow5(1.0 - FRAGMENT.NoV)
        #fssEss = KS * F_AB.x + F_AB.y
        fssEss = FRAGMENT.F0 * F_AB.x + F_AB.y
        irradiance: Vec3 = getIrradianceSphericalHarmonics(FRAGMENT.N)
        lod = ROUGHNESS * (ENVIRONMENT.MIP_COUNT - 1.0)
        radiance: Vec3 = 0 * textureLod(GGX_MAP, -FRAGMENT.R, lod).rgb

    result = FRAGMENT.AO * (fssEss * radiance + FRAGMENT.ALBEDO * irradiance)
]#

proc getIBL*(ENVIRONMENT: Environment, FRAGMENT: Fragment, SKYBOX_MAP: SamplerCube): Vec3 =
    var
        indirectDiffuse = getIrradianceSphericalHarmonics(FRAGMENT.N) * ONE_OVER_PI
        roughness = if isPBR(FRAGMENT): FRAGMENT.ROUGHNESS else: (1.0 - FRAGMENT.REFLECTANCE)
        lod = roughness * (ENVIRONMENT.MIP_COUNT - 1.0)
        indirectSpecular: Vec3 = textureLod(SKYBOX_MAP, FRAGMENT.R, lod).rgb
        dfg = prefilteredDFG(roughness, FRAGMENT.NoV)
        specularColor = FRAGMENT.F0 * dfg.x + dfg.y
    result = FRAGMENT.ALBEDO * indirectDiffuse + indirectSpecular * specularColor
