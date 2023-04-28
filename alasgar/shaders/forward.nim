import compile
import types
import common
import skin
import material
import light


proc prepare(SURFACE: Surface, 
             MATERIAL: Material,
             CAMERA: Camera,
             ENV: Environment,
             NORMAL_MAP: Sampler2D,
             ALBEDO_MAP: Sampler2D,
             METALLIC_MAP: Sampler2D,
             ROUGHNESS_MAP: Sampler2D,
             EMISSIVE_MAP: Sampler2D,
             AO_MAP: Sampler2D,
             GGX_MAP: SamplerCube): Fragment =
    result.FOG_AMOUNT = getFogAmount(ENV.FOG_DENSITY, SURFACE.POSITION_RELATED_TO_VIEW.xyz)
    if result.FOG_AMOUNT < 1.0:
        if MATERIAL.HAS_ALBEDO_MAP > 0.0:
            let c = texture(ALBEDO_MAP, SURFACE.UV)
            result.ALBEDO = c.rgb * MATERIAL.BASE_COLOR
            result.OPACITY = c.a * MATERIAL.OPACITY
        else:
            result.ALBEDO = MATERIAL.BASE_COLOR
            result.OPACITY = MATERIAL.OPACITY

        result.BACKGROUND = ENV.BACKGROUND_COLOR.xyz

        if MATERIAL.OPACITY > OPACITY_CUTOFF:
            result.SPECULAR = MATERIAL.SPECULAR_COLOR
            if MATERIAL.HAS_METALLIC_MAP > 0.0 and result.METALLIC > 0.0:
                result.METALLIC = MATERIAL.METALLIC * texture(METALLIC_MAP, SURFACE.UV).b
            else:
                result.METALLIC = MATERIAL.METALLIC

            if MATERIAL.HAS_ROUGHNESS_MAP > 0.0 and result.ROUGHNESS > 0.0:
                result.ROUGHNESS = MATERIAL.ROUGHNESS * texture(ROUGHNESS_MAP, SURFACE.UV).g
            else:
                result.ROUGHNESS = MATERIAL.ROUGHNESS

            if MATERIAL.HAS_AO_MAP > 0.0 and MATERIAL.AO > 0.0:
                result.AO = MATERIAL.AO * texture(AO_MAP, SURFACE.UV).r
            else:
                result.AO = MATERIAL.AO

            if MATERIAL.HAS_EMISSIVE_MAP > 0.0:
                result.EMISSIVE = texture(EMISSIVE_MAP, SURFACE.UV).rgb
            else:
                result.EMISSIVE = MATERIAL.EMISSIVE_COLOR

            result.P = SURFACE.POSITION.xyz
            if MATERIAL.HAS_NORMAL_MAP > 0.0:
                result.N = getNormalMap(result.P, SURFACE.NORMAL, SURFACE.UV, NORMAL_MAP)
            else:
                result.N = SURFACE.NORMAL
            result.V = normalize(CAMERA.POSITION - SURFACE.POSITION.xyz)
            result.R = -normalize(reflect(result.V, result.N))
            result.NoV = max(dot(result.N, result.V), EPSILON)

            if isPBR(result):
                result.ALPHA = result.ROUGHNESS * result.ROUGHNESS
                result.ALPHA2 = result.ALPHA * result.ALPHA
                result.ROUGHNESS2_MINUS_ONE = result.ALPHA2 - 1.0
                result.K = pow2(result.ROUGHNESS + 1.0) / 8.0
                result.NORMALIZED_ROUGHNESS = (result.ROUGHNESS + 0.5) * 4.0
                result.REFLECTANCE = MATERIAL.REFLECTANCE
                result.GGX_MAP_LOD = result.ROUGHNESS * ENV.MIP_COUNT
                #if ENV.HAS_ENV_MAP > 0:
                #    result.INDIRECT_SPECULAR = textureLod(GGX_MAP, FRAGMENT.R, result.GGX_MAP_LOD).rgb
            else:
                result.SHININESS = result.REFLECTANCE * 255.0
                #if ENV.HAS_ENV_MAP > 0:
                #    result.INDIRECT_SPECULAR = textureLod(GGX_MAP, FRAGMENT.R, result.REFLECTANCE * ENV.MIP_COUNT).rgb


proc mainVertex*(iPosition: Layout[0, Vec3], 
                 iNormal: Layout[1, Vec3],
                 iUV: Layout[2, Vec4],
                 iBone: Layout[3, Vec4], 
                 iWeight: Layout[4, Vec4],
                 iModel: Layout[5, Mat4],
                 iMaterial: Layout[9, UVec4],
                 iSprite: Layout[10, Vec4],
                 iSkin: Layout[11, Vec4],
                 uSkinMap: Layout[15, Uniform[Sampler2D]],
                 CAMERA: Uniform[Camera],
                 ENV: Uniform[Environment],
                 FRAME: Uniform[Frame],
                 SURFACE: var Surface,
                 MATERIAL: var Material,
                 gl_Position: var Vec4) =
    
    let
        position = vec4(iPosition, 1)
        model = applySkinTransform(uSkinMap, ENV, iModel, iBone, iWeight, iSkin)

    unpackMaterial(iMaterial, MATERIAL)
    SURFACE.POSITION = model * position
    SURFACE.NORMAL = (model * vec4(iNormal, 0.0)).xyz
    SURFACE.UV = calculateUV(iUV, iSprite)
    SURFACE.POSITION_RELATED_TO_VIEW = CAMERA.VIEW_MATRIX * SURFACE.POSITION
    SURFACE.PROJECTED_POSITION = CAMERA.PROJECTION_MATRIX * SURFACE.POSITION_RELATED_TO_VIEW

    gl_Position = SURFACE.PROJECTED_POSITION


proc mainFragment*(ALBEDO_MAP: Layout[0, Uniform[Sampler2D]],
                   NORMAL_MAP: Layout[1, Uniform[Sampler2D]],
                   METALLIC_MAP: Layout[2, Uniform[Sampler2D]],
                   ROUGHNESS_MAP: Layout[3, Uniform[Sampler2D]],
                   AO_MAP: Layout[4, Uniform[Sampler2D]],
                   EMISSIVE_MAP: Layout[5, Uniform[Sampler2D]],
                   GGX_MAP: Layout[5, Uniform[SamplerCube]],
                   DEPTH_MAP0: Layout[7, Uniform[Sampler2D]],
                   DEPTH_MAP1: Layout[8, Uniform[Sampler2D]],
                   DEPTH_MAP2: Layout[9, Uniform[Sampler2D]],
                   DEPTH_MAP3: Layout[10, Uniform[Sampler2D]],
                   DEPTH_CUBE_MAP0: Layout[11, Uniform[SamplerCube]],
                   DEPTH_CUBE_MAP1: Layout[12, Uniform[SamplerCube]],
                   DEPTH_CUBE_MAP2: Layout[13, Uniform[SamplerCube]],
                   DEPTH_CUBE_MAP3: Layout[14, Uniform[SamplerCube]],
                   SKIN_MAP: Layout[15, Uniform[Sampler2D]],
                   LIGHTS: Uniform[array[64, Light]],
                   CAMERA: Uniform[Camera],
                   ENV: Uniform[Environment],
                   FRAME: Uniform[Frame],
                   SURFACE: Surface,
                   MATERIAL: Material,
                   COLOR: var Vec4,
                   NORMAL: var Vec3) =
    var FRAGMENT: Fragment = prepare(
            SURFACE, 
            MATERIAL, 
            CAMERA, 
            ENV,
            NORMAL_MAP, 
            ALBEDO_MAP, 
            METALLIC_MAP, 
            ROUGHNESS_MAP, 
            EMISSIVE_MAP, 
            AO_MAP,
            GGX_MAP,
        )
    
    if FRAGMENT.FOG_AMOUNT < 1.0:
        COLOR = vec4(FRAGMENT.ALBEDO, FRAGMENT.OPACITY)
        #if FRAGMENT.OPACITY > OPACITY_CUTOFF:
        #    var lightFactor = vec3(0.0, 0.0, 0.0)
        #    for i in 0..<ENV.LIGHTS_COUNT:
        #        lightFactor += getLight(LIGHTS[i], FRAGMENT, SURFACE)
        #    COLOR.rgb = ENV.AMBIENT_COLOR + lightFactor

    if FRAGMENT.FOG_AMOUNT > 0.0:
        COLOR = mix(ENV.BACKGROUND_COLOR, COLOR, FRAGMENT.FOG_AMOUNT)

    COLOR = vec4(1.0, 1.0, 1.0, 1.0)
